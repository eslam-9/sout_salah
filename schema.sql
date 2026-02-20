-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. PROFILES (Extends auth.users)
-- We already have public.users from the previous fix. Let's extend it.
-- If you haven't run the previous fix, this creates the table.
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  role text default 'listener' check (role in ('super_admin', 'mosque_admin', 'publisher', 'listener')),
  mosque_id uuid, -- For admins/publishers linked to a specific mosque
  username text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Fix: If table 'public.users' exists from previous step, we rename it to 'profiles' for clarity, 
-- or we just use 'profiles' moving forward. 
-- Let's assume we use 'profiles' to be standard. 
-- If 'public.users' exists, we should ideally migrate it, but for a fresh start/dev:
-- ALTER TABLE public.users RENAME TO profiles; (Commented out to be safe)

-- Enable RLS
alter table public.profiles enable row level security;

-- Policies
create policy "Public profiles are viewable by everyone." on public.profiles for select using (true);
create policy "Users can insert their own profile." on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile." on public.profiles for update using (auth.uid() = id);

-- 2. MOSQUES
create table public.mosques (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  description text,
  location text, -- simple text for now, could be lat/long later
  admin_id uuid references public.profiles(id), -- The Creator/Admin of the mosque
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.mosques enable row level security;

-- Policies
create policy "Mosques are viewable by everyone." on public.mosques for select using (true);
create policy "Mosque Admins can create mosques." on public.mosques for insert with check (
  exists (select 1 from public.profiles where id = auth.uid() and role = 'mosque_admin')
);
create policy "Admins can update their own mosque." on public.mosques for update using (admin_id = auth.uid());

-- 3. RAMADAN DAYS
create table public.ramadan_days (
  id uuid default uuid_generate_v4() primary key,
  mosque_id uuid references public.mosques(id) on delete cascade not null,
  day_number int not null check (day_number between 1 and 30),
  status text default 'red' check (status in ('red', 'yellow', 'green')), -- Red: Empty, Yellow: Partial, Green: Full
  active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(mosque_id, day_number)
);

alter table public.ramadan_days enable row level security;

create policy "Days are viewable by everyone." on public.ramadan_days for select using (true);
-- Only system/triggers usually update this, or Admins
create policy "Admins/Publishers can update days." on public.ramadan_days for update using (
  exists (select 1 from public.profiles where id = auth.uid() and mosque_id = public.ramadan_days.mosque_id)
);

-- 4. RECORDINGS
create table public.recordings (
  id uuid default uuid_generate_v4() primary key,
  mosque_id uuid references public.mosques(id) on delete cascade not null,
  day_id uuid references public.ramadan_days(id) on delete cascade not null,
  publisher_id uuid references public.profiles(id),
  
  prayer_name text not null check (prayer_name in ('Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha', 'Taraweeh', 'Tahajjud')),
  sheikh_name text,
  audio_url text not null,
  
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.recordings enable row level security;

create policy "Recordings are viewable by everyone." on public.recordings for select using (true);
create policy "Publishers can insert recordings for their mosque." on public.recordings for insert with check (
  exists (select 1 from public.profiles where id = auth.uid() and mosque_id = public.recordings.mosque_id)
);
create policy "Publishers can delete their own recordings." on public.recordings for delete using (publisher_id = auth.uid());
create policy "Admins can delete any recording in their mosque." on public.recordings for delete using (
  exists (select 1 from public.mosques where id = public.recordings.mosque_id and admin_id = auth.uid())
);

-- TRIGGERS

-- A. Auto-create 30 days when a mosque is created
create or replace function public.handle_new_mosque()
returns trigger as $$
begin
  for i in 1..30 loop
    insert into public.ramadan_days (mosque_id, day_number)
    values (new.id, i);
  end loop;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_mosque_created
  after insert on public.mosques
  for each row execute procedure public.handle_new_mosque();

-- B. Update Day Status when recording is added/removed
-- (Simplified logic: If any recording exists -> Yellow. Real logic is complex, maybe handle in App or separate function later)
-- For now, let's keep it simple: Application updates status or we just fetch counts.
-- We'll leave the 'status' column update for a later refinement or Application logic to keep this SQL simple.

