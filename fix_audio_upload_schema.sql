-- ==========================================
-- FIX AUDIO UPLOAD SCHEMA & PERMISSIONS
-- ==========================================

-- 1. FIX PRAYER NAME CONSTRAINT
-- The previous constraint didn't include Taraweeh 1-4, Shaf, Witr
ALTER TABLE public.recordings DROP CONSTRAINT IF EXISTS recordings_prayer_name_check;

ALTER TABLE public.recordings ADD CONSTRAINT recordings_prayer_name_check 
  CHECK (prayer_name IN (
    'Fajr', 
    'Maghrib', 
    'Isha', 
    'Taraweeh 1', 
    'Taraweeh 2', 
    'Taraweeh 3', 
    'Taraweeh 4', 
    'Shaf', 
    'Witr'
  ));

-- 2. FIX RLS FOR RECORDINGS
-- Allow connected admins to insert recordings
CREATE POLICY "Admins can insert recordings for their mosque" 
  ON public.recordings FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.mosques 
      WHERE id = recordings.mosque_id 
      AND admin_id = auth.uid()
    )
  );

-- 3. STORAGE SETUP (Try this part, but if it fails, please create bucket manually)
-- Attempt to insert the bucket configuration directly
INSERT INTO storage.buckets (id, name, public)
VALUES ('audio-recordings', 'audio-recordings', true)
ON CONFLICT (id) DO NOTHING;

-- Policy: Public read access
CREATE POLICY "Public Audio Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'audio-recordings' );

-- Policy: Authenticated upload access
CREATE POLICY "Authenticated users can upload audio"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'audio-recordings' 
  AND auth.role() = 'authenticated'
);

-- Policy: Owner update/delete
CREATE POLICY "Users can update own audio"
ON storage.objects FOR UPDATE
USING ( bucket_id = 'audio-recordings' AND auth.uid() = owner );

CREATE POLICY "Users can delete own audio"
ON storage.objects FOR DELETE
USING ( bucket_id = 'audio-recordings' AND auth.uid() = owner );
