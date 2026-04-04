CREATE TABLE sports (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  icon_url TEXT,
  team_size_min INT DEFAULT 1,
  team_size_max INT DEFAULT 1,
  match_format TEXT DEFAULT 'individual' CHECK (match_format IN ('individual', 'team', 'both')),
  default_duration_min INT DEFAULT 60,
  rules_json JSONB DEFAULT '{}'
);

ALTER TABLE sports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Sports are viewable by everyone" ON sports FOR SELECT USING (true);
