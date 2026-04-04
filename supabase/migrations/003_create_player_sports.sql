CREATE TABLE player_sports (
  id SERIAL PRIMARY KEY,
  player_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  sport_id INT REFERENCES sports(id) ON DELETE CASCADE,
  elo_rating INT DEFAULT 1000,
  skill_level TEXT DEFAULT 'beginner' CHECK (skill_level IN ('beginner', 'intermediate', 'advanced', 'expert')),
  matches_played INT DEFAULT 0,
  wins INT DEFAULT 0,
  reputation_score DECIMAL(3,2) DEFAULT 5.00,
  xp INT DEFAULT 0,
  UNIQUE(player_id, sport_id)
);

ALTER TABLE player_sports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Player sports are viewable by everyone" ON player_sports FOR SELECT USING (true);
CREATE POLICY "Users can insert own player_sports" ON player_sports FOR INSERT WITH CHECK (auth.uid() = player_id);
CREATE POLICY "Users can update own player_sports" ON player_sports FOR UPDATE USING (auth.uid() = player_id);
