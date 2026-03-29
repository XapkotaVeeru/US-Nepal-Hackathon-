# Debugging Similar User Matching

## Issue
After posting, the app is not returning similar users even though there are submissions with similar content in DynamoDB.

## Enhanced Logging Added
The Lambda function now includes detailed logging to help debug the matching process:

1. **Embedding shape** - Verifies the embedding vector size
2. **Query results** - Shows how many active submissions were found
3. **Candidates with embeddings** - Shows how many have embeddings stored
4. **Skip reasons** - Logs why each candidate was skipped (no embedding, same user, HIGH risk, etc.)
5. **Similarity scores** - Shows the similarity score for each candidate
6. **Statistics** - Shows min/max/avg similarity scores and the threshold

## Deployment Steps

### 1. Update Lambda Function Code

```bash
cd lambda/submission_handler
zip -r function.zip lambda_function.py requirements.txt
```

### 2. Upload to AWS Lambda

1. Go to AWS Lambda Console → Functions → `PeerSupportSubmissionHandler`
2. Click "Upload from" → ".zip file"
3. Upload `function.zip`
4. Click "Save"

### 3. Test with Similar Posts

Submit two similar posts from the Flutter app:

**Post 1:**
```
I have been feeling stressed about work lately and could use some support from others who understand what it is like to balance career pressure with mental health.
```

**Post 2:**
```
Work has been really overwhelming and I'm struggling to manage the stress. Looking for people who can relate to dealing with job pressure.
```

### 4. Check CloudWatch Logs

1. Go to CloudWatch → Log groups → `/aws/lambda/PeerSupportSubmissionHandler`
2. Look for the latest log stream
3. Check for these key log lines:

```
User embedding shape: (1024,)
Querying StatusIndex for active submissions...
Found X active submissions in match pool
Candidates with embeddings: Y
Candidate <id>: similarity=0.XXX
Similarity scores - min: 0.XXX, max: 0.XXX, avg: 0.XXX
Threshold: 0.75
Returning N matches above threshold 0.75
```

## Common Issues and Solutions

### Issue 1: "Found 0 active submissions in match pool"
**Cause:** StatusIndex GSI is not working or submissions don't have `status='active'`

**Solution:**
1. Check DynamoDB table → Indexes tab → Verify StatusIndex exists
2. Check existing submissions have `status` attribute set to `'active'`
3. If StatusIndex doesn't exist, create it:
   - Partition key: `status` (String)
   - Sort key: `timestamp` (String)

### Issue 2: "Candidates with embeddings: 0"
**Cause:** Embeddings are not being stored in DynamoDB

**Solution:**
1. Check CloudWatch logs for "Error generating embedding"
2. Verify Bedrock permissions in IAM role
3. Check if `amazon.titan-embed-text-v2:0` model is accessible

### Issue 3: Similarity scores all below 0.75
**Cause:** Threshold is too high or embeddings are not similar enough

**Solution:**
1. Check the similarity scores in logs (min/max/avg)
2. If scores are close (e.g., 0.70-0.74), temporarily lower threshold:
   ```python
   SIMILARITY_THRESHOLD = float(os.getenv('SIMILARITY_THRESHOLD', '0.65'))
   ```
3. Or set environment variable in Lambda:
   - Configuration → Environment variables
   - Add: `SIMILARITY_THRESHOLD` = `0.65`

### Issue 4: "Skipping candidate: same user"
**Cause:** Both posts are from the same anonymousId

**Solution:**
- Use different devices or clear app data to get a new anonymousId
- Or manually test with different anonymousId values in API Gateway

### Issue 5: StatusIndex query fails
**Cause:** GSI might not be properly configured

**Alternative Solution - Use Scan instead of Query:**
```python
# Replace the query with a scan (less efficient but works without GSI)
response = table.scan(
    FilterExpression='#status = :status',
    ExpressionAttributeNames={'#status': 'status'},
    ExpressionAttributeValues={':status': 'active'}
)
```

## Testing Checklist

- [ ] Lambda function updated with new code
- [ ] Two similar posts submitted from different anonymousIds
- [ ] CloudWatch logs show "Found X active submissions" (X > 0)
- [ ] CloudWatch logs show "Candidates with embeddings: Y" (Y > 0)
- [ ] CloudWatch logs show similarity scores
- [ ] If scores < 0.75, consider lowering threshold
- [ ] Flutter app displays similar users in match results

## Expected Log Output (Success Case)

```
Received event: {...}
Parsed body: {"anonymousId": "user-123", "content": "...", ...}
Raw Bedrock response: {"riskLevel": "MEDIUM", ...}
Risk classification successful: MEDIUM
User embedding shape: (1024,)
Querying StatusIndex for active submissions...
Found 3 active submissions in match pool
Candidates with embeddings: 3
Skipping candidate abc-123: same submission
Candidate def-456: similarity=0.892
Candidate ghi-789: similarity=0.734
Similarity scores - min: 0.734, max: 0.892, avg: 0.813
Threshold: 0.75
Returning 1 matches above threshold 0.75
Returning response: {"statusCode": 200, "body": "{\"submissionId\": \"...\", \"similarUsers\": [{...}], ...}"}
```

## Next Steps

1. Deploy the updated Lambda function
2. Submit test posts
3. Check CloudWatch logs
4. Share the log output here so we can diagnose the issue
