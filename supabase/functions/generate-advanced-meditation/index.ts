// supabase/functions/generate-advanced-meditation/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { corsHeaders } from '../_shared/cors.ts'
import { OpenAI } from 'https://esm.sh/openai@4.0.0'

const openAiKey = Deno.env.get('OPENAI_API_KEY')
const supabaseUrl = Deno.env.get('API_SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('API_SUPABASE_KEY')

const openai = new OpenAI({
  apiKey: openAiKey
})

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { mood, topic, duration, scriptureReference, isPremium } = await req.json()

    // Validate premium status (in a real app, you'd check the user's subscription)
    if (!isPremium) {
      return new Response(
        JSON.stringify({ error: 'Premium subscription required for advanced meditation' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
      )
    }

    // Build the prompt based on the inputs
    let prompt = `Generate a Christian meditation on the topic of "${topic}" for someone who is feeling "${mood}". `
    
    if (scriptureReference) {
      prompt += `Include references to the scripture "${scriptureReference}". `
    }
    
    prompt += `The meditation should be appropriate for a ${duration}-minute guided meditation session. `
    prompt += `Format the response with a title and meditation content. The title should be concise and inspiring. `
    prompt += `The content should be calming, spiritually enriching, and include moments for reflection and breathing.`

    // Call OpenAI API
    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: 'You are a Christian spiritual guide specializing in creating personalized meditations.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.7,
      max_tokens: 1000
    })

    const response = completion.choices[0].message.content

    // Extract title and content
    const titleMatch = response.match(/^#*\s*(.*?)(?:\n|$)/)
    const title = titleMatch ? titleMatch[1].replace(/[#*]/g, '').trim() : 'Christian Meditation'
    
    // Remove the title from the content
    const content = response.replace(/^#*\s*(.*?)(?:\n|$)/, '').trim()

    return new Response(
      JSON.stringify({
        title,
        content,
        duration
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