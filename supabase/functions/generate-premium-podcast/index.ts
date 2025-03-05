// Deno-specific imports - these will work in the Supabase Edge Functions environment
// but may show as errors in local development environments
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { corsHeaders } from '../_shared/cors.ts'

// Use OpenAI API for generation, similar to the free version
// Deno.env is available in the Supabase Edge Functions environment
const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')
const supabaseUrl = Deno.env.get('API_SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('API_SUPABASE_KEY')

// Bible verses database for scripture references
const commonVerses = {
  "faith": ["Hebrews 11:1", "Romans 10:17", "2 Corinthians 5:7"],
  "hope": ["Romans 15:13", "Hebrews 6:19", "Romans 8:24-25"],
  "love": ["1 Corinthians 13:4-7", "John 3:16", "1 John 4:7-8"],
  "peace": ["John 14:27", "Philippians 4:6-7", "Isaiah 26:3"],
  "joy": ["James 1:2-3", "Psalm 16:11", "Romans 15:13"],
  "wisdom": ["James 1:5", "Proverbs 1:7", "Proverbs 3:13-18"],
  "forgiveness": ["Ephesians 4:32", "Colossians 3:13", "Matthew 6:14-15"],
  "prayer": ["Philippians 4:6-7", "1 Thessalonians 5:17", "James 5:16"],
  "gratitude": ["1 Thessalonians 5:18", "Psalm 100:4", "Colossians 3:15-17"],
  "purpose": ["Jeremiah 29:11", "Romans 8:28", "Ephesians 2:10"]
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { topic, duration, scriptureReferences, isPremium, contentType = 'bible_study' } = await req.json()

    // Validate premium status
    if (!isPremium) {
      return new Response(
        JSON.stringify({ error: 'Premium subscription required for advanced podcast generation' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
      )
    }

    // Validate required fields
    if (!topic) {
      return new Response(
        JSON.stringify({ error: 'Topic is required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    // Get scripture references if not provided
    const scriptures = scriptureReferences || 
      (commonVerses[topic.toLowerCase()] ? 
        commonVerses[topic.toLowerCase()].join(", ") : 
        "");

    // In development mode or if no API key, return mock data
    if (!OPENAI_API_KEY) {
      console.log('No OpenAI API key found, returning mock data')
      return new Response(
        JSON.stringify(generateMockPodcast(topic, scriptures, duration, contentType)),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Adjust prompts based on content type
    const isLongForm = contentType === 'longform_podcast';
    const contentTypeLabel = isLongForm ? 'podcast' : 'Bible study';
    
    // Generate the complete script using OpenAI
    const script = await generateScript(topic, scriptures, isLongForm, contentTypeLabel, duration);
    
    // Generate metadata (title, description) from the script
    const metadata = await generateMetadata(script, topic);
    
    // Generate audio from the script
    const audioBuffer = await generateAudio(script);
    
    // Return the response
    return new Response(
      JSON.stringify({
        title: metadata.title,
        content: script,
        duration: duration || 15
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
    
  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'An error occurred during podcast generation' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})

// Generate script using OpenAI
async function generateScript(topic, scriptureReferences, isLongForm, contentTypeLabel, duration) {
  console.log('Generating premium podcast script...');
  
  // Prepare the content prompt based on whether scripture references are provided
  let contentPrompt = `Create a premium ${contentTypeLabel} script about ${topic}.`;
  if (scriptureReferences && scriptureReferences.trim() !== '') {
    contentPrompt = `Create a premium ${contentTypeLabel} script about ${topic} with a focus on ${scriptureReferences}.`;
  }
  
  if (isLongForm) {
    contentPrompt += ` This should be a longer, more in-depth ${contentTypeLabel} of approximately ${duration || 15} minutes when spoken.`;
  } else {
    contentPrompt += ` This should be a concise ${contentTypeLabel} of approximately ${duration || 15} minutes when spoken.`;
  }
  
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: `You are a knowledgeable Bible study podcast host. Create an engaging and insightful discussion about the specified topic. Include:
            1. A warm welcome and introduction
            2. Historical and biblical context
            3. Key verses and their meaning
            4. Theological insights
            5. Life applications
            6. Reflection questions
            ${isLongForm ? 'This is a premium long-form podcast, so provide more depth, examples, and theological insights than a standard Bible study.' : 'This is a premium Bible study, so provide more depth and theological insights than a standard Bible study.'}
            ${isLongForm ? `Structure the content for a ${duration || 15}-minute podcast.` : `Keep the content around ${duration || 15} minutes when spoken.`}`
        },
        {
          role: 'user',
          content: contentPrompt
        }
      ],
      temperature: 0.7
    })
  });
  
  if (!response.ok) {
    const errorBody = await response.text();
    console.error('OpenAI script generation error:', errorBody);
    throw new Error(`Failed to generate script: ${response.status} ${response.statusText}`);
  }
  
  const data = await response.json();
  return data.choices[0].message.content;
}

// Generate metadata using OpenAI
async function generateMetadata(script, topic) {
  console.log('Generating metadata...');
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: 'Extract a concise title and brief description from the provided podcast script. Return only a JSON object with "title" and "description" fields.'
        },
        {
          role: 'user',
          content: `Generate a title and description for this Bible study about ${topic}: ${script.substring(0, 1000)}...`
        }
      ],
      temperature: 0.3
    })
  });
  
  if (!response.ok) {
    const errorBody = await response.text();
    console.error('OpenAI metadata generation error:', errorBody);
    throw new Error(`Failed to generate metadata: ${response.status} ${response.statusText}`);
  }
  
  const data = await response.json();
  let metadata;
  try {
    metadata = JSON.parse(data.choices[0].message.content);
  } catch (error) {
    const jsonMatch = data.choices[0].message.content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      metadata = JSON.parse(jsonMatch[0]);
    } else {
      // Fallback if parsing fails
      metadata = {
        title: `Premium Bible Study: ${topic}`,
        description: `A premium Bible study exploring ${topic} from a Christian perspective.`
      };
    }
  }
  return metadata;
}

