-- Drop the check constraint on prayer_name to allow custom prayer names
ALTER TABLE public.recordings DROP CONSTRAINT IF EXISTS recordings_prayer_name_check;
