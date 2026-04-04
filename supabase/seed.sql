-- Seed 10 sports
INSERT INTO sports (name, display_name, team_size_min, team_size_max, match_format, default_duration_min) VALUES
  ('football', 'Football', 4, 11, 'team', 90),
  ('basketball', 'Basketball', 3, 5, 'team', 60),
  ('tennis', 'Tennis', 1, 2, 'both', 60),
  ('padel', 'Padel', 2, 2, 'team', 60),
  ('badminton', 'Badminton', 1, 2, 'both', 45),
  ('volleyball', 'Volleyball', 4, 6, 'team', 60),
  ('running', 'Running', 1, 50, 'individual', 60),
  ('table_tennis', 'Ping-pong', 1, 2, 'both', 30),
  ('boxing', 'Boxe / MMA', 1, 1, 'individual', 60),
  ('cycling', 'Cyclisme', 1, 50, 'individual', 120);

-- Seed badges
INSERT INTO badges (name, description, icon_url, category, condition_json) VALUES
  ('Premier Match', 'Joue ton premier match', 'badge_first_match', 'achievement', '{"type": "matches_played", "count": 1}'),
  ('Rookie', 'Joue 5 matchs', 'badge_rookie', 'achievement', '{"type": "matches_played", "count": 5}'),
  ('Régulier', 'Joue 25 matchs', 'badge_regular', 'achievement', '{"type": "matches_played", "count": 25}'),
  ('Vétéran', 'Joue 100 matchs', 'badge_veteran', 'achievement', '{"type": "matches_played", "count": 100}'),
  ('Multi-sport', 'Joue dans 3 sports différents', 'badge_multisport', 'sport', '{"type": "sports_played", "count": 3}'),
  ('Décathlonien', 'Joue dans les 10 sports', 'badge_decathlon', 'sport', '{"type": "sports_played", "count": 10}'),
  ('Série de 3', 'Joue 3 jours consécutifs', 'badge_streak3', 'streak', '{"type": "streak_days", "count": 3}'),
  ('Série de 7', 'Joue 7 jours consécutifs', 'badge_streak7', 'streak', '{"type": "streak_days", "count": 7}'),
  ('Série de 30', 'Joue 30 jours consécutifs', 'badge_streak30', 'streak', '{"type": "streak_days", "count": 30}'),
  ('Social Butterfly', 'Suis 10 joueurs', 'badge_social', 'social', '{"type": "following_count", "count": 10}'),
  ('Fair-play', 'Reçois 10 reviews 5 étoiles', 'badge_fairplay', 'social', '{"type": "five_star_reviews", "count": 10}'),
  ('Créateur', 'Crée 10 matchs', 'badge_creator', 'achievement', '{"type": "matches_created", "count": 10}');
