# Fix 502 Error from API Gateway

## Problem
Flutter app receives 502 error from API Gateway even though Lambda function executes successfully and returns data.

## Root Cause
API Gateway integration is not properly configured to handle Lambda proxy responses.

## Solution

### Option 1: Verify Lambda Proxy Integration (Recommended)

1. Go to **API Gateway Console** → Your API (`PeerSupportAPI`)
2. Click **Resources** → `/submissions` → `POST` method
3. Click **Integration Request**
4. Verify these settings:
   - Integration type: **Lambda Function**
   - ✅ **Use Lambda Proxy integration** (THIS MUST BE CHECKED)
   - Lambda Function: `PeerSupportSubmissionHandler`
   - Lambda Region: `us-east-1`

5. If "Use Lambda Proxy integration" is NOT checked:
   - Check the box
   - Click **Save**
   - You'll see a popup asking for permission - click **OK**

6. **Deploy the API**:
   - Click **Actions** → **Deploy API**
   - Deployment stage: `prod`
   - Click **Deploy**

### Option 2: Check Method Response

1. In API Gateway → `/submissions` → `POST`
2. Click **Method Response**
3. Verify HTTP Status 200 exists
4. If not, add it:
   - Click **Add Response**
   - HTTP Status: `200`
   - Click the checkmark

### Option 3: Check Integration Response

1. In API Gateway → `/submissions` → `POST`
2. Click **Integration Response**
3. Verify there's a mapping for HTTP status 200
4. If the mapping is incorrect or missing:
   - Delete existing mappings
   - Click **Add integration response**
   - Lambda Error Regex: (leave empty)
   - Method response status: `200`
   - Click **Save**

### Option 4: Test in API Gateway Console

1. In API Gateway → `/submissions` → `POST`
2. Click **Test** (lightning bolt icon)
3. Request Body:
```json
{
  "anonymousId": "test-user-123",
  "content": "I have been feeling stressed about work lately and could use some support from others who understand what it is like to balance career pressure with mental health.",
  "consent": true,
  "region": "US"
}
```
4. Click **Test**
5. Check the response:
   - Should show Status: 200
   - Should show the full response with similarUsers array

If the test works but the Flutter app still gets 502, the issue is with the deployment.

### Option 5: Redeploy API

Sometimes API Gateway needs a fresh deployment:

1. Go to **API Gateway Console** → Your API
2. Click **Actions** → **Deploy API**
3. Deployment stage: `prod`
4. Deployment description: "Fix 502 error"
5. Click **Deploy**
6. Wait 30 seconds for deployment to propagate
7. Test from Flutter app again

### Option 6: Check Lambda Timeout

1. Go to **Lambda Console** → `PeerSupportSubmissionHandler`
2. Click **Configuration** → **General configuration**
3. Verify:
   - Timeout: At least 30 seconds (currently should be 30s)
   - Memory: 512 MB or higher (currently 1024 MB)

### Option 7: Check CloudWatch Logs During 502

1. Submit a post from Flutter app
2. Immediately go to **CloudWatch** → **Log groups** → `/aws/lambda/PeerSupportSubmissionHandler`
3. Check the latest log stream
4. Look for:
   - "Returning response: ..." (should be there)
   - Any errors after that line
   - Check if Lambda completed successfully

## Verification Steps

After applying the fix:

1. **Test in API Gateway Console** (should return 200 with data)
2. **Test from Flutter app** (should show similar users)
3. **Check Flutter console** for:
```
submitPost status: 200
submitPost body: {"submissionId": "...", "similarUsers": [...], ...}
Similar users count: 3
```

## Most Likely Fix

Based on the symptoms, the most likely issue is:
- **Lambda Proxy Integration is not enabled**

Go to API Gateway → `/submissions` → POST → Integration Request → Check "Use Lambda Proxy integration" → Deploy API

This single change should fix the 502 error.
