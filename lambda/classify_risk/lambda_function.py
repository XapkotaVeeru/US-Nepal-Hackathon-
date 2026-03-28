import json
import logging
import os
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
bedrock = boto3.client("bedrock-runtime")
lambda_client = boto3.client("lambda")

POSTS_TABLE = os.environ.get("POSTS_TABLE", "mindconnect-dev-posts")
MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "anthropic.claude-3-sonnet-20240229-v1:0")
MATCH_FUNCTION = os.environ.get("MATCH_FUNCTION_NAME", "")
CRISIS_TOPIC_ARN = os.environ.get("CRISIS_TOPIC_ARN", "")
sns = boto3.client('sns') if CRISIS_TOPIC_ARN else None

def analyze_risk(content):
    prompt = f"""
    Please analyze the following post from a mental health peer support app.
    Determine the risk level as one of: 'low', 'medium', 'high', 'crisis'.
    Return ONLY a JSON object with the following structure:
    {{
        "riskLevel": "high | medium | low | crisis",
        "reasoning": "brief explanation",
        "topics": ["topic1", "topic2"]
    }}
    
    Post content: "{content}"
    """
    
    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 512,
        "temperature": 0.0,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ]
    })
    
    try:
        response = bedrock.invoke_model(
            body=body,
            modelId=MODEL_ID,
            accept="application/json",
            contentType="application/json"
        )
        response_body = json.loads(response.get("body").read())
        text_content = response_body.get("content", [])[0].get("text", "{}")
        
        # Parse the JSON response
        import re
        json_match = re.search(r'\{.*\}', text_content, re.DOTALL)
        if json_match:
            return json.loads(json_match.group(0))
        return json.loads(text_content)
    except Exception as e:
        logger.error(f"Bedrock error: {e}")
        return {"riskLevel": "unknown", "reasoning": str(e), "topics": []}

def handler(event, context):
    logger.info(f"classifyRisk triggered by DynamoDB stream: {json.dumps(event)}")
    
    for record in event.get('Records', []):
        if record['eventName'] != 'INSERT':
            continue
            
        new_image = record['dynamodb']['NewImage']
        
        # DynamoDB types -> Python types
        post_id = new_image.get('id', {}).get('S')
        content = new_image.get('content', {}).get('S')
        anonymous_id = new_image.get('anonymousId', {}).get('S')
        
        if not post_id or not content:
            logger.warning("Missing post_id or content")
            continue
            
        logger.info(f"Analyzing post {post_id} from user {anonymous_id}")
        
        analysis = analyze_risk(content)
        risk_level = analysis.get("riskLevel", "unknown")
        topics = analysis.get("topics", [])
        
        # Update DynamoDB
        try:
            table = dynamodb.Table(POSTS_TABLE)
            table.update_item(
                Key={'id': post_id},
                UpdateExpression="set riskLevel = :r, postStatus = :s, topics = :t",
                ExpressionAttributeValues={
                    ':r': risk_level,
                    ':s': 'classified',
                    ':t': topics,
                }
            )
            logger.info(f"Updated post {post_id} with riskLevel {risk_level}")
        except Exception as e:
            logger.error(f"Failed to update DDB for {post_id}: {e}")
            
        # If crisis and we have an SNS topic (from Terraform), alert
        if risk_level == "crisis" and sns and CRISIS_TOPIC_ARN:
            try:
                sns.publish(
                    TopicArn=CRISIS_TOPIC_ARN,
                    Message=f"CRISIS ALERT for Post ID: {post_id}\nContent: {content}",
                    Subject="Crisis Alert: MindConnect"
                )
                logger.info("Published crisis alert to SNS")
            except Exception as e:
                logger.error(f"Failed to publish SNS: {e}")

        # Trigger matching logic if we have the lambda set up and it's not a crisis
        if MATCH_FUNCTION and risk_level != "crisis":
            try:
                lambda_client.invoke(
                    FunctionName=MATCH_FUNCTION,
                    InvocationType='Event',
                    Payload=json.dumps({
                        "postId": post_id,
                        "anonymousId": anonymous_id,
                        "content": content,
                        "topics": topics
                    })
                )
                logger.info(f"Triggered matchUsers for post {post_id}")
            except Exception as e:
                logger.error(f"Failed to invoke matchUsers: {e}")
                
    return {"statusCode": 200, "body": "Classified successfully"}
