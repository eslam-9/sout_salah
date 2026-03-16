-- Create the table
CREATE TABLE day_schedule (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_id      UUID NOT NULL REFERENCES ramadan_days(id) ON DELETE CASCADE,
  mosque_id   UUID NOT NULL REFERENCES mosques(id) ON DELETE CASCADE,
  salah       TEXT NOT NULL,        -- e.g. "الفجر", "التراويح"
  shikh       TEXT NOT NULL,        -- sheikh name
  comments    TEXT,                 -- optional notes
  sort_order  INTEGER DEFAULT 0,    -- row ordering
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- RLS: enable
ALTER TABLE day_schedule ENABLE ROW LEVEL SECURITY;

-- Everyone can read
CREATE POLICY "All users can view schedule"
  ON day_schedule FOR SELECT USING (true);

-- Only admins and mosque publishers can insert/update/delete
CREATE POLICY "Admins and publishers can manage schedule"
  ON day_schedule FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
    OR
    EXISTS (
      SELECT 1 FROM mosque_publishers
      WHERE mosque_publishers.mosque_id = day_schedule.mosque_id
      AND mosque_publishers.publisher_id = auth.uid()
    )
  );
