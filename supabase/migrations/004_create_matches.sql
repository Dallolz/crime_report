CREATE TABLE matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sport_id INT REFERENCES sports(id),
  creator_id UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'full', 'in_progress', 'completed', 'cancelled')),
  match_type TEXT CHECK (match_type IN ('quick', 'scheduled')),
  location GEOGRAPHY(POINT),
  venue_name TEXT,
  address TEXT,
  scheduled_at TIMESTAMPTZ,
  duration_min INT,
  max_players INT,
  min_skill TEXT,
  max_skill TEXT,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE match_participants (
  id SERIAL PRIMARY KEY,
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
  player_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  team TEXT,
  status TEXT DEFAULT 'joined' CHECK (status IN ('joined', 'confirmed', 'no_show', 'completed')),
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(match_id, player_id)
);

CREATE TABLE match_reviews (
  id SERIAL PRIMARY KEY,
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
  reviewer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  reviewed_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  rating INT CHECK (rating BETWEEN 1 AND 5),
  fair_play BOOLEAN DEFAULT true,
  showed_up BOOLEAN DEFAULT true,
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(match_id, reviewer_id, reviewed_id)
);

CREATE TABLE match_results (
  id SERIAL PRIMARY KEY,
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
  team_a_score INT,
  team_b_score INT,
  winner_team TEXT CHECK (winner_team IN ('A', 'B', 'draw')),
  reported_by UUID REFERENCES profiles(id),
  confirmed_by UUID[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Matches are viewable by everyone" ON matches FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create matches" ON matches FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Creator can update own match" ON matches FOR UPDATE USING (auth.uid() = creator_id);

ALTER TABLE match_participants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Match participants are viewable by everyone" ON match_participants FOR SELECT USING (true);
CREATE POLICY "Authenticated users can join matches" ON match_participants FOR INSERT WITH CHECK (auth.uid() = player_id);
CREATE POLICY "Users can update own participation" ON match_participants FOR UPDATE USING (auth.uid() = player_id);
CREATE POLICY "Users can leave matches" ON match_participants FOR DELETE USING (auth.uid() = player_id);

ALTER TABLE match_reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Reviews are viewable by everyone" ON match_reviews FOR SELECT USING (true);
CREATE POLICY "Users can create reviews" ON match_reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

ALTER TABLE match_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Results are viewable by everyone" ON match_results FOR SELECT USING (true);
CREATE POLICY "Match participants can report results" ON match_results FOR INSERT WITH CHECK (auth.uid() = reported_by);

-- Indexes
CREATE INDEX idx_matches_sport ON matches(sport_id);
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_matches_location ON matches USING GIST(location);
CREATE INDEX idx_matches_scheduled ON matches(scheduled_at);
CREATE INDEX idx_match_participants_match ON match_participants(match_id);
CREATE INDEX idx_match_participants_player ON match_participants(player_id);
