import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
import { corsHeaders } from "../_shared/cors.ts";

const openaiApiKey = Deno.env.get("OPENAI_API_KEY") || "";
const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

// Character limits based on duration
const CHARS_PER_MINUTE = 750;

// Create a Supabase client with the service role key
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Parse the request body
    const { topic, duration, voices, initialRequest } = await req.json();

    // Validate required fields
    if (!topic) {
      return new Response(
        JSON.stringify({ error: "Topic is required" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        }
      );
    }

    if (!duration || duration < 5 || duration > 60) {
      return new Response(
        JSON.stringify({ error: "Valid duration between 5-60 minutes is required" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        }
      );
    }

    if (!voices || !Array.isArray(voices) || voices.length < 2) {
      return new Response(
        JSON.stringify({ error: "At least 2 voices are required" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        }
      );
    }

    // Calculate target character count based on duration
    const targetCharCount = duration * CHARS_PER_MINUTE;

    // Create a new podcast entry in the database
    const { data: podcast, error: podcastError } = await supabaseAdmin
      .from("premium_podcasts")
      .insert({
        title: `${duration}-minute Podcast on ${topic}`,
        description: "A premium podcast featuring multiple speakers discussing this topic.",
        topic: topic,
        status: "generating",
        duration: duration,
        character_count: targetCharCount,
      })
      .select()
      .single();

    if (podcastError) {
      console.error("Error creating podcast entry:", podcastError);
      return new Response(
        JSON.stringify({ error: "Failed to create podcast entry" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 500,
        }
      );
    }

    // If this is just the initial request, return the podcast entry
    // The actual generation will happen asynchronously
    if (initialRequest) {
      return new Response(
        JSON.stringify(podcast),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        }
      );
    }

    // Start the actual generation process asynchronously
    // This would typically be handled by a background worker or queue
    // For this implementation, we'll simulate it with a Promise
    generatePodcastContent(podcast.id, topic, duration, voices, targetCharCount);

    return new Response(
      JSON.stringify(podcast),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Error processing request:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});

// Function to generate podcast content asynchronously
async function generatePodcastContent(
  podcastId: string,
  topic: string,
  duration: number,
  voices: string[],
  targetCharCount: number
) {
  try {
    // Step 1: Generate the podcast script with multiple speakers
    const script = await generatePodcastScript(topic, duration, voices, targetCharCount);
    
    // Step 2: Generate audio for each speaker part and combine them
    const audioUrl = await generateAndUploadAudio(script, voices, podcastId);
    
    // Step 3: Update the podcast entry with the audio URL and set status to ready
    const { error: updateError } = await supabaseAdmin
      .from("premium_podcasts")
      .update({
        audio_url: audioUrl,
        status: "ready",
      })
      .eq("id", podcastId);
    
    if (updateError) {
      console.error("Error updating podcast entry:", updateError);
      throw updateError;
    }
  } catch (error) {
    console.error("Error generating podcast content:", error);
    
    // Update the podcast entry with failed status
    await supabaseAdmin
      .from("premium_podcasts")
      .update({
        status: "failed",
      })
      .eq("id", podcastId);
  }
}

// Function to generate a podcast script with multiple speakers
async function generatePodcastScript(
  topic: string,
  duration: number,
  voices: string[],
  targetCharCount: number
): Promise<{ [key: string]: string[] }> {
  // Create a prompt for OpenAI to generate a conversation between multiple speakers
  const prompt = `
    Create a Christian podcast script on the topic of "${topic}" that's approximately ${duration} minutes long when read aloud.
    
    The podcast should be a conversation between ${voices.length} speakers named ${voices.join(", ")}.
    
    Format the script as a JSON object with speaker names as keys and arrays of their dialogue lines as values.
    Each speaker should have roughly equal speaking time.
    
    The total character count should be approximately ${targetCharCount} characters.
    
    Make the conversation natural, engaging, and informative. Include biblical references and spiritual insights.
    Start with an introduction and end with a conclusion.
  `;
  
  // Call OpenAI API to generate the script
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${openaiApiKey}`,
    },
    body: JSON.stringify({
      model: "gpt-4-turbo",
      messages: [
        {
          role: "system",
          content: "You are a Christian podcast scriptwriter who creates engaging, multi-speaker conversations on spiritual topics."
        },
        {
          role: "user",
          content: prompt
        }
      ],
      temperature: 0.7,
      max_tokens: 4000,
    }),
  });
  
  const data = await response.json();
  
  if (!data.choices || !data.choices[0] || !data.choices[0].message) {
    throw new Error("Failed to generate podcast script");
  }
  
  // Extract the script from the response
  const scriptText = data.choices[0].message.content;
  
  // Parse the JSON script
  // The script might be wrapped in ```json ``` markdown code blocks
  const jsonMatch = scriptText.match(/```json\n([\s\S]*?)\n```/) || 
                    scriptText.match(/```\n([\s\S]*?)\n```/) ||
                    [null, scriptText];
  
  const cleanedScript = jsonMatch[1] || scriptText;
  
  try {
    return JSON.parse(cleanedScript);
  } catch (error) {
    console.error("Error parsing script JSON:", error);
    console.log("Raw script:", scriptText);
    
    // If parsing fails, create a simple script structure
    const fallbackScript: { [key: string]: string[] } = {};
    voices.forEach(voice => {
      fallbackScript[voice] = ["I'm sorry, but there was an error generating the podcast script."];
    });
    
    return fallbackScript;
  }
}

// Function to generate audio for each speaker and combine them
async function generateAndUploadAudio(
  script: { [key: string]: string[] },
  voices: string[],
  podcastId: string
): Promise<string> {
  // Create an array to hold all audio segments
  const audioSegments: Uint8Array[] = [];
  
  // Process each speaker's lines
  for (const [speaker, lines] of Object.entries(script)) {
    // Find the corresponding OpenAI voice
    const voiceId = voices.includes(speaker.toLowerCase()) ? 
                    speaker.toLowerCase() : 
                    voices[Math.floor(Math.random() * voices.length)];
    
    // Join the speaker's lines with a pause between them
    const speakerText = lines.join("\n\n");
    
    // Generate audio for this speaker's lines
    const audioData = await generateSpeakerAudio(speakerText, voiceId);
    
    // Add to segments
    audioSegments.push(audioData);
  }
  
  // Combine all audio segments (in a real implementation, you would use proper audio processing)
  // For this example, we'll just concatenate the binary data
  const combinedAudio = concatenateAudioSegments(audioSegments);
  
  // Upload the combined audio to Supabase Storage
  const audioPath = `podcasts/${podcastId}.mp3`;
  
  const { error: uploadError } = await supabaseAdmin
    .storage
    .from("audio")
    .upload(audioPath, combinedAudio, {
      contentType: "audio/mpeg",
      cacheControl: "3600",
    });
  
  if (uploadError) {
    console.error("Error uploading audio:", uploadError);
    throw uploadError;
  }
  
  // Get the public URL for the uploaded audio
  const { data: publicUrlData } = supabaseAdmin
    .storage
    .from("audio")
    .getPublicUrl(audioPath);
  
  return publicUrlData.publicUrl;
}

// Function to generate audio for a single speaker
async function generateSpeakerAudio(text: string, voice: string): Promise<Uint8Array> {
  // Call OpenAI TTS API to generate audio
  const response = await fetch("https://api.openai.com/v1/audio/speech", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${openaiApiKey}`,
    },
    body: JSON.stringify({
      model: "tts-1",
      voice: voice,
      input: text,
    }),
  });
  
  if (!response.ok) {
    const errorData = await response.json();
    console.error("Error generating audio:", errorData);
    throw new Error(`Failed to generate audio: ${response.statusText}`);
  }
  
  // Get the audio data as an ArrayBuffer
  const arrayBuffer = await response.arrayBuffer();
  
  // Convert to Uint8Array
  return new Uint8Array(arrayBuffer);
}

// Function to concatenate audio segments
// In a real implementation, you would use proper audio processing libraries
function concatenateAudioSegments(segments: Uint8Array[]): Uint8Array {
  // Calculate the total length
  const totalLength = segments.reduce((sum, segment) => sum + segment.length, 0);
  
  // Create a new array to hold all the data
  const result = new Uint8Array(totalLength);
  
  // Copy each segment into the result array
  let offset = 0;
  for (const segment of segments) {
    result.set(segment, offset);
    offset += segment.length;
  }
  
  return result;
} 