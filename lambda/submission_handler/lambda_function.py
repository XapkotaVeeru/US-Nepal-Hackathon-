import json
import os
import boto3
import uuid
import numpy as np
from datetime import datetime, timezone
from decimal import Decimal
from botocore.config import Config
from botocore.exceptions import ClientError

# Environment configuration
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
TABLE_NAME = os.getenv('PEER_SUPPORT_TABLE', 'PeerSupportData')
RISK_MODEL_ID = os.getenv('BEDROCK_RISK_MODEL_ID', 'amazon.nova-lite-v1:0')
EMBEDDING_MODEL_ID = os.getenv('BEDROCK_EMBEDDING_MODEL_ID', 'amazon.titan-embed-text-v2:0')
SIMILARITY_THRESHOLD = float(os.getenv('SIMILARITY_THRESHOLD', '0.75'))

BEDROCK_CONFIG = Config(
    connect_timeout=10,
    read_timeout=3600,
    retries={'max_attempts': 3, 'mode': 'standard'}
)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
bedrock = boto3.client('bedrock', region_name=AWS_REGION, config=BEDROCK_CONFIG)
bedrock_runtime = boto3.client('bedrock-runtime', region_name=AWS_REGION, config=BEDROCK_CONFIG)

# DynamoDB table
table = dynamodb.Table(TABLE_NAME)


class BedrockInvocationError(Exception):
    """Raised when Bedrock cannot be invoked due to auth/access/service issues."""
    def __init__(self, message, *, error_code=None, availability=None):
        super().__init__(message)
        self.error_code = error_code
        self.availability = availability or {}


