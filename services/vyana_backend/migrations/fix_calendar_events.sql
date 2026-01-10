-- Run this SQL in your Supabase SQL Editor to fix the calendar_events table

-- Add missing end_time column if it doesn't exist
ALTER TABLE IF EXISTS calendar_events 
ADD COLUMN IF NOT EXISTS end_time TIMESTAMPTZ;

-- If the table doesn't exist at all, create it:
CREATE TABLE IF NOT EXISTS calendar_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    summary TEXT NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS (Row Level Security)
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

-- Create policy to allow authenticated users to manage their own events
CREATE POLICY IF NOT EXISTS "Users can manage own events" ON calendar_events
    FOR ALL
    USING (auth.uid() = user_id);

-- For service_role access (backend), allow all
CREATE POLICY IF NOT EXISTS "Service role full access" ON calendar_events
    FOR ALL
    USING (auth.role() = 'service_role');
