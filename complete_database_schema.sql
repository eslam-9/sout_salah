-- ============================================
-- COMPLETE DATABASE SCHEMA FOR SOUT SALAH
-- ============================================
-- Run this script in Supabase SQL Editor after deleting all tables
-- This will create all tables, policies, and triggers needed for the app

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. PROFILES TABLE (extends auth.users)
-- ============================================
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  role TEXT DEFAULT 'listener' CHECK (role IN ('super_admin', 'mosque_admin', 'publisher', 'listener')),
  mosque_id UUID, -- For admins/publishers linked to a specific mosque
  username TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Public profiles are viewable by everyone" 
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
  admin_id UUID REFERENCES public.profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.mosques ENABLE ROW LEVEL SECURITY;

-- RLS Policies for mosques
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
-- 3. RAMADAN DAYS TABLE
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

-- Enable RLS
ALTER TABLE public.ramadan_days ENABLE ROW LEVEL SECURITY;

-- RLS Policies for ramadan_days
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
-- 4. RECORDINGS TABLE
-- ============================================
CREATE TABLE public.recordings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  mosque_id UUID REFERENCES public.mosques(id) ON DELETE CASCADE NOT NULL,
  day_id UUID REFERENCES public.ramadan_days(id) ON DELETE CASCADE NOT NULL,
  publisher_id UUID REFERENCES public.profiles(id),
  prayer_name TEXT NOT NULL CHECK (prayer_name IN ('Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha', 'Taraweeh', 'Tahajjud')),
  sheikh_name TEXT,
  audio_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.recordings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for recordings
CREATE POLICY "Recordings are viewable by everyone" 
  ON public.recordings FOR SELECT 
  USING (true);

CREATE POLICY "Publishers can insert recordings for their mosque" 
  ON public.recordings FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() 
      AND mosque_id = recordings.mosque_id
    )
  );

CREATE POLICY "Publishers can delete their own recordings" 
  ON public.recordings FOR DELETE 
  USING (publisher_id = auth.uid());

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
-- 5. TRIGGERS
-- ============================================

-- Drop existing triggers and functions if they exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_mosque_created ON public.mosques;
DROP TRIGGER IF EXISTS before_mosque_insert ON public.mosques;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_mosque() CASCADE;
DROP FUNCTION IF EXISTS public.set_mosque_admin() CASCADE;

-- Trigger: Auto-create profile when user signs up
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

-- Trigger: Auto-create 30 Ramadan days when a mosque is created
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

-- Trigger: Set admin_id automatically when creating a mosque
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
-- SETUP COMPLETE
-- ============================================
-- Your database is now ready!
-- All tables, policies, and triggers have been created.
