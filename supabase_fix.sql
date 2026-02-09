-- ALREADY EXISTS? This script safely updates your trigger for Anonymous Users.
-- Assumes your table is named 'public.users'. If it's 'public.profiles', change it below.

-- 1. Create or Update the Function to handle NULL emails
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (
    new.id,
    -- CRITICAL FIX: If email is NULL (Anonymous User), use a placeholder
    COALESCE(new.email, 'guest_' || substr(new.id::text, 1, 8))
  )
  ON CONFLICT (id) DO NOTHING; -- Prevents errors if row exists
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Ensure the Trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- OPTIONAL: If you haven't created the table yet, run this:

create table public.users (
  id uuid not null references auth.users on delete cascade,
  email text,
  primary key (id)
);
alter table public.users enable row level security;

