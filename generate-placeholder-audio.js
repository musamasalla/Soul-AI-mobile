// Script to generate a placeholder audio file using OpenAI's text-to-speech API
const fs = require('fs');
const https = require('https');
const path = require('path');

// Replace with your OpenAI API key
const OPENAI_API_KEY = 'YOUR_OPENAI_API_KEY';

// The text to convert to speech
const text = 'Your podcast is being generated. Please check back in a few minutes.';

// Function to generate audio using OpenAI API
async function generateAudio() {
  return new Promise((resolve, reject) => {
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

// Run the function
generateAudio()
  .then(filePath => {
    console.log('Success! Now you can upload this file to Supabase.');
    console.log(`File path: ${filePath}`);
  })
  .catch(error => {
    console.error('Error:', error.message);
  }); 