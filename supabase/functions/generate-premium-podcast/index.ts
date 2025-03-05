import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { corsHeaders } from '../_shared/cors.ts'

const NOTEBOOKLM_API_KEY = Deno.env.get('NOTEBOOKLM_API_KEY')
const NOTEBOOKLM_API_URL = 'https://notebooklm.googleapis.com/v1/models/notebooklm:generateContent'
const supabaseUrl = Deno.env.get('API_SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('API_SUPABASE_KEY')

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

    // Build the prompt for NotebookLM
    let prompt = `Create a Christian podcast script on the topic of "${topic}". `
    
    if (scriptureReferences) {
      prompt += `Include references to these scriptures: ${scriptureReferences}. `
    }
    
    prompt += `The podcast should be appropriate for a ${duration || 15}-minute episode. `
    prompt += `Format the response with a title, introduction, main content with sections, and conclusion. `
    prompt += `The content should be spiritually enriching, conversational in tone, and include thought-provoking questions and insights.`

    // In development mode, return mock data
    if (!NOTEBOOKLM_API_KEY) {
      console.log('No NotebookLM API key found, returning mock data')
      return new Response(
        JSON.stringify(generateMockPodcast(topic, scriptureReferences, duration)),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Call NotebookLM API
    const response = await fetch(NOTEBOOKLM_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${NOTEBOOKLM_API_KEY}`
      },
      body: JSON.stringify({
        contents: [
          {
            role: 'user',
            parts: [{ text: prompt }]
          }
        ],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 4096,
        }
      })
    })

    if (!response.ok) {
      const errorData = await response.text()
      console.error('NotebookLM API error:', errorData)
      throw new Error(`NotebookLM API error: ${response.status}`)
    }

    const data = await response.json()
    const content = data.candidates[0].content.parts[0].text

    // Extract title and content
    const titleMatch = content.match(/^#*\s*(.*?)(?:\n|$)/)
    const title = titleMatch ? titleMatch[1].replace(/[#*]/g, '').trim() : 'Christian Podcast'
    
    // Remove the title from the content
    const podcastContent = content.replace(/^#*\s*(.*?)(?:\n|$)/, '').trim()

    return new Response(
      JSON.stringify({
        title,
        content: podcastContent,
        duration: duration || 15
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
  
  let content = `# Introduction (2 minutes)\n\nWelcome to "The Christian Journey," where we explore faith in everyday life. I'm your host, and today we're diving into the topic of ${topic}. `
  
  if (scriptureReferences) {
    content += `We'll be reflecting on ${scriptureReferences} and how these scriptures guide us in our understanding of ${topic}.\n\n`
  } else {
    content += `We'll be exploring what the Bible teaches us about ${topic} and how we can apply these teachings in our daily lives.\n\n`
  }
  
  content += `# Main Content (${Math.floor(podcastDuration * 0.7)} minutes)\n\n`
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