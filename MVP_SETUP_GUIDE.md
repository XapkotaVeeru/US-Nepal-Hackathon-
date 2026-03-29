# MVP Setup Guide - Core Flow Only

## Goal
Get the basic flow working: **Submit Post → Risk Classification → Matching → Chat**

Skip all extras: monitoring, property tests, feedback, deletion, etc.

---

## AWS Setup (us-east-1)

### 1. Enable Bedrock Models
- AWS Console → Bedrock (us-east-1) → Model access
- Enable: `Amazon Nova Lite` and `Amazon Titan Embeddings G1 - Text v2`

### 2. Create DynamoDB Table
- Table name: `PeerSupportData`
- Partition key: `PK` (String)
- Sort key: `SK` (String)
- **Create 2 GSIs only:**
  - `StatusIndex`: GSI with PK=`status`, SK=`timestamp`
  - `AnonymousIdIndex`: GSI with PK=`anonymousId`, SK=`timestamp`

### 3. Add Crisis Resources
Add these items to DynamoDB:

**Nepal Resource:**
```json
{
  "PK": "CRISIS_RESOURCE#NEPAL",
  "SK": "RESOURCE#001",
  "name": "Nepal Mental Health Helpline",
  "phone": "1660-01-19-000",
  "description": "24/7 free mental health support and counseling in Nepali",
  "available24_7": true,
  "language": "Nepali, English",
  "priority": 1
}
```

**US Resource:**
```json
{
  "PK": "CRISIS_RESOURCE#US",
  "SK": "RESOURCE#001",
  "name": "988 Suicide & Crisis Lifeline",
  "phone": "988",
  "description": "24/7 free and confidential support for people in distress",
  "available24_7": true,
  "priority": 1
}
```

### 4. Create IAM Role
- Name: `PeerSupportLambdaRole`
- Attach these policies:
  - `AWSLambdaBasicExecutionRole` (managed)
  - Custom inline policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": [
        "arn:aws:dynamodb:us-east-1:*:table/PeerSupportData",
        "arn:aws:dynamodb:us-east-1:*:table/PeerSupportData/index/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:GetFoundationModelAvailability"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "arn:aws:lambda:us-east-1:*:function:PeerSupport*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "execute-api:ManageConnections"
      ],
      "Resource": "arn:aws:execute-api:us-east-1:*:*"
    }
  ]
}
```

---

## Lambda Functions to Create

### Lambda 1: Submission Handler ✅ (Already have code)
- Name: `PeerSupportSubmissionHandler`
- Runtime: Python 3.11
- Role: `PeerSupportLambdaRole`
- Memory: 512 MB
- Timeout: 30 seconds
- Code: Use `lambda/submission_handler/lambda_function.py`

### Lambda 2: Matching Handler (Need to create)
- Name: `PeerSupportMatchingHandler`
- Runtime: Python 3.11
- Role: `PeerSupportLambdaRole`
- Memory: 1024 MB (needs memory for vector calculations)
- Timeout: 60 seconds

### Lambda 3: WebSocket Connect (Need to create)
- Name: `PeerSupportWebSocketConnect`
- Runtime: Python 3.11
- Role: `PeerSupportLambdaRole`
- Memory: 256 MB
- Timeout: 10 seconds

### Lambda 4: WebSocket Disconnect (Need to create)
- Name: `PeerSupportWebSocketDisconnect`
- Runtime: Python 3.11
- Role: `PeerSupportLambdaRole`
- Memory: 256 MB
- Timeout: 10 seconds

### Lambda 5: WebSocket Message Handler (Need to create)
- Name: `PeerSupportWebSocketMessage`
- Runtime: Python 3.11
- Role: `PeerSupportLambdaRole`
- Memory: 512 MB
- Timeout: 30 seconds

---

## API Gateway Setup

### REST API
- Name: `PeerSupportAPI`
- Create routes:
  - `POST /submissions` → `PeerSupportSubmissionHandler`
- Enable CORS

### WebSocket API
- Name: `PeerSupportWebSocket`
- Create routes:
  - `$connect` → `PeerSupportWebSocketConnect`
  - `$disconnect` → `PeerSupportWebSocketDisconnect`
  - `sendMessage` → `PeerSupportWebSocketMessage`

---

## Next Steps

1. ✅ Submission Handler Lambda (already done)
2. Create Matching Handler Lambda
3. Create WebSocket Lambdas (3 functions)
4. Create API Gateway REST API
5. Create API Gateway WebSocket API
6. Update Flutter app with real API endpoints
7. Test end-to-end flow

---

## Testing the Flow

1. Submit a LOW risk post → Should return "searching for match"
2. Submit another LOW risk post → Should match with first user
3. Both users receive WebSocket notification
4. Users can chat via WebSocket
5. Submit a HIGH risk post → Should return crisis resources immediately
