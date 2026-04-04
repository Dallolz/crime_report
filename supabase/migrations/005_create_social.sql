CREATE TABLE follows (
  follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (follower_id, following_id)
);

CREATE TABLE activity_feed (
  id SERIAL PRIMARY KEY,
  actor_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  target_type TEXT,
  target_id TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Follows are viewable by everyone" ON follows FOR SELECT USING (true);
CREATE POLICY "Users can follow others" ON follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users can unfollow" ON follows FOR DELETE USING (auth.uid() = follower_id);

ALTER TABLE activity_feed ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Feed is viewable by everyone" ON activity_feed FOR SELECT USING (true);
CREATE POLICY "Users can create feed entries" ON activity_feed FOR INSERT WITH CHECK (auth.uid() = actor_id);

CREATE INDEX idx_feed_actor ON activity_feed(actor_id);
CREATE INDEX idx_feed_created ON activity_feed(created_at DESC);
