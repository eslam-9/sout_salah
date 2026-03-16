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
