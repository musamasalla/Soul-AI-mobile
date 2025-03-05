// Script to generate a placeholder audio file using OpenAI's text-to-speech API and upload it to Supabase
const fs = require('fs');
const https = require('https');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

// Replace with your credentials
const OPENAI_API_KEY = 'YOUR_OPENAI_API_KEY';
const SUPABASE_URL = 'https://zihuvecrcuaovdiremzw.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// The text to convert to speech
const text = 'Your podcast is being generated. Please check back in a few minutes.';

// Function to generate audio using OpenAI API
async function generateAudio() {
  return new Promise((resolve, reject) => {
    console.log('Generating audio with OpenAI...');
    
    const options = {
      hostname: 'api.openai.com',
      path: '/v1/audio/speech',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${OPENAI_API_KEY}`
      }
    };

    const req = https.request(options, (res) => {
      if (res.statusCode !== 200) {
        let error = '';
        res.on('data', (chunk) => {
          error += chunk;
        });
        res.on('end', () => {
          reject(new Error(`Failed to generate audio: ${res.statusCode} ${res.statusMessage}\n${error}`));
        });
        return;
      }

      // Create a file to save the audio
      const outputPath = path.join(__dirname, 'generating-placeholder.mp3');
      const fileStream = fs.createWriteStream(outputPath);
      
      res.pipe(fileStream);
      
      fileStream.on('finish', () => {
        fileStream.close();
        console.log(`Audio file saved to: ${outputPath}`);
        resolve(outputPath);
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    // Send the request with the text to convert
    req.write(JSON.stringify({
      model: 'tts-1',
      voice: 'onyx',
      input: text
    }));
    
    req.end();
  });
}

// Function to upload file to Supabase Storage
async function uploadToSupabase(filePath) {
  console.log('Uploading to Supabase...');
  
  try {
    // Read the file
    const fileBuffer = fs.readFileSync(filePath);
    
    // Upload to Supabase Storage
    const { data, error } = await supabase
      .storage
      .from('podcasts')
      .upload('generating-placeholder.mp3', fileBuffer, {
        contentType: 'audio/mpeg',
        upsert: true
      });
    
    if (error) {
      throw new Error(`Failed to upload to Supabase: ${error.message}`);
    }
    
    // Get the public URL
    const { data: { publicUrl } } = supabase
      .storage
      .from('podcasts')
      .getPublicUrl('generating-placeholder.mp3');
    
    console.log('Upload successful!');
    console.log(`Public URL: ${publicUrl}`);
    
    return publicUrl;
  } catch (error) {
    throw error;
  }
}

// Run the process
async function main() {
  try {
    // Generate the audio file
    const filePath = await generateAudio();
    
    // Upload to Supabase
    const publicUrl = await uploadToSupabase(filePath);
    
    console.log('\nProcess completed successfully!');
    console.log('You can now use the placeholder audio file in your app.');
    console.log(`Public URL: ${publicUrl}`);
  } catch (error) {
    console.error('Error:', error.message);
  }
}

main(); 