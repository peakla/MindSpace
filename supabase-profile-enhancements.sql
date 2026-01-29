
 
-- =====================================================
-- 1. FOLLOWERS SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS followers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  follower_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

ALTER TABLE followers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view followers" ON followers
  FOR SELECT USING (true);

CREATE POLICY "Users can follow others" ON followers
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow" ON followers
  FOR DELETE USING (auth.uid() = follower_id);

-- =====================================================
-- 2. ACHIEVEMENTS/BADGES SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS achievements (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  category TEXT NOT NULL,
  points INTEGER DEFAULT 10,
  criteria JSONB
);

CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id TEXT REFERENCES achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view achievements" ON achievements
  FOR SELECT USING (true);

CREATE POLICY "Anyone can view user achievements" ON user_achievements
  FOR SELECT USING (true);

CREATE POLICY "System can grant achievements" ON user_achievements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Seed default achievements
INSERT INTO achievements (id, name, description, icon, category, points, criteria) VALUES
  ('first_post', 'First Steps', 'Created your first community post', 'create-outline', 'community', 10, '{"posts": 1}'),
  ('five_posts', 'Active Voice', 'Created 5 community posts', 'chatbubbles-outline', 'community', 25, '{"posts": 5}'),
  ('first_comment', 'Joining In', 'Left your first comment', 'chatbubble-outline', 'community', 10, '{"comments": 1}'),
  ('helpful_member', 'Helpful Member', 'Received 10 likes on your posts', 'heart-outline', 'community', 50, '{"likes_received": 10}'),
  ('popular_voice', 'Popular Voice', 'Received 50 likes on your posts', 'star-outline', 'community', 100, '{"likes_received": 50}'),
  ('week_streak', '7 Day Streak', 'Visited MindBalance 7 days in a row', 'flame-outline', 'engagement', 30, '{"streak": 7}'),
  ('month_streak', '30 Day Streak', 'Visited MindBalance 30 days in a row', 'ribbon-outline', 'engagement', 100, '{"streak": 30}'),
  ('first_save', 'Bookworm', 'Saved your first article', 'bookmark-outline', 'reading', 10, '{"saves": 1}'),
  ('mood_tracker', 'Self Aware', 'Logged your mood 7 times', 'happy-outline', 'wellness', 25, '{"mood_logs": 7}'),
  ('goal_setter', 'Goal Setter', 'Created your first wellness goal', 'flag-outline', 'wellness', 15, '{"goals": 1}'),
  ('goal_achiever', 'Goal Achiever', 'Completed a wellness goal', 'trophy-outline', 'wellness', 50, '{"goals_completed": 1}'),
  ('profile_complete', 'Complete Profile', 'Added avatar, bio, and social links', 'person-outline', 'profile', 20, '{"profile_complete": true}')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 3. MOOD TRACKING SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS mood_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  mood TEXT NOT NULL,
  mood_score INTEGER NOT NULL CHECK (mood_score BETWEEN 1 AND 5),
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE mood_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own mood logs" ON mood_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create mood logs" ON mood_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own mood logs" ON mood_logs
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- 4. WELLNESS GOALS SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS wellness_goals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  target_value INTEGER DEFAULT 1,
  current_value INTEGER DEFAULT 0,
  start_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE wellness_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own goals" ON wellness_goals
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create goals" ON wellness_goals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own goals" ON wellness_goals
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own goals" ON wellness_goals
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- 5. READING STREAKS & ENGAGEMENT TRACKING
-- =====================================================

CREATE TABLE IF NOT EXISTS user_engagement (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  visit_date DATE NOT NULL,
  articles_read INTEGER DEFAULT 0,
  time_spent_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, visit_date)
);

ALTER TABLE user_engagement ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own engagement" ON user_engagement
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can log engagement" ON user_engagement
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own engagement" ON user_engagement
  FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- 6. ENHANCED PROFILES TABLE (add new columns)
-- =====================================================

-- Add new columns to existing profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS theme_color TEXT DEFAULT '#d4a574';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS social_links JSONB DEFAULT '{}';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pinned_post_id UUID REFERENCES posts(id) ON DELETE SET NULL;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT TRUE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS show_activity BOOLEAN DEFAULT TRUE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS show_saved BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS reputation_points INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS current_streak INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_visit_date DATE;

-- =====================================================
-- 7. SAVED ARTICLES TABLE (if not exists)
-- =====================================================

CREATE TABLE IF NOT EXISTS saved_articles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  article_slug TEXT NOT NULL,
  article_title TEXT NOT NULL,
  article_thumbnail TEXT,
  saved_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, article_slug)
);

ALTER TABLE saved_articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own saved articles" ON saved_articles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can save articles" ON saved_articles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unsave articles" ON saved_articles
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- 8. FUNCTION TO CALCULATE REPUTATION
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_user_reputation(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  total_reputation INTEGER := 0;
  post_likes INTEGER;
  comment_count INTEGER;
  achievement_points INTEGER;
BEGIN
  SELECT COALESCE(SUM(p.like_count), 0) INTO post_likes
  FROM posts p WHERE p.author_id = user_uuid;
  
  SELECT COUNT(*) INTO comment_count
  FROM post_comments WHERE author_id = user_uuid;
  
  SELECT COALESCE(SUM(a.points), 0) INTO achievement_points
  FROM user_achievements ua
  JOIN achievements a ON ua.achievement_id = a.id
  WHERE ua.user_id = user_uuid;
  
  total_reputation := (post_likes * 2) + (comment_count * 1) + achievement_points;
  
  RETURN total_reputation;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 9. FUNCTION TO UPDATE STREAK
-- =====================================================

CREATE OR REPLACE FUNCTION update_user_streak(user_uuid UUID)
RETURNS VOID AS $$
DECLARE
  last_visit DATE;
  new_streak INTEGER;
BEGIN
  SELECT last_visit_date, current_streak INTO last_visit, new_streak
  FROM profiles WHERE id = user_uuid;
  
  IF last_visit IS NULL OR last_visit < CURRENT_DATE - INTERVAL '1 day' THEN
    new_streak := 1;
  ELSIF last_visit = CURRENT_DATE - INTERVAL '1 day' THEN
    new_streak := COALESCE(new_streak, 0) + 1;
  END IF;
  
  UPDATE profiles SET 
    current_streak = new_streak,
    longest_streak = GREATEST(COALESCE(longest_streak, 0), new_streak),
    last_visit_date = CURRENT_DATE
  WHERE id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. SAVED ARTICLES SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS saved_articles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  article_slug TEXT NOT NULL,
  article_title TEXT NOT NULL,
  article_category TEXT,
  article_image TEXT,
  saved_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, article_slug)
);

ALTER TABLE saved_articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own saved articles" ON saved_articles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can save articles" ON saved_articles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unsave articles" ON saved_articles
  FOR DELETE USING (auth.uid() = user_id);

-- Enable realtime for new tables
ALTER PUBLICATION supabase_realtime ADD TABLE followers;
ALTER PUBLICATION supabase_realtime ADD TABLE user_achievements;
ALTER PUBLICATION supabase_realtime ADD TABLE mood_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE wellness_goals;
ALTER PUBLICATION supabase_realtime ADD TABLE saved_articles;
