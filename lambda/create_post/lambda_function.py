"""
createPost Lambda — Saves a post to DynamoDB.
The DynamoDB Stream then triggers classifyRisk automatically.
"""
import json
import logging
import os
import uuid
from datetime import datetime

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
POSTS_TABLE = os.environ.get("POSTS_TABLE", "mindconnect-dev-posts")

CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
}


def handler(event, context):
    logger.info(f"createPost event: {json.dumps(event)}")

    # Handle API Gateway v2 payload
    try:
        body = json.loads(event.get("body", "{}"))
    except (json.JSONDecodeError, TypeError):
        body = {}

    anonymous_id = body.get("anonymousId", "unknown")
    content = body.get("content", "")

    if not content or len(content) < 10:
        return {
            "statusCode": 400,
            "headers": CORS_HEADERS,
            "body": json.dumps({"error": "Content must be at least 10 characters"}),
        }

    post_id = str(uuid.uuid4())
    timestamp = datetime.utcnow().isoformat() + "Z"

    item = {
        "id": post_id,
        "anonymousId": anonymous_id,
        "content": content,
        "createdAt": timestamp,
        "status": "pending_classification",
        "riskLevel": "pending",
    }

    try:
        table = dynamodb.Table(POSTS_TABLE)
        table.put_item(Item=item)
        logger.info(f"Post saved: {post_id}")
    except Exception as e:
        logger.error(f"DynamoDB error: {e}")
        return {
            "statusCode": 500,
            "headers": CORS_HEADERS,
            "body": json.dumps({"error": "Failed to save post"}),
        }

    # Return immediately — classifyRisk will be triggered by DynamoDB Stream
    return {
        "statusCode": 201,
        "headers": CORS_HEADERS,
        "body": json.dumps(
            {
                "submissionId": post_id,
                "riskLevel": "pending",
                "message": "Post submitted. AI analysis will begin shortly.",
                "createdAt": timestamp,
            }
        ),
    }
