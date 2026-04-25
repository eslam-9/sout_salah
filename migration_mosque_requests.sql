-- MIGRATION: Create mosque_requests table

create table public.mosque_requests (
  id uuid default gen_random_uuid() not null primary key,
  name text not null,
  location text not null,
  description text,
  requested_by uuid references public.profiles(id) on delete cascade not null,
  status text default 'pending'::text not null, -- 'pending', 'accepted', 'declined'
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.mosque_requests enable row level security;

-- Policies
create policy "Users can view their own requests and admins can view all"
  on public.mosque_requests for select
  using ( requested_by = auth.uid() or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') );

create policy "Users can insert their own requests"
  on public.mosque_requests for insert
  with check ( requested_by = auth.uid() );

create policy "Admins can update requests"
  on public.mosque_requests for update
  using ( exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') );
