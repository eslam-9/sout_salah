-- Fix RLS policy for mosque insertion
-- The current policy only allows mosque_admin role, but we need to allow any authenticated user
-- or adjust based on your requirements

-- Drop the restrictive policy
DROP POLICY IF EXISTS "Mosque Admins can create mosques." ON public.mosques;

-- Create a new policy that allows authenticated users to create mosques
-- Option 1: Allow any authenticated user to create mosques
CREATE POLICY "Authenticated users can create mosques." ON public.mosques 
  FOR INSERT 
  WITH CHECK (auth.uid() IS NOT NULL);

-- Option 2: If you want to keep role-based restriction, make sure users have the correct role
-- First, check if the user has a profile and update their role if needed
-- You can run this in Supabase SQL editor to give your test user the mosque_admin role:
-- UPDATE public.profiles SET role = 'mosque_admin' WHERE id = auth.uid();

-- Also ensure the admin_id is set automatically for new mosques
-- You might want to add a trigger or default value
