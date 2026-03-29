# Flutter API Integration - Complete ✅

## API Endpoint
```
https://x0dge4fjri.execute-api.us-east-1.amazonaws.com/prod
```

## What's Integrated

### ✅ Submission Endpoint
- **URL**: `POST /submissions`
- **Flutter Service**: `lib/services/api_service.dart` → `submitPost()`
- **Provider**: `lib/providers/post_provider.dart`
- **UI**: `lib/widgets/create_post_card.dart`

### Request Format
```dart
{
  "anonymousId": "user-123",
  "content": "I've been feeling stressed...",
  "consent": true,
  "region": "US"
}
```

### Response Handling

**LOW/MEDIUM Risk Response:**
```json
{
  "submissionId": "uuid",
  "riskLevel": "LOW" or "MEDIUM",
  "status": "searching_for_match",
  "message": "We're finding people with similar experiences..."
}
```
- Shows "Searching for match..." message
- User stays on home screen
- Match results will appear when matching completes

**HIGH Risk Response:**
```json
{
  "submissionId": "uuid",
  "riskLevel": "HIGH",
  "crisisResources": [
    {
      "name": "988 Suicide & Crisis Lifeline",
      "phone": "988",
      "description": "24/7 support",
      "available24_7": true
    }
  ],
  "message": "We're concerned about your safety..."
}
```
- Shows crisis resources immediately
- Displays phone numbers with tap-to-call
- No matching occurs

## Testing the Integration

### Test 1: LOW Risk Submission
1. Open Flutter app
2. Write a post: "I've been feeling stressed about work lately and need support"
3. Submit
4. Should see: "Searching for match..." message
5. Check API Gateway logs to verify request was received

### Test 2: HIGH Risk Submission
1. Write a post with concerning content (use test case from earlier)
2. Submit
3. Should see: Crisis resources with phone numbers
4. Verify resources are displayed correctly

### Test 3: Error Handling
1. Turn off WiFi/mobile data
2. Try to submit a post
3. Should see: Error message
4. Turn on connectivity
5. Try again - should work

## Current Limitations (To Be Implemented)

### ⏳ Match Notifications
- Currently: User submits and sees "searching for match"
- Missing: Real-time notification when match is found
- **Need**: WebSocket integration

### ⏳ Chat Functionality
- Currently: No way to chat after match
- Missing: Real-time messaging
- **Need**: WebSocket API + Message Lambda functions

### ⏳ Session Management
- Currently: No way to view active sessions
- Missing: Session list, resume chat
- **Need**: GET /sessions endpoint

## Next Steps

1. **Implement WebSocket API** for real-time notifications
2. **Create Message Handler Lambda** for chat
3. **Add Session Endpoints** to view/manage sessions
4. **Update Flutter** to handle WebSocket connections

## Files Modified

- ✅ `lib/main.dart` - Updated API URL
- ✅ `lib/services/api_service.dart` - Fixed endpoint path, added consent & region
- ✅ `lib/providers/post_provider.dart` - Already handles responses correctly
- ✅ `lib/widgets/create_post_card.dart` - Already integrated with provider
- ✅ `lib/screens/home_screen.dart` - Already shows results

## Testing Commands

### Test from command line (curl):
```bash
curl -X POST https://x0dge4fjri.execute-api.us-east-1.amazonaws.com/prod/submissions \
  -H "Content-Type: application/json" \
  -d '{
    "anonymousId": "test-user",
    "content": "I have been feeling stressed about work lately and could use some support from others who understand what it is like to balance career pressure with mental health.",
    "consent": true,
    "region": "US"
  }'
```

### Test from Flutter:
```bash
# Run the app
flutter run

# Or for web
flutter run -d chrome
```

## Troubleshooting

### Issue: "Network error" in Flutter
- Check API URL is correct in `lib/main.dart`
- Verify API Gateway is deployed
- Check CORS is enabled on API Gateway

### Issue: "Failed to submit post: 400"
- Check request body format
- Verify content length (50-2000 chars)
- Ensure consent is true

### Issue: "Failed to submit post: 500"
- Check Lambda CloudWatch logs
- Verify DynamoDB table exists
- Check Bedrock model access

## Success Criteria ✅

- [x] Flutter app connects to real API
- [x] LOW/MEDIUM risk submissions work
- [x] HIGH risk submissions show crisis resources
- [x] Error handling works
- [x] Loading states display correctly
- [ ] Match notifications (WebSocket needed)
- [ ] Chat functionality (WebSocket needed)
