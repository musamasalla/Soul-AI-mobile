-- Create premium_podcasts table
CREATE TABLE IF NOT EXISTS premium_podcasts (
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

-- Add RLS policies
ALTER TABLE premium_podcasts ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read premium_podcasts
CREATE POLICY "Allow anyone to read premium_podcasts"
  ON premium_podcasts
  FOR SELECT
  USING (true);

-- Allow authenticated users to insert premium_podcasts
CREATE POLICY "Allow authenticated users to insert premium_podcasts"
  ON premium_podcasts
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow service role to update premium_podcasts
CREATE POLICY "Allow service role to update premium_podcasts"
  ON premium_podcasts
  FOR UPDATE
  USING (true);

-- Create trigger to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_premium_podcasts_updated_at
BEFORE UPDATE ON premium_podcasts
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column(); 