import json
import os
import boto3
import uuid
from datetime import datetime, timezone
from decimal import Decimal
import numpy as np

# Environment configuration
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
TABLE_NAME = os.getenv('PEER_SUPPORT_TABLE', 'PeerSupportData')
SIMILARITY_THRESHOLD = float(os.getenv('SIMILARITY_THRESHOLD', '0.75'))

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
lambda_client = boto3.client('lambda', region_name=AWS_REGION)

# DynamoDB table
table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    """
    Main handler for matching processing
    Invoked asynchronously by Submission Handler
    """
    try:
        # Log the raw event for debugging
        print(f"Received event: {json.dumps(event)}")
        
        # Parse input
        submission_id = event.get('submissionId')
        anonymous_id = event.get('anonymousId')
        timestamp = event.get('timestamp')
        
        print(f"Processing match for submission {submission_id}, user {anonymous_id}")
        
        if not submission_id or not anonymous_id or not timestamp:
            print(f"Missing required fields: submissionId={submission_id}, anonymousId={anonymous_id}, timestamp={timestamp}")
            return {'statusCode': 400, 'message': 'Missing required fields'}
        
        # Retrieve the submission with embedding
        submission = get_submission(submission_id, timestamp)
        
        if not submission:
            print(f"Submission {submission_id} not found")
            return {'statusCode': 404, 'message': 'Submission not found'}
        
        if 'embedding' not in submission:
            print(f"Submission {submission_id} has no embedding")
            return {'statusCode': 400, 'message': 'Submission has no embedding'}
        
        # Get embedding as numpy array
        user_embedding = np.array([float(x) for x in submission['embedding']])
        
        # Find best match
        best_match = find_best_match(user_embedding, anonymous_id)
        
        if best_match:
            # Create session
            session_id = create_session(submission, best_match)
            
            print(f"Match found! Session {session_id} created between {anonymous_id} and {best_match['anonymousId']}")
            
            # Notify both users (will implement WebSocket later)
            # For now, just log
            print(f"TODO: Notify users via WebSocket about session {session_id}")
            
            return {
                'statusCode': 200,
                'message': 'Match found and session created',
                'sessionId': session_id
            }
        else:
            print(f"No match found for submission {submission_id}")
            return {
                'statusCode': 200,
                'message': 'No match found, user remains in active pool'
            }
    
    except Exception as e:
        print(f"Error in matching handler: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return {'statusCode': 500, 'message': 'Internal server error'}


def get_submission(submission_id, timestamp):
    """Retrieve submission from DynamoDB"""
    try:
        response = table.get_item(
            Key={
                'PK': f'SUBMISSION#{submission_id}',
                'SK': f'METADATA#{timestamp}'
            }
        )
        return response.get('Item')
    except Exception as e:
        print(f"Error retrieving submission: {str(e)}")
        return None


def find_best_match(user_embedding, user_anonymous_id):
    """
    Find best match using cosine similarity
    Returns the best matching submission or None
    """
    try:
        # Query all active submissions from DynamoDB
        response = table.query(
            IndexName='StatusIndex',
            KeyConditionExpression='#status = :status',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': 'active'
            }
        )
        
        candidates = response.get('Items', [])
        print(f"Found {len(candidates)} active submissions in match pool")
        
        best_match = None
        best_similarity = SIMILARITY_THRESHOLD
        
        for candidate in candidates:
            # Skip if no embedding
            if 'embedding' not in candidate:
                continue
            
            # Skip self
            if candidate.get('anonymousId') == user_anonymous_id:
                continue
            
            # Skip HIGH risk users (safety check)
            if candidate.get('riskLevel') == 'HIGH':
                continue
            
            # Calculate cosine similarity
            candidate_embedding = np.array([float(x) for x in candidate['embedding']])
            similarity = cosine_similarity(user_embedding, candidate_embedding)
            
            print(f"Similarity with {candidate.get('submissionId')}: {similarity:.3f}")
            
            # Update best match if this is better
            if similarity > best_similarity:
                best_similarity = similarity
                best_match = candidate
        
        if best_match:
            print(f"Best match: {best_match.get('submissionId')} with similarity {best_similarity:.3f}")
        else:
            print(f"No matches above threshold {SIMILARITY_THRESHOLD}")
        
        return best_match
    
    except Exception as e:
        print(f"Error finding match: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return None


def cosine_similarity(vec1, vec2):
    """Calculate cosine similarity between two vectors"""
    dot_product = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    
    if norm1 == 0 or norm2 == 0:
        return 0.0
    
    return dot_product / (norm1 * norm2)


def create_session(submission1, submission2):
    """
    Create a support session between two matched users
    Updates both submissions to 'matched' status
    """
    try:
        session_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Calculate similarity for session metadata
        emb1 = np.array([float(x) for x in submission1['embedding']])
        emb2 = np.array([float(x) for x in submission2['embedding']])
        similarity = cosine_similarity(emb1, emb2)
        
        # Create session record
        session_item = {
            'PK': f'SESSION#{session_id}',
            'SK': f'METADATA#{timestamp}',
            'sessionId': session_id,
            'participant1': submission1['anonymousId'],
            'participant2': submission2['anonymousId'],
            'submission1Id': submission1['submissionId'],
            'submission2Id': submission2['submissionId'],
            'similarity': Decimal(str(similarity)),
            'status': 'active',
            'createdAt': timestamp,
            'lastActivityAt': timestamp
        }
        
        table.put_item(Item=session_item)
        
        # Update submission 1 to matched status
        table.update_item(
            Key={
                'PK': f"SUBMISSION#{submission1['submissionId']}",
                'SK': submission1['SK']
            },
            UpdateExpression='SET #status = :status, sessionId = :sessionId, matchedAt = :matchedAt',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': 'matched',
                ':sessionId': session_id,
                ':matchedAt': timestamp
            }
        )
        
        # Update submission 2 to matched status
        table.update_item(
            Key={
                'PK': f"SUBMISSION#{submission2['submissionId']}",
                'SK': submission2['SK']
            },
            UpdateExpression='SET #status = :status, sessionId = :sessionId, matchedAt = :matchedAt',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': 'matched',
                ':sessionId': session_id,
                ':matchedAt': timestamp
            }
        )
        
        print(f"Session {session_id} created successfully")
        return session_id
    
    except Exception as e:
        print(f"Error creating session: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return None