def _json_safe(value):
    """Convert DynamoDB/NumPy values into plain JSON-safe Python types."""
    if isinstance(value, Decimal):
        if value % 1 == 0:
            return int(value)
        return float(value)
    if isinstance(value, np.generic):
        return value.item()
    if isinstance(value, np.ndarray):
        return value.tolist()
    if isinstance(value, dict):
        return {k: _json_safe(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_json_safe(v) for v in value]
    return value


def lambda_handler(event, context):
    """Main handler for submission processing with synchronous matching"""
    try:
        # Log the incoming event for debugging
        print(f"Received event: {json.dumps(_json_safe(event))}")
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        print(f"Parsed body: {json.dumps(_json_safe(body))}")
        
        # Validate input
        validation_error = validate_input(body)
        if validation_error:
            return create_response(400, {'error': validation_error})
        
        # Extract data
        anonymous_id = body.get('anonymousId')
        content = body.get('content')
        region = body.get('region', 'US')
        
        # Generate submission ID
        submission_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Classify risk using Bedrock
        risk_result = classify_risk_bedrock(content)
        risk_level = risk_result['riskLevel']
        confidence = risk_result['confidence']
        reasoning = risk_result['reasoning']
        
        # Store submission in DynamoDB
        submission_item = {
            'PK': f'SUBMISSION#{submission_id}',
            'SK': f'METADATA#{timestamp}',
            'submissionId': submission_id,
            'anonymousId': anonymous_id,
            'content': content,
            'riskLevel': risk_level,
            'confidence': Decimal(str(confidence)),
            'reasoning': reasoning,
            'status': 'active' if risk_level != 'HIGH' else 'high_risk',
            'timestamp': timestamp,
            'region': region,
            'createdAt': timestamp
        }
        
        table.put_item(Item=submission_item)
        
        # Handle based on risk level
        if risk_level == 'HIGH':
            # Return crisis resources
            crisis_resources = get_crisis_resources(region)
            return create_response(200, {
                'submissionId': submission_id,
                'riskLevel': risk_level,
                'crisisResources': crisis_resources,
                'message': 'We\'re concerned about your safety. Please reach out to these professional resources.'
            })
        else:
            # Generate embedding
            embedding = generate_embedding_bedrock(content)
            
            if embedding:
                # Convert embedding floats to Decimals for DynamoDB
                embedding_decimals = [Decimal(str(float(x))) for x in embedding]
                
                # Store embedding with submission
                table.update_item(
                    Key={
                        'PK': f'SUBMISSION#{submission_id}',
                        'SK': f'METADATA#{timestamp}'
                    },
                    UpdateExpression='SET embedding = :emb, embeddingModel = :model',
                    ExpressionAttributeValues={
                        ':emb': embedding_decimals,
                        ':model': EMBEDDING_MODEL_ID
                    }
                )
                
                # Find similar users synchronously
                similar_users = find_similar_users(embedding, anonymous_id, submission_id)
                
                # Get support groups (mock for now)
                support_groups = get_support_groups(risk_level, content)
                
                print(f"Found {len(similar_users)} similar users")
                
                return create_response(200, {
                    'submissionId': submission_id,
                    'riskLevel': risk_level,
                    'similarUsers': similar_users,
                    'supportGroups': support_groups,
                    'message': f'Found {len(similar_users)} people with similar experiences'
                })
            else:
                # No embedding generated
                return create_response(200, {
                    'submissionId': submission_id,
                    'riskLevel': risk_level,
                    'similarUsers': [],
                    'supportGroups': [],
                    'message': 'Post submitted successfully'
                })
    
    except BedrockInvocationError as e:
        print(f"Bedrock unavailable during submission handling: {str(e)}")
        return create_response(503, {
            'error': 'Risk classification service is temporarily unavailable',
            'details': str(e)
        })
    except Exception as e:
        print(f"Error in submission handler: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return create_response(500, {'error': 'Internal server error', 'details': str(e)})


def validate_input(body):
    """Validate submission input"""
    if not body.get('anonymousId'):
        return 'anonymousId is required'
    
    if not body.get('content'):
        return 'content is required'
    
    content = body.get('content', '')
    if len(content) < 50:
        return 'Content must be at least 50 characters'
    
    if len(content) > 2000:
        return 'Content must not exceed 2000 characters'
    
    if not body.get('consent'):
        return 'Consent acknowledgment is required'
    
    return None


def classify_risk_bedrock(content):
    """Classify risk level using Amazon Nova Lite via Bedrock"""
    try:
        prompt = f"""Analyze this text and classify mental health risk level.

Text: "{content}"

Classification Guidelines:
- HIGH: Suicidal thoughts, self-harm intent, immediate danger, harm to others
- MEDIUM: Depression, anxiety, significant distress (but no immediate danger)
- LOW: General stress, everyday challenges, seeking peer support

You must respond with ONLY valid JSON, no other text. Use this exact format:
{{"riskLevel": "LOW", "confidence": 0.85, "reasoning": "brief explanation"}}

Your JSON response:"""

        request_body = {
            "messages": [
                {
                    "role": "user",
                    "content": [{"text": prompt}]
                }
            ],
            "inferenceConfig": {
                "maxTokens": 500,
                "temperature": 0.1,
                "topP": 0.9
            }
        }
        
        response_body = invoke_bedrock_model(
            model_id=RISK_MODEL_ID,
            request_body=request_body
        )
        result_text = response_body['output']['message']['content'][0]['text'].strip()
        
        print(f"Raw Bedrock response: {result_text}")
        
        # Try to extract JSON from response (sometimes wrapped in markdown)
        if '```json' in result_text:
            json_start = result_text.find('```json') + 7
            json_end = result_text.find('```', json_start)
            result_text = result_text[json_start:json_end].strip()
        elif '```' in result_text:
            json_start = result_text.find('```') + 3
            json_end = result_text.find('```', json_start)
            result_text = result_text[json_start:json_end].strip()
        
        # Parse JSON from response
        result = json.loads(result_text)
        
        # Validate risk level
        if result['riskLevel'] not in ['LOW', 'MEDIUM', 'HIGH']:
            print(f"Invalid risk level: {result['riskLevel']}, defaulting to HIGH")
            result['riskLevel'] = 'HIGH'
        
        print(f"Risk classification successful: {result['riskLevel']}")
        return result
    
    except BedrockInvocationError:
        raise
    except Exception as e:
        print(f"Error in risk classification: {str(e)}")
        print(f"Error type: {type(e).__name__}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        # Default to HIGH risk on any error (safety first)
        return {
            'riskLevel': 'HIGH',
            'confidence': 0.0,
            'reasoning': 'Error in classification, defaulting to HIGH for safety'
        }


def generate_embedding_bedrock(content):
    """Generate embedding using Titan Embeddings v2 via Bedrock"""
    try:
        request_body = {
            "inputText": content,
            "dimensions": 1024,
            "normalize": True
        }
        
        response_body = invoke_bedrock_model(
            model_id=EMBEDDING_MODEL_ID,
            request_body=request_body
        )
        embedding = response_body['embedding']
        
        return embedding
    
    except Exception as e:
        print(f"Error generating embedding: {str(e)}")
        return None


def find_similar_users(user_embedding, user_anonymous_id, user_submission_id):
    """
    Find similar users using cosine similarity
    Returns top 5 matches above threshold
    """
    try:
        # Convert to numpy array
        user_emb_array = np.array(user_embedding)
        print(f"User embedding shape: {user_emb_array.shape}")
        
        # Query all active submissions from DynamoDB
        print(f"Querying StatusIndex for active submissions...")
        response = table.query(
            IndexName='StatusIndex',
            KeyConditionExpression='#status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'active'}
        )
        
        candidates = response.get('Items', [])
        print(f"Found {len(candidates)} active submissions in match pool")
        
        # Log details about candidates
        candidates_with_embedding = [c for c in candidates if 'embedding' in c]
        print(f"Candidates with embeddings: {len(candidates_with_embedding)}")
        
        matches = []
        similarity_scores = []
        
        for candidate in candidates:
            # Skip if no embedding
            if 'embedding' not in candidate:
                print(f"Skipping candidate {candidate.get('submissionId', 'unknown')}: no embedding")
                continue
            
            # Skip self
            if candidate.get('anonymousId') == user_anonymous_id:
                print(f"Skipping candidate {candidate.get('submissionId', 'unknown')}: same user")
                continue
            
            # Skip same submission
            if candidate.get('submissionId') == user_submission_id:
                print(f"Skipping candidate {candidate.get('submissionId', 'unknown')}: same submission")
                continue
            
            # Skip HIGH risk users
            if candidate.get('riskLevel') == 'HIGH':
                print(f"Skipping candidate {candidate.get('submissionId', 'unknown')}: HIGH risk")
                continue
            
            # Calculate cosine similarity
            candidate_embedding = np.array([float(x) for x in candidate['embedding']])
            similarity = cosine_similarity(user_emb_array, candidate_embedding)
            similarity_scores.append(similarity)
            
            print(f"Candidate {candidate.get('submissionId', 'unknown')}: similarity={similarity:.3f}")
            
            if similarity >= SIMILARITY_THRESHOLD:
                # Calculate time ago
                timestamp_str = candidate.get('timestamp', '')
                last_active = calculate_time_ago(timestamp_str)
                
                matches.append({
                    'id': candidate.get('submissionId'),
                    'anonymousName': f"Anonymous {generate_animal_name(candidate.get('anonymousId'))}",
                    'similarityScore': round(float(similarity), 2),
                    'lastActive': last_active,
                    'commonTheme': extract_theme(candidate.get('content', ''))
                })
        
        # Log similarity statistics
        if similarity_scores:
            print(f"Similarity scores - min: {min(similarity_scores):.3f}, max: {max(similarity_scores):.3f}, avg: {sum(similarity_scores)/len(similarity_scores):.3f}")
            print(f"Threshold: {SIMILARITY_THRESHOLD}")
        
        # Sort by similarity (highest first) and take top 5
        matches.sort(key=lambda x: x['similarityScore'], reverse=True)
        top_matches = matches[:5]
        
        print(f"Returning {len(top_matches)} matches above threshold {SIMILARITY_THRESHOLD}")
        return top_matches
    
    except Exception as e:
        print(f"Error finding similar users: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return []


def cosine_similarity(vec1, vec2):
    """Calculate cosine similarity between two vectors"""
    dot_product = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    
    if norm1 == 0 or norm2 == 0:
        return 0.0
    
    return dot_product / (norm1 * norm2)


def get_support_groups(risk_level, content):
    """
    Get suggested support groups based on risk level and content
    For MVP, return mock data - can be enhanced later
    """
    groups = []
    
    # Analyze content for keywords
    content_lower = content.lower()
    
    if 'work' in content_lower or 'job' in content_lower or 'career' in content_lower:
        groups.append({
            'id': 'group-work-stress',
            'name': 'Work Stress Support',
            'theme': 'Connect with others managing workplace challenges',
            'memberCount': 24,
            'createdAt': datetime.now(timezone.utc).isoformat()
        })
    
    if 'anxiety' in content_lower or 'anxious' in content_lower or 'worried' in content_lower:
        groups.append({
            'id': 'group-anxiety',
            'name': 'Anxiety Support Circle',
            'theme': 'Share coping strategies for anxiety',
            'memberCount': 42,
            'createdAt': datetime.now(timezone.utc).isoformat()
        })
    
    if 'stress' in content_lower or 'stressed' in content_lower or 'pressure' in content_lower:
        groups.append({
            'id': 'group-stress-management',
            'name': 'Stress Management',
            'theme': 'Learn and share stress reduction techniques',
            'memberCount': 31,
            'createdAt': datetime.now(timezone.utc).isoformat()
        })
    
    # Default general group if no specific matches
    if not groups:
        groups.append({
            'id': 'group-general-support',
            'name': 'General Support',
            'theme': 'A welcoming space for all experiences',
            'memberCount': 67,
            'createdAt': datetime.now(timezone.utc).isoformat()
        })
    
    return groups[:3]  # Return max 3 groups


def generate_animal_name(anonymous_id):
    """Generate a consistent animal name from anonymous ID"""
    animals = [
        'Butterfly', 'Phoenix', 'Dove', 'Eagle', 'Owl', 'Swan', 
        'Dolphin', 'Panda', 'Tiger', 'Lion', 'Bear', 'Wolf',
        'Fox', 'Deer', 'Rabbit', 'Hawk', 'Falcon', 'Raven'
    ]
    # Use hash of ID to consistently pick same animal
    hash_val = sum(ord(c) for c in anonymous_id)
    return animals[hash_val % len(animals)]


def calculate_time_ago(timestamp_str):
    """Calculate human-readable time ago from ISO timestamp"""
    try:
        timestamp = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        now = datetime.now(timezone.utc)
        diff = now - timestamp
        
        if diff.days > 0:
            return f"{diff.days} day{'s' if diff.days > 1 else ''} ago"
        elif diff.seconds >= 3600:
            hours = diff.seconds // 3600
            return f"{hours} hour{'s' if hours > 1 else ''} ago"
        elif diff.seconds >= 60:
            minutes = diff.seconds // 60
            return f"{minutes} minute{'s' if minutes > 1 else ''} ago"
        else:
            return "just now"
    except Exception as e:
        print(f"Error calculating time ago: {e}")
        return "recently"


def extract_theme(content):
    """Extract a brief theme from content"""
    content_lower = content.lower()
    
    # Check for common themes
    if 'work' in content_lower or 'job' in content_lower:
        return 'Work-related stress'
    elif 'study' in content_lower or 'exam' in content_lower or 'school' in content_lower:
        return 'Academic pressure'
    elif 'anxiety' in content_lower or 'anxious' in content_lower:
        return 'Anxiety and worry'
    elif 'lonely' in content_lower or 'alone' in content_lower:
        return 'Feeling isolated'
    elif 'relationship' in content_lower or 'family' in content_lower:
        return 'Relationship challenges'
    else:
        return 'Similar feelings'


def invoke_bedrock_model(model_id, request_body):
    """Invoke a Bedrock model with error handling"""
    try:
        response = bedrock_runtime.invoke_model(
            modelId=model_id,
            body=json.dumps(request_body),
            contentType='application/json',
            accept='application/json'
        )
        return json.loads(response['body'].read())
    except ClientError as e:
        error = e.response.get('Error', {})
        request_id = e.response.get('ResponseMetadata', {}).get('RequestId')
        availability = get_model_availability(model_id)
        availability_text = json.dumps(availability) if availability is not None else 'unavailable'

        raise BedrockInvocationError(
            f"Bedrock invoke failed for model '{model_id}' in region '{AWS_REGION}'. "
            f"code={error.get('Code')} message={error.get('Message')} "
            f"requestId={request_id} availability={availability_text}",
            error_code=error.get('Code'),
            availability=availability
        ) from e


def get_model_availability(model_id):
    """Best-effort model availability lookup"""
    try:
        response = bedrock.get_foundation_model_availability(modelId=model_id)
        return {
            'agreementStatus': response.get('agreementAvailability', {}).get('status'),
            'agreementError': response.get('agreementAvailability', {}).get('errorMessage'),
            'authorizationStatus': response.get('authorizationStatus'),
            'entitlementAvailability': response.get('entitlementAvailability'),
            'regionAvailability': response.get('regionAvailability')
        }
    except ClientError as e:
        error = e.response.get('Error', {})
        print(f"Could not retrieve Bedrock model availability for '{model_id}': "
              f"{error.get('Code')} - {error.get('Message')}")
        return None


def get_crisis_resources(region='US'):
    """Retrieve crisis resources from DynamoDB for the given region"""
    try:
        response = table.query(
            KeyConditionExpression='PK = :pk',
            ExpressionAttributeValues={':pk': f'CRISIS_RESOURCE#{region}'}
        )
        
        resources = []
        for item in response.get('Items', []):
            resource = {
                'name': item.get('name'),
                'phone': item.get('phone'),
                'description': item.get('description'),
                'available24_7': item.get('available24_7', False)
            }
            
            if 'url' in item:
                resource['url'] = item['url']
            if 'hours' in item:
                resource['hours'] = item['hours']
            if 'smsKeyword' in item:
                resource['smsKeyword'] = item['smsKeyword']
            if 'language' in item:
                resource['language'] = item['language']
            
            resources.append(resource)
        
        # Sort by priority
        resources.sort(key=lambda x: x.get('priority', 999))
        
        # If no resources found in DB, return defaults
        if not resources:
            print(f"No crisis resources found in DB for region {region}, using defaults")
            return get_default_crisis_resources(region)
        
        return resources
    
    except Exception as e:
        print(f"Error retrieving crisis resources: {str(e)}")
        return get_default_crisis_resources(region)


def get_default_crisis_resources(region='US'):
    """Return default crisis resources when DB query fails or returns empty"""
    if region == 'NEPAL':
        return [
            {
                'name': 'Nepal Mental Health Helpline',
                'phone': '1660-01-19-000',
                'description': '24/7 free mental health support and counseling in Nepali',
                'available24_7': True,
                'language': 'Nepali, English'
            },
            {
                'name': 'TPO Nepal Helpline',
                'phone': '01-4102037',
                'description': 'Mental health and psychosocial support services',
                'available24_7': False,
                'url': 'https://tponepal.org',
                'hours': 'Sunday-Friday, 10am-5pm',
                'language': 'Nepali, English'
            }
        ]
    else:
        return [
            {
                'name': '988 Suicide & Crisis Lifeline',
                'phone': '988',
                'description': '24/7 free and confidential support for people in distress',
                'available24_7': True
            },
            {
                'name': 'NAMI Helpline',
                'phone': '1-800-950-6264',
                'description': 'Information, referrals and support for mental health',
                'available24_7': False,
                'url': 'https://www.nami.org/help',
                'hours': 'Monday-Friday, 10am-10pm ET',
                'language': 'English'
            }
        ]


def create_response(status_code, body):
    """Create HTTP response"""
    safe_body = _json_safe(body)
    response = {
        'statusCode': status_code,
        'isBase64Encoded': False,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'POST, OPTIONS'
        },
        'body': json.dumps(safe_body)
    }
    print(f"Returning response: {json.dumps(response)}")
    return response
