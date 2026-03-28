import json
import logging
import os
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
bedrock = boto3.client("bedrock-runtime")

MATCHES_TABLE = os.environ.get("MATCHES_TABLE", "mindconnect-dev-matches")
MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "amazon.titan-embed-text-v2:0")

def get_embedding(text):
    body = json.dumps({
        "inputText": text
    })
    try:
        response = bedrock.invoke_model(
            body=body, 
            modelId=MODEL_ID, 
            accept="application/json", 
            contentType="application/json"
        )
        response_body = json.loads(response.get("body").read())
        return response_body.get("embedding")
    except Exception as e:
        logger.error(f"Failed to get embedding: {e}")
        return None

def handler(event, context):
    logger.info(f"matchUsers invoked with event: {json.dumps(event)}")
    
    post_id = event.get("postId")
    content = event.get("content")
    anonymous_id = event.get("anonymousId")
    topic_tags = event.get("topics", [])
    
    if not all([post_id, content, anonymous_id]):
        return {"statusCode": 400, "body": "Missing required fields"}
        
    embedding = get_embedding(content)
    
    if not embedding:
         return {"statusCode": 500, "body": "Failed to generate embedding"}
         
    # Dummy matching logic - in a real app this would compare embeddings
    # against other users using OpenSearch or pgvector etc.
    # For now, we just save a mock match record to the matches table.
    
    import uuid
    from datetime import datetime
    
    match_id = str(uuid.uuid4())
    now_ts = datetime.utcnow().isoformat() + "Z"
    
    try:
        table = dynamodb.Table(MATCHES_TABLE)
        table.put_item(Item={
            "id": match_id,
            "postId": post_id,
            "userId1": anonymous_id,
            "userId2": "dummy-matched-user-123",
            "similarityScore": str(0.85),
            "topics": topic_tags,
            "status": "proposed",
            "createdAt": now_ts
        })
        logger.info(f"Stored match {match_id} into {MATCHES_TABLE}")
    except Exception as e:
        logger.error(f"Failed saving match: {e}")
        
    return {"statusCode": 200, "body": "Matched successfully"}