// Generate audio using OpenAI
async function generateAudio(script) {
  console.log('Generating audio...');
  const response = await fetch('https://api.openai.com/v1/audio/speech', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'tts-1-hd',  // Using the HD model for premium quality
      voice: 'onyx',
      input: script
    })
  });
  
  if (!response.ok) {
    const errorBody = await response.text();
    console.error('OpenAI audio generation error:', errorBody);
    throw new Error(`Failed to generate audio: ${response.status} ${response.statusText}`);
  }
  
  return response.arrayBuffer();
}

// Mock podcast generator for development/testing
function generateMockPodcast(topic, scriptureReferences, duration = 15, contentType = 'bible_study') {
  const isLongForm = contentType === 'longform_podcast';
  const podcastDuration = duration || (isLongForm ? 15 : 5);
  const title = isLongForm ? 
    `The Christian Journey: ${topic}` : 
    `Premium Bible Study: ${topic}`;
  
  let content = `# Introduction (${Math.floor(podcastDuration * 0.2)} minutes)\n\nWelcome to "${isLongForm ? 'The Christian Journey' : 'Premium Bible Study'}," where we explore faith in everyday life. I'm your host, and today we're diving into the topic of ${topic}. `
  
  if (scriptureReferences) {
    content += `We'll be reflecting on ${scriptureReferences} and how these scriptures guide us in our understanding of ${topic}.\n\n`
  } else {
    content += `We'll be exploring what the Bible teaches us about ${topic} and how we can apply these teachings in our daily lives.\n\n`
  }
  
  content += `# Main Content (${Math.floor(podcastDuration * 0.6)} minutes)\n\n`
  content += `## Understanding ${topic} from a Biblical Perspective\n\n`
  content += `When we think about ${topic} in the context of our faith, we must consider how God views this aspect of our lives. `
  content += `The Bible provides us with guidance through various passages and stories that illuminate God's perspective on ${topic}.\n\n`
  
  if (scriptureReferences) {
    content += `Looking at ${scriptureReferences}, we can see that God values ${topic} as an essential part of our spiritual growth. `
    content += `These verses remind us that our approach to ${topic} should be aligned with God's will and purpose for our lives.\n\n`
  } else {
    content += `Throughout scripture, we see examples of how God values ${topic} as an essential part of our spiritual growth. `
    content += `The Bible reminds us that our approach to ${topic} should be aligned with God's will and purpose for our lives.\n\n`
  }
  
  content += `## Practical Application\n\n`
  content += `How can we apply these biblical principles about ${topic} in our daily lives? First, we need to pray for guidance and wisdom. `
  content += `Second, we should seek community and accountability with other believers. And third, we must be intentional about aligning our actions with our faith.\n\n`
  
  content += `## Challenges and Growth\n\n`
  content += `Of course, living out our faith in the area of ${topic} isn't always easy. We face challenges from cultural pressures, our own weaknesses, and spiritual warfare. `
  content += `But these challenges are opportunities for growth and deeper reliance on God's strength rather than our own.\n\n`
  
  content += `# Conclusion (${Math.floor(podcastDuration * 0.2)} minutes)\n\n`
  content += `As we conclude our discussion on ${topic}, I encourage you to reflect on how God is calling you to grow in this area. `
  content += `Remember that spiritual growth is a journey, not a destination. Each step we take in faith brings us closer to becoming who God created us to be.\n\n`
  content += `Thank you for joining me today on "${isLongForm ? 'The Christian Journey' : 'Premium Bible Study'}." Until next time, may God bless you and keep you in His perfect peace.`
  
  return {
    title,
    content,
    duration: podcastDuration
  }
} 