-- =============================================================================
-- SAWT AL-MASJID (صوت المسجد) — PRODUCTION DATABASE SCHEMA
-- Project: fsddnmdmfrrapbumggsg (Supabase: Sawt Al-Masjid)
-- Generated: 2026-09-04
-- This file is the single source of truth. It reflects the EXACT current schema
-- on Supabase production. Do NOT run this blindly on production — the tables
-- already exist. Use this for documentation, new environment setup, or reference.
-- =============================================================================


-- =============================================================================
-- EXTENSIONS
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; -- provides uuid_generate_v4()


-- =============================================================================
-- TABLE: profiles
-- Stores user profile data, linked 1:1 with auth.users.
-- NOTE: No mosque_id column exists in production (was planned in old drafts).
-- =============================================================================
CREATE TABLE public.profiles (
  id          UUID        NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT,
  username    TEXT,
  role        TEXT,                                          -- 'listener' | 'admin' (super admin)
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);


-- =============================================================================
-- TABLE: mosques
-- Each mosque is owned by an admin. admin_id is NOT NULL in production.
-- =============================================================================
CREATE TABLE public.mosques (
  id          UUID        NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT        NOT NULL,
  description TEXT,
  location    TEXT,
  admin_id    UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE NO ACTION,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

ALTER TABLE public.mosques ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Mosques are viewable by everyone"
  ON public.mosques FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create mosques"
  ON public.mosques FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Admins can update their own mosque"
  ON public.mosques FOR UPDATE USING (admin_id = auth.uid());

CREATE POLICY "Admins can delete their own mosque"
  ON public.mosques FOR DELETE USING (admin_id = auth.uid());


-- =============================================================================
-- TABLE: mosque_publishers
-- Links publishers (users) to a mosque. added_by is NOT NULL in production.
-- =============================================================================
CREATE TABLE public.mosque_publishers (
  id           UUID        NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  mosque_id    UUID        NOT NULL REFERENCES public.mosques(id) ON DELETE CASCADE,
  publisher_id UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  added_by     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE NO ACTION,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (mosque_id, publisher_id)
);

ALTER TABLE public.mosque_publishers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Publishers list is viewable by everyone"
  ON public.mosque_publishers FOR SELECT USING (true);

CREATE POLICY "Only mosque admins can add publishers"
  ON public.mosque_publishers FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.mosques WHERE id = mosque_publishers.mosque_id AND admin_id = auth.uid())
  );

CREATE POLICY "Only mosque admins can remove publishers"
  ON public.mosque_publishers FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM public.mosques WHERE id = mosque_publishers.mosque_id AND admin_id = auth.uid())
  );


-- =============================================================================
-- TABLE: mosque_requests
-- Users request to create a new mosque. Super admins approve or decline.
-- =============================================================================
CREATE TABLE public.mosque_requests (
  id           UUID        NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  name         TEXT        NOT NULL,
  location     TEXT        NOT NULL,
  description  TEXT,
  requested_by UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status       TEXT        NOT NULL DEFAULT 'pending',      -- 'pending' | 'accepted' | 'declined'
  created_at   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

ALTER TABLE public.mosque_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own requests"
  ON public.mosque_requests FOR INSERT WITH CHECK (requested_by = auth.uid());

CREATE POLICY "Users can view their own requests and admins can view all"
  ON public.mosque_requests FOR SELECT
  USING (
    requested_by = auth.uid()
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can update requests"
  ON public.mosque_requests FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));


-- =============================================================================
-- TABLE: ramadan_days
-- One row per day (1-30) per Ramadan month per mosque.
-- NOTE: No 'prayer' or 'is_juz_changed' columns exist in production.
-- =============================================================================
CREATE TABLE public.ramadan_days (
  id          UUID        NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  mosque_id   UUID        NOT NULL REFERENCES public.mosques(id) ON DELETE CASCADE,
  day_number  INTEGER     NOT NULL,
  month       INTEGER     NOT NULL,
  year        INTEGER     NOT NULL,
  status      TEXT                 DEFAULT 'red',           -- 'red' | 'yellow' | 'green'
  active      BOOLEAN              DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (mosque_id, day_number, month, year)
);

ALTER TABLE public.ramadan_days ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Days are viewable by everyone"
  ON public.ramadan_days FOR SELECT USING (true);

CREATE POLICY "Mosque admins/publishers can insert days."
  ON public.ramadan_days FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.mosques
      WHERE id = ramadan_days.mosque_id
        AND (
          admin_id = auth.uid()
          OR EXISTS (SELECT 1 FROM public.mosque_publishers WHERE mosque_id = mosques.id AND publisher_id = auth.uid())
          OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
        )
    )
  );

