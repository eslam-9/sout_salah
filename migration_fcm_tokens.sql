-- Store FCM tokens for each user
CREATE TABLE public.fcm_tokens (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  token TEXT NOT NULL,
  platform TEXT DEFAULT 'android',  -- 'android' or 'ios'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Users can manage their own tokens
CREATE POLICY "Users can manage own tokens"
  ON public.fcm_tokens FOR ALL
  USING (auth.uid() = user_id);
