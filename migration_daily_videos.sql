-- DAILY VIDEOS TABLE
create table public.daily_videos (
  id uuid default uuid_generate_v4() not null primary key,
  mosque_id uuid references public.mosques(id) on delete cascade not null,
  day_id uuid references public.ramadan_days(id) on delete cascade not null,
  publisher_id uuid references public.profiles(id) on delete set null,
  video_url text not null,
  description text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(mosque_id, day_id)
);

-- Enable RLS
alter table public.daily_videos enable row level security;

-- Policies
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