CREATE POLICY "Mosque admins can update days"
  ON public.ramadan_days FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.mosques WHERE id = ramadan_days.mosque_id AND admin_id = auth.uid()));


-- =============================================================================
-- TABLE: recordings
-- Audio recordings linked to a specific ramadan day.
-- sheikh_name is NOT NULL with no default in production.
-- =============================================================================
CREATE TABLE public.recordings (
  id           UUID        NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  mosque_id    UUID        NOT NULL REFERENCES public.mosques(id) ON DELETE CASCADE,
  day_id       UUID        NOT NULL REFERENCES public.ramadan_days(id) ON DELETE CASCADE,
  publisher_id UUID                 REFERENCES public.profiles(id) ON DELETE SET NULL,
  prayer_name  TEXT        NOT NULL,
  sheikh_name  TEXT        NOT NULL,
  audio_url    TEXT        NOT NULL,
  file_size    BIGINT,
  duration     INTEGER,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

ALTER TABLE public.recordings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Recordings are viewable by everyone"
  ON public.recordings FOR SELECT USING (true);

CREATE POLICY "Admins and publishers can insert recordings"
  ON public.recordings FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.mosques WHERE id = recordings.mosque_id AND admin_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.mosque_publishers WHERE mosque_id = recordings.mosque_id AND publisher_id = auth.uid())
  );

CREATE POLICY "Admins can insert recordings for their mosque"
  ON public.recordings FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM public.mosques WHERE id = recordings.mosque_id AND admin_id = auth.uid()));

CREATE POLICY "Publishers can delete own recordings"
  ON public.recordings FOR DELETE USING (publisher_id = auth.uid());

CREATE POLICY "Admins can delete any recording in their mosque"
  ON public.recordings FOR DELETE
  USING (EXISTS (SELECT 1 FROM public.mosques WHERE id = recordings.mosque_id AND admin_id = auth.uid()));


-- =============================================================================
-- TABLE: day_schedule
-- Prayer schedule for a specific ramadan day at a mosque.
-- WARNING: Column is named 'shikh' (typo) in production — NOT 'sheikh'.
-- =============================================================================
CREATE TABLE public.day_schedule (
  id          UUID        NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  day_id      UUID        NOT NULL REFERENCES public.ramadan_days(id) ON DELETE CASCADE,
  mosque_id   UUID        NOT NULL REFERENCES public.mosques(id) ON DELETE CASCADE,
  salah       TEXT        NOT NULL,
  shikh       TEXT        NOT NULL,  -- ⚠️ TYPO: production column is 'shikh' not 'sheikh'
  comments    TEXT,
  sort_order  INTEGER              DEFAULT 0,
  created_at  TIMESTAMPTZ          DEFAULT now()
);

ALTER TABLE public.day_schedule ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All users can view schedule"
  ON public.day_schedule FOR SELECT USING (true);

CREATE POLICY "Admins and publishers can manage schedule"
  ON public.day_schedule FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    OR EXISTS (SELECT 1 FROM public.mosque_publishers WHERE mosque_id = day_schedule.mosque_id AND publisher_id = auth.uid())
  );


-- =============================================================================
-- TABLE: daily_videos
-- Short daily video content linked to a ramadan day.
-- NOTE: Separate from 'videos' table. Both exist in production.
-- =============================================================================
CREATE TABLE public.daily_videos (
  id           UUID        NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  mosque_id    UUID        NOT NULL REFERENCES public.mosques(id) ON DELETE CASCADE,
  day_id       UUID        NOT NULL REFERENCES public.ramadan_days(id) ON DELETE CASCADE,
  publisher_id UUID                 REFERENCES public.profiles(id) ON DELETE SET NULL,
  video_url    TEXT        NOT NULL,
  title        TEXT,
  description  TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

ALTER TABLE public.daily_videos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Daily videos are viewable by everyone."
  ON public.daily_videos FOR SELECT USING (true);

CREATE POLICY "Mosque admins/publishers can upload daily videos."
  ON public.daily_videos FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.mosques WHERE id = daily_videos.mosque_id
        AND (admin_id = auth.uid()
          OR EXISTS (SELECT 1 FROM public.mosque_publishers WHERE mosque_id = mosques.id AND publisher_id = auth.uid()))
    )
  );

