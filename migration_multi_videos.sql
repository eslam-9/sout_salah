-- STEP 1: Drop the unique constraint to allow multiple videos per day
ALTER TABLE public.daily_videos
DROP CONSTRAINT daily_videos_mosque_id_day_id_key;

-- STEP 2: Add optional title column to each video
ALTER TABLE public.daily_videos
ADD COLUMN title text;
