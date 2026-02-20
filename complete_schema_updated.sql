-- ============================================
-- UPDATED DATABASE SCHEMA FOR SOUT SALAH
-- ============================================
-- This includes all role-based permissions and the 9-prayer structure
-- Run this in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- CLEAN UP (Drop existing if re-running)
-- ============================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_mosque_created ON public.mosques;
DROP TRIGGER IF EXISTS before_mosque_insert ON public.mosques;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_mosque() CASCADE;
DROP FUNCTION IF EXISTS public.set_mosque_admin() CASCADE;

DROP TABLE IF EXISTS public.recordings CASCADE;
DROP TABLE IF EXISTS public.mosque_publishers CASCADE;
DROP TABLE IF EXISTS public.ramadan_days CASCADE;
DROP TABLE IF EXISTS public.mosques CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- ============================================
-- 1. PROFILES TABLE
-- ============================================
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  username TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are viewable by everyone" 
  ON public.profiles FOR SELECT 
  USING (true);

CREATE POLICY "Users can insert their own profile" 
  ON public.profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = id);

-- ============================================
-- 2. MOSQUES TABLE
-- ============================================
CREATE TABLE public.mosques (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  location TEXT,
  admin_id UUID REFERENCES public.profiles(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.mosques ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Mosques are viewable by everyone" 
  ON public.mosques FOR SELECT 
  USING (true);

CREATE POLICY "Authenticated users can create mosques" 
  ON public.mosques FOR INSERT 
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Admins can update their own mosque" 
  ON public.mosques FOR UPDATE 
  USING (admin_id = auth.uid());

CREATE POLICY "Admins can delete their own mosque" 
  ON public.mosques FOR DELETE 
  USING (admin_id = auth.uid());

-- ============================================
-- 3. MOSQUE PUBLISHERS (Junction Table)
-- ============================================
CREATE TABLE public.mosque_publishers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  mosque_id UUID REFERENCES public.mosques(id) ON DELETE CASCADE NOT NULL,
  publisher_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  added_by UUID REFERENCES public.profiles(id) NOT NULL, -- Admin who added them
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(mosque_id, publisher_id)
);

ALTER TABLE public.mosque_publishers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Publishers list is viewable by everyone" 
  ON public.mosque_publishers FOR SELECT 
  USING (true);

CREATE POLICY "Only mosque admins can add publishers" 
  ON public.mosque_publishers FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.mosques 
      WHERE id = mosque_publishers.mosque_id 
      AND admin_id = auth.uid()
    )
  );

CREATE POLICY "Only mosque admins can remove publishers" 
  ON public.mosque_publishers FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.mosques 
      WHERE id = mosque_publishers.mosque_id 
      AND admin_id = auth.uid()
    )
  );

-- ============================================
-- 4. RAMADAN DAYS TABLE
-- ============================================
CREATE TABLE public.ramadan_days (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  mosque_id UUID REFERENCES public.mosques(id) ON DELETE CASCADE NOT NULL,
  day_number INT NOT NULL CHECK (day_number BETWEEN 1 AND 30),
  status TEXT DEFAULT 'red' CHECK (status IN ('red', 'yellow', 'green')),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(mosque_id, day_number)
);

ALTER TABLE public.ramadan_days ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Days are viewable by everyone" 
  ON public.ramadan_days FOR SELECT 
  USING (true);

CREATE POLICY "Mosque admins can update days" 
  ON public.ramadan_days FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.mosques 
      WHERE id = ramadan_days.mosque_id 
      AND admin_id = auth.uid()
    )
  );

-- ============================================
-- 5. RECORDINGS TABLE
-- ============================================
CREATE TABLE public.recordings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  mosque_id UUID REFERENCES public.mosques(id) ON DELETE CASCADE NOT NULL,
  day_id UUID REFERENCES public.ramadan_days(id) ON DELETE CASCADE NOT NULL,
  publisher_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  prayer_name TEXT NOT NULL CHECK (
    prayer_name IN ('Fajr', 'Maghrib', 'Isha', 'Taraweeh 1', 'Taraweeh 2', 'Taraweeh 3', 'Taraweeh 4', 'Shaf', 'Witr')
  ),
  sheikh_name TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  file_size BIGINT, -- in bytes
  duration INT, -- in seconds
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.recordings ENABLE ROW LEVEL SECURITY;

