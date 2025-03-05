# Podcast Generation Feature Updates

## Overview of Changes

We've implemented a robust solution to fix the timeout issues with the podcast generation feature in the iOS app while maintaining backward compatibility with the web app. Here's a summary of the changes:

### 1. Supabase Edge Function Updates

The `generate-podcast` Edge Function has been updated to support a two-step asynchronous process:

- **For iOS App (with `initialRequest: true`)**:
  - Creates a pending podcast entry with a placeholder audio URL
  - Returns immediately to prevent timeout errors
  - Continues processing in the background using `Deno.runtime.waitUntil()`
  - Updates the podcast entry when processing is complete

- **For Web App (without `initialRequest` parameter)**:
  - Processes the podcast generation synchronously as before
  - Returns the completed podcast entry when done
  - This maintains backward compatibility with the existing web app

### 2. New Methods Added

- Added `updatePodcastEntry` method to the `SupabaseService` class to update podcast entries after background processing

### 3. Placeholder Audio File

- Created instructions for uploading a placeholder audio file to Supabase storage
- This file is used as a temporary audio URL while the podcast is being generated
- It satisfies the not-null constraint for the `audio_url` field in the database

### 4. Deployment Scripts and Documentation

- Created a deployment script (`deploy-edge-function.sh`) to simplify deploying the updated Edge Function
- Added comprehensive documentation in README files

## Files Modified

1. `/web-version/supabase/functions/generate-podcast/index.ts`
2. `/web-version/supabase/functions/generate-podcast/supabase-service.ts`

## Files Created

1. `/web-version/supabase/storage/podcasts/README.md`
2. `/web-version/supabase/functions/deploy-edge-function.sh`
3. `/web-version/supabase/functions/generate-podcast/README.md`
4. `/PODCAST_GENERATION_UPDATES.md` (this file)

## Deployment Instructions

To deploy the updated Edge Function:

1. Navigate to the functions directory:
   ```bash
   cd web-version/supabase/functions
   ```

2. Run the deployment script:
   ```bash
   ./deploy-edge-function.sh
   ```

3. Upload the placeholder audio file as described in `/web-version/supabase/storage/podcasts/README.md`

## Testing

After deployment, you can test the function:

- **For iOS App**:
  ```bash
  curl -X POST https://<your-project-ref>.supabase.co/functions/v1/generate-podcast \
    -H "Authorization: Bearer <your-anon-key>" \
    -H "Content-Type: application/json" \
    -d '{"bibleChapter": "John 3", "initialRequest": true}'
  ```

- **For Web App**:
  ```bash
  curl -X POST https://<your-project-ref>.supabase.co/functions/v1/generate-podcast \
    -H "Authorization: Bearer <your-anon-key>" \
    -H "Content-Type: application/json" \
    -d '{"bibleChapter": "John 3"}'
  ```

## Backward Compatibility

The changes have been carefully designed to maintain backward compatibility with the web app:

- The web app will continue to work as before, using the synchronous processing path
- The iOS app will use the new asynchronous processing path with the `initialRequest: true` parameter
- Both apps will be able to fetch and display podcasts from the same database table

## Next Steps

1. Deploy the updated Edge Function
2. Upload the placeholder audio file
3. Test the podcast generation feature in both the iOS app and web app
4. Monitor the logs for any issues 