# Premium Podcast Feature Deployment Guide

This guide outlines the steps required to deploy the Premium Podcast feature to production.

## Prerequisites

- Supabase account with access to the project
- OpenAI API key with access to GPT-4 and TTS APIs
- Xcode 15.0+ for iOS app deployment
- Deno CLI for testing Supabase Edge Functions locally

## Deployment Steps

### 1. Database Setup

1. Apply the SQL migration to create the `premium_podcasts` table:

```bash
cd supabase
supabase db push
```

This will apply the migration in `supabase/migrations/20250305_premium_podcasts.sql`.

2. Verify the table was created successfully:

```bash
supabase db query "SELECT * FROM premium_podcasts LIMIT 1;"
```

### 2. Edge Function Deployment

1. Set the required environment variables in the Supabase dashboard:
   - `OPENAI_API_KEY`: Your OpenAI API key
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key

2. Deploy the Edge Function:

```bash
cd supabase
supabase functions deploy generate-premium-podcast
```

3. Test the Edge Function:

```bash
curl -X POST 'https://[YOUR_PROJECT_REF].supabase.co/functions/v1/generate-premium-podcast' \
  -H 'Authorization: Bearer [YOUR_ANON_KEY]' \
  -H 'Content-Type: application/json' \
  -d '{"topic": "Faith and Prayer", "duration": 15, "voices": ["alloy", "echo"], "initialRequest": true}'
```

### 3. Storage Bucket Setup

1. Create a new storage bucket for podcast audio files:

```bash
supabase storage create premium-podcasts
```

2. Set the bucket policy to allow authenticated users to read files:

```bash
supabase storage update premium-podcasts --public=false
```

3. Create a policy to allow the service role to upload files:

```sql
CREATE POLICY "Service role can upload" 
ON storage.objects 
FOR INSERT 
TO authenticated 
USING (bucket_id = 'premium-podcasts' AND auth.role() = 'service_role');
```

### 4. iOS App Deployment

1. Update the app's Info.plist to include the necessary permissions:
   - Background audio playback
   - Network access

2. Update the app's entitlements to include:
   - App Groups (if needed for background audio)
   - In-App Purchase (for premium subscription)

3. Archive and upload the app to App Store Connect:
   - Open the project in Xcode
   - Select Product > Archive
   - Follow the upload process in the Organizer window

### 5. Monitoring and Logging

1. Set up logging for the Edge Function:

```bash
supabase functions logs generate-premium-podcast --tail
```

2. Create a dashboard in the Supabase UI to monitor:
   - Number of podcasts generated
   - Character usage per user
   - Error rates

### 6. Testing

1. Run the unit tests to verify functionality:

```bash
cd /path/to/ios/project
xcodebuild test -scheme SoulAI -destination 'platform=iOS Simulator,name=iPhone 15'
```

2. Perform manual testing:
   - Generate podcasts with different durations
   - Test with different voice combinations
   - Verify character usage tracking
   - Test error handling scenarios

## Rollback Plan

If issues are encountered during deployment:

1. Revert the Edge Function:

```bash
supabase functions delete generate-premium-podcast
supabase functions deploy generate-premium-podcast --version=previous
```

2. Revert the database migration:

```sql
DROP TABLE IF EXISTS premium_podcasts;
```

3. Submit an expedited app update if issues are found in the iOS app.

## Post-Deployment Verification

1. Generate a test podcast and verify:
   - The podcast is created in the database
   - The audio is generated and stored correctly
   - The podcast appears in the app's UI

2. Monitor error logs for the first 24 hours after deployment.

3. Check user feedback and analytics to ensure the feature is being used as expected.

## Contact Information

For deployment issues, contact:
- Backend: [backend-team@example.com]
- iOS: [ios-team@example.com]
- DevOps: [devops-team@example.com] 