# Supabase Edge Function Update Instructions

To fix the podcast generation timeout issue and the not-null constraint error for the `audio_url` field, you need to update your Supabase Edge Function (`generate-podcast/index.ts`). Here's what you need to change:

## 1. Implement Two-Step Processing

Update your Edge Function to handle the initial request immediately and then continue processing in the background:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders, handleCORS, handleError } from "./utils.ts";
import { generateScript, generateMetadata, generateAudio } from "./openai-service.ts";
import { SupabaseService } from "./supabase-service.ts";

serve(async (req) => {
  const corsResponse = handleCORS(req);
  if (corsResponse) return corsResponse;

  try {
    const { bibleChapter, initialRequest } = await req.json();
    
    if (!bibleChapter) {
      throw new Error('Bible chapter is required');
    }

    const supabaseService = new SupabaseService();
    
    // If this is an initial request, create a pending podcast entry and return immediately
    if (initialRequest) {
      // Create a podcast entry with a placeholder audio URL to satisfy the not-null constraint
      const placeholderAudioUrl = "https://placeholder-url.com/generating.mp3";
      
      const pendingPodcast = await supabaseService.createPodcastEntry({
        title: `Generating: ${bibleChapter}`,
        description: "Your podcast is being generated. This may take a few minutes.",
        chapter: bibleChapter,
        audio_url: placeholderAudioUrl, // Use a placeholder to satisfy not-null constraint
        status: 'generating'
      });
      
      // Start the generation process in the background
      const podcastId = pendingPodcast.id;
      
      // Use Deno's runtime to continue processing in the background
      Deno.env.get('DENO_DEPLOYMENT_ID') && 
      Deno.runtime.waitUntil((async () => {
        try {
          // Generate the podcast content
          const script = await generateScript(bibleChapter);
          const metadata = await generateMetadata(script);
          const audioBuffer = await generateAudio(script);

          // Upload audio and update database entry
          const timestamp = new Date().getTime();
          const fileName = `${bibleChapter.replace(/\s+/g, '-')}-${timestamp}.mp3`;
          const audioUrl = await supabaseService.uploadAudio(fileName, audioBuffer);

          // Update the podcast entry with the real data
          await supabaseService.updatePodcastEntry(podcastId, {
            title: metadata.title,
            description: metadata.description,
            audio_url: audioUrl,
            status: 'ready'
          });
          
          console.log('Successfully generated podcast in background');
        } catch (error) {
          console.error('Background processing error:', error);
          
          // Update the podcast entry with error status
          await supabaseService.updatePodcastEntry(podcastId, {
            status: 'failed',
            description: `Error generating podcast: ${error.message}`
          });
        }
      })());
      
      // Return the pending podcast immediately
      return new Response(
        JSON.stringify(pendingPodcast),
        { 
          headers: { 
            ...corsHeaders,
            'Content-Type': 'application/json'
          }
        }
      );
    }
    
    // If not an initial request (legacy support), process synchronously
    // Generate the podcast content
    const script = await generateScript(bibleChapter);
    const metadata = await generateMetadata(script);
    const audioBuffer = await generateAudio(script);

    // Upload audio and create database entry
    const timestamp = new Date().getTime();
    const fileName = `${bibleChapter.replace(/\s+/g, '-')}-${timestamp}.mp3`;
    const audioUrl = await supabaseService.uploadAudio(fileName, audioBuffer);

    const podcast = await supabaseService.createPodcastEntry({
      title: metadata.title,
      description: metadata.description,
      chapter: bibleChapter,
      audio_url: audioUrl,
      status: 'ready'
    });

    console.log('Successfully created podcast:', podcast);

    return new Response(
      JSON.stringify(podcast),
      { 
        headers: { 
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    );

  } catch (error) {
    return handleError(error);
  }
});
```

## 2. Add updatePodcastEntry Method to SupabaseService

Add this method to your `supabase-service.ts` file:

```typescript
async updatePodcastEntry(id: string, updateData: {
  title?: string;
  description?: string;
  audio_url?: string;
  status?: string;
}) {
  console.log('Updating podcast entry:', id, updateData);
  
  const { data: podcast, error: dbError } = await this.client
    .from('podcasts')
    .update(updateData)
    .eq('id', id)
    .select()
    .single();

  if (dbError) {
    console.error('Database error:', dbError);
    throw new Error(`Failed to update database entry: ${JSON.stringify(dbError)}`);
  }

  if (!podcast) {
    throw new Error('Failed to update database entry: No data returned');
  }

  return podcast;
}
```

## 3. Deploy the Updated Function

After making these changes, deploy the updated function to your Supabase project:

```bash
cd supabase/functions
supabase functions deploy generate-podcast
```

These changes will:
1. Create a podcast entry with a placeholder audio URL immediately
2. Return the pending podcast to the client
3. Continue processing in the background
4. Update the podcast entry when processing is complete

This approach prevents timeout errors and provides a better user experience. 