CREATE POLICY "Deployers can update/delete their own videos or admins can"
  ON public.daily_videos FOR ALL
  USING (
    publisher_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.mosques WHERE id = daily_videos.mosque_id AND admin_id = auth.uid())
  );


-- =============================================================================
-- TABLE: videos
-- General mosque videos (not day-specific content).
-- =============================================================================
CREATE TABLE public.videos (
  id            UUID        NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  mosque_id     UUID        NOT NULL REFERENCES public.mosques(id) ON DELETE CASCADE,
  day_id        UUID        NOT NULL REFERENCES public.ramadan_days(id) ON DELETE CASCADE,
  publisher_id  UUID                 REFERENCES public.profiles(id) ON DELETE SET NULL,
  video_url     TEXT        NOT NULL,
  title         TEXT,
  description   TEXT,
  thumbnail_url TEXT,
  duration      INTEGER,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Videos are viewable by everyone"
  ON public.videos FOR SELECT USING (true);

CREATE POLICY "Mosque admins/publishers can upload videos"
  ON public.videos FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.mosques WHERE id = videos.mosque_id
        AND (admin_id = auth.uid()
          OR EXISTS (SELECT 1 FROM public.mosque_publishers WHERE mosque_id = mosques.id AND publisher_id = auth.uid()))
    )
  );

CREATE POLICY "Publishers can delete their own videos"
  ON public.videos FOR DELETE USING (publisher_id = auth.uid());


-- =============================================================================
-- TABLE: fcm_tokens
-- Firebase push notification tokens per user device.
-- =============================================================================
CREATE TABLE public.fcm_tokens (
  id          UUID        NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token       TEXT        NOT NULL,
  platform    TEXT                 DEFAULT 'android',
  created_at  TIMESTAMPTZ          DEFAULT now(),
  updated_at  TIMESTAMPTZ          DEFAULT now(),
  UNIQUE (user_id, token)
);

ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own tokens"
  ON public.fcm_tokens FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert own token"
  ON public.fcm_tokens FOR INSERT WITH CHECK ((auth.uid() = user_id) OR (user_id IS NULL));

CREATE POLICY "Users can update own token"
  ON public.fcm_tokens FOR UPDATE USING ((auth.uid() = user_id) OR (user_id IS NULL));

CREATE POLICY "Users can delete own token"
  ON public.fcm_tokens FOR DELETE USING ((auth.uid() = user_id) OR (user_id IS NULL));


-- =============================================================================
-- TABLE: data
-- Generic key-value info table (app config / links).
-- =============================================================================
CREATE TABLE public.data (
  id    SMALLINT PRIMARY KEY,
  info  TEXT,
  link  TEXT
);

ALTER TABLE public.data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users"
  ON public.data FOR SELECT USING (true);


-- =============================================================================
-- FUNCTIONS & TRIGGERS
-- =============================================================================

-- Auto-create profile on new auth user signup.
-- NOTE: In production, role is NOT auto-set (unlike the old schema.sql draft).
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-set admin_id on mosque insert.
CREATE OR REPLACE FUNCTION public.set_mosque_admin()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.admin_id IS NULL THEN
    NEW.admin_id := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

-- Helper: is current user admin of given mosque?
CREATE OR REPLACE FUNCTION public.is_mosque_admin(mosque_uuid UUID)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.mosques WHERE id = mosque_uuid AND admin_id = auth.uid()
  );
END;
$$;

-- Helper: is current user a publisher in given mosque?
CREATE OR REPLACE FUNCTION public.is_mosque_publisher(mosque_uuid UUID)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.mosque_publishers WHERE mosque_id = mosque_uuid AND publisher_id = auth.uid()
  );
END;
$$;

-- Helper: can current user upload to given mosque?
CREATE OR REPLACE FUNCTION public.can_upload_to_mosque(mosque_uuid UUID)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
  RETURN public.is_mosque_admin(mosque_uuid) OR public.is_mosque_publisher(mosque_uuid);
END;
$$;

-- RPC used by Flutter app to get available (month, year) pairs for a mosque.
CREATE OR REPLACE FUNCTION public.get_available_months(p_mosque_id UUID)
RETURNS TABLE (month INT, year INT) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT r.month, r.year
  FROM public.ramadan_days r
  WHERE r.mosque_id = p_mosque_id;
END;
$$;

-- ⚠️ DEAD FUNCTION: references public.days table which does NOT exist in production.
-- This should be dropped. Listed here only for documentation purposes.
-- CREATE OR REPLACE FUNCTION public.create_mosque_days() ...
