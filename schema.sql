-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- PROFILES TABLE
-- Extends the auth.users table with additional profile information
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  username text,
  email text,
  role text default 'listener'::text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  mosque_id uuid -- Will reference mosques(id) but added later to avoid circular dependency issues if not careful, though here we can define it if table exists. We'll add FK constraint after.
);

-- MOSQUES TABLE
create table public.mosques (
  id uuid default uuid_generate_v4() not null primary key,
  name text not null,
  description text,
  location text,
  admin_id uuid references public.profiles(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add circular FK for profiles.mosque_id
alter table public.profiles 
  add constraint profiles_mosque_id_fkey 
  foreign key (mosque_id) references public.mosques(id) on delete set null;

-- RAMADAN DAYS TABLE
create table public.ramadan_days (
  id uuid default uuid_generate_v4() not null primary key,
  mosque_id uuid references public.mosques(id) on delete cascade not null,
  day_number integer not null,
  month integer not null,
  year integer not null,
  status text default 'red'::text not null, -- 'red', 'yellow', 'green'
  active boolean default true not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(mosque_id, day_number, month, year)
);

-- RECORDINGS TABLE
create table public.recordings (
  id uuid default uuid_generate_v4() not null primary key,
  mosque_id uuid references public.mosques(id) on delete cascade not null,
  day_id uuid references public.ramadan_days(id) on delete cascade not null,
  publisher_id uuid references public.profiles(id) on delete set null,
  prayer_name text not null, -- 'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha', 'Taraweeh', 'Qiyam'
  sheikh_name text default 'Unknown'::text,
  audio_url text not null,
  file_size bigint, -- File size in bytes
  duration integer, -- Duration in seconds
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- DAY SCHEDULE TABLE
create table public.day_schedule (
  id uuid default uuid_generate_v4() not null primary key,
  day_id uuid references public.ramadan_days(id) on delete cascade not null,
  mosque_id uuid references public.mosques(id) on delete cascade not null,
  salah text not null,        -- e.g. "الفجر", "التراويح"
  shikh text not null,        -- sheikh name
  comments text,                 -- optional notes
  sort_order integer default 0,    -- row ordering
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- MOSQUE PUBLISHERS TABLE
-- Junction table for linking publishers to mosques (if multiple publishers per mosque are allowed)
create table public.mosque_publishers (
  id uuid default uuid_generate_v4() not null primary key,
  mosque_id uuid references public.mosques(id) on delete cascade not null,
  publisher_id uuid references public.profiles(id) on delete cascade not null,
  added_by uuid references public.profiles(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(mosque_id, publisher_id)
);

-- FCM TOKENS TABLE
create table public.fcm_tokens (
  id uuid default uuid_generate_v4() not null primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  token text not null,
  platform text default 'android'::text,  -- 'android' or 'ios'
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, token)
);

-- MOSQUE REQUESTS TABLE
create table public.mosque_requests (
  id uuid default uuid_generate_v4() not null primary key,
  name text not null,
  location text not null,
  description text,
  requested_by uuid references public.profiles(id) on delete cascade not null,
  status text default 'pending'::text not null, -- 'pending', 'accepted', 'declined'
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- DAILY VIDEOS TABLE
create table public.daily_videos (
  id uuid default uuid_generate_v4() not null primary key,
  mosque_id uuid references public.mosques(id) on delete cascade not null,
  day_id uuid references public.ramadan_days(id) on delete cascade not null,
  publisher_id uuid references public.profiles(id) on delete set null,
  title text,
  video_url text not null,
  description text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- STORAGE BUCKETS SETUP (Row Level Security for Storage)
-- Assuming 'recordings' bucket exists in Supabase Storage

-- ROW LEVEL SECURITY (RLS) POLICIES

-- Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.mosques enable row level security;
alter table public.ramadan_days enable row level security;
alter table public.recordings enable row level security;
alter table public.mosque_publishers enable row level security;
alter table public.day_schedule enable row level security;
alter table public.fcm_tokens enable row level security;
alter table public.mosque_requests enable row level security;
alter table public.daily_videos enable row level security;

-- PROFILES POLICIES
create policy "Public profiles are viewable by everyone."
  on public.profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on public.profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on public.profiles for update
  using ( auth.uid() = id );

-- MOSQUES POLICIES
create policy "Mosques are viewable by everyone."
  on public.mosques for select
  using ( true );

create policy "Admins can insert mosques."
  on public.mosques for insert
  with check ( 
    auth.uid() in (
      select id from public.profiles where role = 'admin'
    ) 
  );

create policy "Admins can update their mosques."
  on public.mosques for update
  using ( admin_id = auth.uid() or auth.uid() in (select id from public.profiles where role = 'admin') );

-- RAMADAN DAYS POLICIES
create policy "Ramadan days are viewable by everyone."
  on public.ramadan_days for select
  using ( true );

create policy "Mosque admins/publishers can insert days."
  on public.ramadan_days for insert
  with check (
    exists (
      select 1 from public.mosques 
      where id = mosque_id 
      and (
        admin_id = auth.uid() 
        or exists (select 1 from public.mosque_publishers where mosque_id = mosques.id and publisher_id = auth.uid())
        or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
      )
    )
  );

-- RECORDINGS POLICIES
create policy "Recordings are viewable by everyone."
  on public.recordings for select
  using ( true );

create policy "Mosque admins/publishers can upload recordings."
  on public.recordings for insert
  with check (
    exists (
      select 1 from public.mosques 
      where id = mosque_id 
      and (admin_id = auth.uid() or exists (select 1 from public.mosque_publishers where mosque_id = mosques.id and publisher_id = auth.uid()))
    )
  );

create policy "Publishers can delete their own recordings"
  on public.recordings for delete
  using ( publisher_id = auth.uid() );

-- DAY SCHEDULE POLICIES
create policy "All users can view schedule"
  on public.day_schedule for select
  using ( true );

create policy "Admins and publishers can manage schedule"
  on public.day_schedule for all
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
    or
    exists (
      select 1 from public.mosque_publishers
      where mosque_id = day_schedule.mosque_id
      and publisher_id = auth.uid()
    )
  );

-- MOSQUE PUBLISHERS POLICIES
create policy "Mosque publishers viewable by everyone"
  on public.mosque_publishers for select
  using ( true );

create policy "Super admins can add publishers"
  on public.mosque_publishers for insert
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid()
      and role = 'admin'
    )
  );

create policy "Mosque admins can remove publishers"
  on public.mosque_publishers for delete
  using (
    exists (
      select 1 from public.mosques
      where id = mosque_id
      and admin_id = auth.uid()
    )
  );

-- FCM TOKENS POLICIES
create policy "Users can manage own tokens"
  on public.fcm_tokens for all
  using ( auth.uid() = user_id );

-- MOSQUE REQUESTS POLICIES
create policy "Users can view their own requests and admins can view all"
  on public.mosque_requests for select
  using ( requested_by = auth.uid() or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') );

create policy "Users can insert their own requests"
  on public.mosque_requests for insert
  with check ( requested_by = auth.uid() );

create policy "Admins can update requests"
  on public.mosque_requests for update
  using ( exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') );

-- DAILY VIDEOS POLICIES
create policy "Daily videos are viewable by everyone."
  on public.daily_videos for select
  using ( true );

create policy "Mosque admins/publishers can upload daily videos."
  on public.daily_videos for insert
  with check (
    exists (
      select 1 from public.mosques 
      where id = mosque_id 
      and (
        admin_id = auth.uid() 
        or exists (select 1 from public.mosque_publishers where mosque_id = mosques.id and publisher_id = auth.uid())
      )
    )
  );

create policy "Deployers can update/delete their own videos or admins can"
  on public.daily_videos for all
  using (
    publisher_id = auth.uid()
    or exists (
      select 1 from public.mosques
      where id = mosque_id
      and admin_id = auth.uid()
    )
  );

-- FUNCTIONS & TRIGGERS

-- Function to handle new user signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, username, role)
  values (new.id, new.email, new.raw_user_meta_data->>'username', coalesce(new.raw_user_meta_data->>'role', 'listener'));
  return new;
end;
$$ language plpgsql security definer;

-- Trigger to automatically create profile on signup
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
