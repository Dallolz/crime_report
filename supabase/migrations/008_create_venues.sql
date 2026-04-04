CREATE TABLE venues (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT,
  location GEOGRAPHY(POINT),
  sport_ids INT[] DEFAULT '{}',
  photos TEXT[] DEFAULT '{}',
  rating DECIMAL(3,2) DEFAULT 0.00,
  review_count INT DEFAULT 0,
  created_by UUID REFERENCES profiles(id),
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE venues ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Venues are viewable by everyone" ON venues FOR SELECT USING (true);
CREATE POLICY "Authenticated users can add venues" ON venues FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Creator can update venue" ON venues FOR UPDATE USING (auth.uid() = created_by);

CREATE INDEX idx_venues_location ON venues USING GIST(location);
CREATE INDEX idx_venues_sports ON venues USING GIN(sport_ids);
