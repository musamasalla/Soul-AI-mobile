import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { corsHeaders } from '../_shared/cors.ts'

// Use Claude API for more cost-effective generation
const CLAUDE_API_KEY = Deno.env.get('CLAUDE_API_KEY')
const CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages'
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
    const { topic, duration, scriptureReferences, isPremium } = await req.json()

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
    if (!CLAUDE_API_KEY) {
      console.log('No Claude API key found, returning mock data')
      return new Response(
        JSON.stringify(generateMockPodcast(topic, scriptures, duration)),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate podcast using a hybrid approach
    // 1. Use a template for structure
    // 2. Use Claude API for specific content sections
    
    // First, generate the introduction using Claude
    const introPrompt = `Write a brief introduction (2-3 paragraphs) for a Christian podcast about ${topic}.
    If relevant, reference these scriptures: ${scriptures}.
    The introduction should be warm, inviting, and set up the topic in a way that engages Christian listeners.
    Keep it concise but impactful.`;
    
    const introResponse = await fetch(CLAUDE_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': CLAUDE_API_KEY,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: "claude-instant-1.2",
        max_tokens: 500,
        messages: [
          { role: "user", content: introPrompt }
        ]
      })
    });

    if (!introResponse.ok) {
      throw new Error(`Claude API error: ${introResponse.status}`);
    }

    const introData = await introResponse.json();
    const introduction = introData.content[0].text;

    // Next, generate the main content sections using Claude
    const mainContentPrompt = `Create 3 main sections for a Christian podcast about ${topic}.
    If relevant, incorporate these scriptures: ${scriptures}.
    For each section:
    1. Provide a clear subheading
    2. Write 2-3 paragraphs of content
    3. Include at least one practical application point
    
    Format with markdown headings (##) for each section.
    The content should be spiritually enriching and biblically sound.`;
    
    const mainContentResponse = await fetch(CLAUDE_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': CLAUDE_API_KEY,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: "claude-instant-1.2",
        max_tokens: 1500,
        messages: [
          { role: "user", content: mainContentPrompt }
        ]
      })
    });

    if (!mainContentResponse.ok) {
      throw new Error(`Claude API error: ${mainContentResponse.status}`);
    }

    const mainContentData = await mainContentResponse.json();
    const mainContent = mainContentData.content[0].text;

    // Finally, generate the conclusion using Claude
    const conclusionPrompt = `Write a conclusion (1-2 paragraphs) for a Christian podcast about ${topic}.
    If relevant, reference these scriptures: ${scriptures}.
    The conclusion should summarize key points, offer a final encouragement, and include a brief prayer or blessing.
    Keep it concise but meaningful.`;
    
    const conclusionResponse = await fetch(CLAUDE_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': CLAUDE_API_KEY,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: "claude-instant-1.2",
        max_tokens: 500,
        messages: [
          { role: "user", content: conclusionPrompt }
        ]
      })
    });

    if (!conclusionResponse.ok) {
      throw new Error(`Claude API error: ${conclusionResponse.status}`);
    }

    const conclusionData = await conclusionResponse.json();
    const conclusion = conclusionData.content[0].text;

    // Assemble the complete podcast content
    const title = `The Christian Journey: ${topic}`;
    const podcastDuration = duration || 15;
    
    const content = `# Introduction (${Math.floor(podcastDuration * 0.2)} minutes)\n\n${introduction}\n\n` +
                   `# Main Content (${Math.floor(podcastDuration * 0.6)} minutes)\n\n${mainContent}\n\n` +
                   `# Conclusion (${Math.floor(podcastDuration * 0.2)} minutes)\n\n${conclusion}`;

    return new Response(
      JSON.stringify({
        title,
        content,
        duration: podcastDuration
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})

// Function to generate mock podcast data for development
function generateMockPodcast(topic: string, scriptureReferences?: string, duration?: number) {
  const podcastDuration = duration || 15
  const title = `The Christian Journey: ${topic}`
  
  let content = `# Introduction (${Math.floor(podcastDuration * 0.2)} minutes)\n\nWelcome to "The Christian Journey," where we explore faith in everyday life. I'm your host, and today we're diving into the topic of ${topic}. `
  
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
  content += `Thank you for joining me today on "The Christian Journey." Until next time, may God bless you and keep you in His perfect peace.`
  
  return {
    title,
    content,
    duration: podcastDuration
  }
} 