-- Everyone can view/listen
CREATE POLICY "Recordings are viewable by everyone" 
  ON public.recordings FOR SELECT 
  USING (true);

-- Admins and publishers can upload
CREATE POLICY "Admins and publishers can insert recordings" 
  ON public.recordings FOR INSERT 
  WITH CHECK (
    -- User is the admin of this mosque
    EXISTS (
      SELECT 1 FROM public.mosques 
      WHERE id = recordings.mosque_id 
      AND admin_id = auth.uid()
    )
    OR
    -- User is a publisher for this mosque
    EXISTS (
      SELECT 1 FROM public.mosque_publishers 
      WHERE mosque_id = recordings.mosque_id 
      AND publisher_id = auth.uid()
    )
  );

-- Publishers can delete their own recordings
CREATE POLICY "Publishers can delete own recordings" 
  ON public.recordings FOR DELETE 
  USING (publisher_id = auth.uid());

-- Admins can delete any recording in their mosque
CREATE POLICY "Admins can delete any recording in their mosque" 
  ON public.recordings FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.mosques 
      WHERE id = recordings.mosque_id 
      AND admin_id = auth.uid()
    )
  );

-- ============================================
-- 6. INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX idx_mosques_admin ON public.mosques(admin_id);
CREATE INDEX idx_mosque_publishers_mosque ON public.mosque_publishers(mosque_id);
CREATE INDEX idx_mosque_publishers_publisher ON public.mosque_publishers(publisher_id);
CREATE INDEX idx_ramadan_days_mosque ON public.ramadan_days(mosque_id);
CREATE INDEX idx_recordings_mosque ON public.recordings(mosque_id);
CREATE INDEX idx_recordings_day ON public.recordings(day_id);
CREATE INDEX idx_recordings_publisher ON public.recordings(publisher_id);
CREATE INDEX idx_recordings_prayer ON public.recordings(prayer_name);

-- ============================================
-- 7. TRIGGERS
-- ============================================

-- Auto-create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1))
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Auto-create 30 Ramadan days when mosque is created
CREATE OR REPLACE FUNCTION public.handle_new_mosque()
RETURNS TRIGGER AS $$
BEGIN
  FOR i IN 1..30 LOOP
    INSERT INTO public.ramadan_days (mosque_id, day_number)
    VALUES (new.id, i);
  END LOOP;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_mosque_created
  AFTER INSERT ON public.mosques
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_mosque();

-- Auto-set admin_id when creating mosque
CREATE OR REPLACE FUNCTION public.set_mosque_admin()
RETURNS TRIGGER AS $$
BEGIN
  IF new.admin_id IS NULL THEN
    new.admin_id := auth.uid();
  END IF;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER before_mosque_insert
  BEFORE INSERT ON public.mosques
  FOR EACH ROW EXECUTE PROCEDURE public.set_mosque_admin();

-- ============================================
-- 8. HELPER FUNCTIONS
-- ============================================

-- Check if user is admin of a mosque
CREATE OR REPLACE FUNCTION public.is_mosque_admin(mosque_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.mosques 
    WHERE id = mosque_uuid 
    AND admin_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is publisher of a mosque
CREATE OR REPLACE FUNCTION public.is_mosque_publisher(mosque_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.mosque_publishers 
    WHERE mosque_id = mosque_uuid 
    AND publisher_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user can upload to a mosque
CREATE OR REPLACE FUNCTION public.can_upload_to_mosque(mosque_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.is_mosque_admin(mosque_uuid) OR public.is_mosque_publisher(mosque_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SETUP COMPLETE
-- ============================================
-- Database is ready with:
-- ✅ 9-prayer structure
-- ✅ Role-based permissions
-- ✅ Publisher management
-- ✅ Strict RLS policies
-- ✅ Helper functions
