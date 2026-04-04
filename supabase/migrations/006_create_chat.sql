CREATE TABLE chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT,
  type TEXT CHECK (type IN ('match', 'sport_local', 'group', 'direct')),
  sport_id INT REFERENCES sports(id),
  match_id UUID REFERENCES matches(id),
  city TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE chat_members (
  room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (room_id, user_id)
);

CREATE TABLE chat_messages (
  id SERIAL PRIMARY KEY,
  room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Chat rooms viewable by members" ON chat_rooms FOR SELECT USING (
  EXISTS (SELECT 1 FROM chat_members WHERE room_id = chat_rooms.id AND user_id = auth.uid())
);
CREATE POLICY "Authenticated users can create rooms" ON chat_rooms FOR INSERT WITH CHECK (auth.role() = 'authenticated');

ALTER TABLE chat_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members viewable by room members" ON chat_members FOR SELECT USING (
  EXISTS (SELECT 1 FROM chat_members cm WHERE cm.room_id = chat_members.room_id AND cm.user_id = auth.uid())
);
CREATE POLICY "Users can join rooms" ON chat_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can leave rooms" ON chat_members FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Messages viewable by room members" ON chat_messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM chat_members WHERE room_id = chat_messages.room_id AND user_id = auth.uid())
);
CREATE POLICY "Members can send messages" ON chat_messages FOR INSERT WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (SELECT 1 FROM chat_members WHERE room_id = chat_messages.room_id AND user_id = auth.uid())
);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

CREATE INDEX idx_messages_room ON chat_messages(room_id);
CREATE INDEX idx_messages_created ON chat_messages(created_at DESC);
