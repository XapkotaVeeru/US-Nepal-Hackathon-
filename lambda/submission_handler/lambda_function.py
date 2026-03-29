import json
import os
import boto3
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from botocore.config import Config
from botocore.exceptions import ClientError

# Environment-driven configuration keeps the function portable across regions
# and makes model changes possible without code edits.
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
TABLE_NAME = os.getenv('PEER_SUPPORT_TABLE', 'PeerSupportData')
RISK_MODEL_ID = os.getenv('BEDROCK_RISK_MODEL_ID', 'amazon.nova-lite-v1:0')
EMBEDDING_MODEL_ID = os.getenv(
    'BEDROCK_EMBEDDING_MODEL_ID',
    'amazon.titan-embed-text-v2:0'
)
BEDROCK_CONFIG = Config(
    connect_timeout=10,
    read_timeout=3600,
    retries={'max_attempts': 3, 'mode': 'standard'}
)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
bedrock = boto3.client('bedrock', region_name=AWS_REGION, config=BEDROCK_CONFIG)
bedrock_runtime = boto3.client(
    'bedrock-runtime',
    region_name=AWS_REGION,
    config=BEDROCK_CONFIG
)
lambda_client = boto3.client('lambda', region_name=AWS_REGION)

# DynamoDB table
table = dynamodb.Table(TABLE_NAME)


class BedrockInvocationError(Exception):
    """Raised when Bedrock cannot be invoked due to auth/access/service issues."""

    def __init__(self, message, *, error_code=None, availability=None):
        super().__init__(message)
        self.error_code = error_code
        self.availability = availability or {}

def lambda_handler(event, context):
    """
    Main handler for submission processing
    """
    try:
        # Log the incoming event for debugging
        print(f"Received event: {json.dumps(event)}")
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        print(f"Parsed body: {json.dumps(body)}")
        
        # Validate input
        validation_error = validate_input(body)
        if validation_error:
            return create_response(400, {'error': validation_error})
        
        # Extract data
        anonymous_id = body.get('anonymousId')
        content = body.get('content')
        region = body.get('region', 'US')  # Default to US
        
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
            # Generate embedding and trigger matching
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
                        ':model': 'amazon.titan-embed-text-v2:0'
                    }
                )
            
            # Invoke matching lambda asynchronously
            try:
                lambda_client.invoke(
                    FunctionName='PeerSupportMatchingHandler',
                    InvocationType='Event',  # Async
                    Payload=json.dumps({
                        'submissionId': submission_id,
                        'anonymousId': anonymous_id,
                        'timestamp': timestamp
                    })
                )
            except Exception as e:
                print(f"Error invoking matching lambda: {str(e)}")
            
            return create_response(200, {
                'submissionId': submission_id,
                'riskLevel': risk_level,
                'status': 'searching_for_match',
                'message': 'We\'re finding people with similar experiences...'
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
    """
    Classify risk level using Amazon Nova Lite via Bedrock
    """
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
            # Extract JSON from markdown code block
            json_start = result_text.find('```json') + 7
            json_end = result_text.find('```', json_start)
            result_text = result_text[json_start:json_end].strip()
        elif '```' in result_text:
            # Extract from generic code block
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
    """
    Generate embedding using Titan Embeddings v2 via Bedrock
    """
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


def invoke_bedrock_model(model_id, request_body):
    """
    Invoke a Bedrock model and surface enough context to distinguish code
    issues from account, region, or authorization issues.
    """
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
        availability_text = (
            json.dumps(availability)
            if availability is not None
            else 'unavailable'
        )

        raise BedrockInvocationError(
            f"Bedrock invoke failed for model '{model_id}' in region "
            f"'{AWS_REGION}'. code={error.get('Code')} "
            f"message={error.get('Message')} requestId={request_id} "
            f"availability={availability_text}",
            error_code=error.get('Code'),
            availability=availability
        ) from e


def get_model_availability(model_id):
    """
    Best-effort model availability lookup. This is extremely useful when
    Bedrock returns vague messages such as 'Operation not allowed'.
    """
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
        print(
            f"Could not retrieve Bedrock model availability for '{model_id}': "
            f"{error.get('Code')} - {error.get('Message')}"
        )
        return None


def get_crisis_resources(region='US'):
    """
    Retrieve crisis resources from DynamoDB for the given region
    """
    try:
        response = table.query(
            KeyConditionExpression='PK = :pk',
            ExpressionAttributeValues={
                ':pk': f'CRISIS_RESOURCE#{region}'
            }
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
        # Default to US resources
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
    response = {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'POST, OPTIONS'
        },
        'body': json.dumps(body)
    }
    print(f"Returning response: {json.dumps(response)}")
    return response
