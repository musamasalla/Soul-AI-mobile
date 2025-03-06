# Premium Podcast Feature

## Overview

The Premium Podcast feature allows subscribers to generate long-form podcasts (5-60 minutes) featuring multiple AI voices discussing Christian topics. This feature uses OpenAI's GPT-4 for content generation and OpenAI's TTS (Text-to-Speech) for voice synthesis.

## Key Features

- Generate podcasts on various Christian topics
- Select podcast duration (5, 10, 15, 30, 45, or 60 minutes)
- Choose from multiple AI voices for a conversational experience
- Character usage tracking with monthly limits
- Asynchronous generation with status updates

## Technical Implementation

### Character Limits

- Each premium user is limited to 45,000 characters per month
- 45,000 characters equates to approximately 60 minutes of audio
- 750 characters = 1 minute of audio

### Components

1. **Models**:
   - `PremiumPodcast.swift`: Data model for premium podcasts
   - `CharacterUsage.swift`: Tracks user's character usage
   - `PodcastVoice.swift`: Enum for available OpenAI voices

2. **ViewModels**:
   - `PremiumPodcastViewModel.swift`: Manages podcast generation and playback

3. **Views**:
   - `PremiumPodcastView.swift`: UI for generating and listing podcasts

4. **Backend**:
   - `generate-premium-podcast`: Supabase Edge Function for podcast generation
   - `premium_podcasts` table in Supabase database

### Generation Process

1. User selects topic, duration, and voices
2. App checks if user has enough characters remaining
3. Initial request creates a podcast entry with "generating" status
4. Backend asynchronously:
   - Generates a multi-speaker script using GPT-4
   - Converts each speaker's lines to audio using OpenAI TTS
   - Combines audio segments
   - Uploads to Supabase Storage
   - Updates podcast entry with audio URL and "ready" status
5. App polls for status updates and displays the podcast when ready

## Voice Options

The following OpenAI TTS voices are available:
- Alloy (Female)
- Echo (Male)
- Fable (Male)
- Onyx (Male)
- Nova (Female)
- Shimmer (Female)

## Database Schema

```sql
CREATE TABLE premium_podcasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  topic TEXT NOT NULL,
  audio_url TEXT,
  status TEXT NOT NULL DEFAULT 'generating',
  duration INTEGER NOT NULL,
  character_count INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE
);
```

## API Endpoints

### Generate Premium Podcast
- **URL**: `/functions/v1/generate-premium-podcast`
- **Method**: POST
- **Request Body**:
  ```json
  {
    "topic": "Faith and Spirituality",
    "duration": 15,
    "voices": ["alloy", "echo"],
    "initialRequest": true
  }
  ```
- **Response**: PremiumPodcast object

### Fetch Premium Podcasts
- **URL**: `/rest/v1/premium_podcasts?select=*&order=created_at.desc`
- **Method**: GET
- **Response**: Array of PremiumPodcast objects

## Future Improvements

- Add ability to download podcasts for offline listening
- Implement more sophisticated audio processing for smoother transitions
- Add background music options
- Allow users to specify custom topics beyond the predefined list
- Implement sharing functionality for podcasts 