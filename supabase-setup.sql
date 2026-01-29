-- MindBalance Community Forum Database Setup
-- Run this SQL in your Supabase Dashboard > SQL Editor

-- Create posts table
CREATE TABLE IF NOT EXISTS posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  author_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  author_email TEXT NOT NULL,
  author_name TEXT NOT NULL,
  content TEXT NOT NULL,
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create post_likes table for tracking who liked which post
CREATE TABLE IF NOT EXISTS post_likes (
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (post_id, user_id)
);

-- Create post_comments table
CREATE TABLE IF NOT EXISTS post_comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  author_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  author_email TEXT NOT NULL,
  author_name TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create notifications table for mentions, likes, comments, follows
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('mention', 'like', 'comment', 'follow', 'reply')),
  from_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  from_user_name TEXT NOT NULL,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES post_comments(id) ON DELETE CASCADE,
  content TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Notifications policies
CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Authenticated users can create notifications" ON notifications
  FOR INSERT WITH CHECK (auth.uid() = from_user_id);

CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications" ON notifications
  FOR DELETE USING (auth.uid() = user_id);

-- Posts policies: Anyone can read, only author can insert/update/delete
CREATE POLICY "Anyone can view posts" ON posts
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create posts" ON posts
  FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update own posts" ON posts
  FOR UPDATE USING (auth.uid() = author_id);

CREATE POLICY "Users can delete own posts or admin can delete any" ON posts
  FOR DELETE USING (
    auth.uid() = author_id 
    OR auth.jwt()->>'email' = 'marlonsalmeron871@gmail.com'
  );

-- Post likes policies
CREATE POLICY "Anyone can view likes" ON post_likes
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can like" ON post_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike" ON post_likes
  FOR DELETE USING (auth.uid() = user_id);

-- Comments policies
CREATE POLICY "Anyone can view comments" ON post_comments
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can comment" ON post_comments
  FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can delete own comments" ON post_comments
  FOR DELETE USING (auth.uid() = author_id);

-- Function to update like count
CREATE OR REPLACE FUNCTION update_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET like_count = like_count - 1 WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for like count
DROP TRIGGER IF EXISTS on_like_change ON post_likes;
CREATE TRIGGER on_like_change
  AFTER INSERT OR DELETE ON post_likes
  FOR EACH ROW EXECUTE FUNCTION update_like_count();

-- Function to update comment count
CREATE OR REPLACE FUNCTION update_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET comment_count = comment_count - 1 WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for comment count
DROP TRIGGER IF EXISTS on_comment_change ON post_comments;
CREATE TRIGGER on_comment_change
  AFTER INSERT OR DELETE ON post_comments
  FOR EACH ROW EXECUTE FUNCTION update_comment_count();

-- Enable realtime for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE posts;
ALTER PUBLICATION supabase_realtime ADD TABLE post_likes;
ALTER PUBLICATION supabase_realtime ADD TABLE post_comments;

-- =====================================================
-- SEED DATA: Original MindBalance Community Posts
-- These posts will appear in the Activity Feed
-- This is IDEMPOTENT - safe to run multiple times
-- =====================================================

-- First, modify posts table to allow system posts (no author_id required)
ALTER TABLE posts ALTER COLUMN author_id DROP NOT NULL;

-- Insert seed posts only if no posts exist (idempotent)
-- This prevents duplicate posts if the script is run multiple times
INSERT INTO posts (author_email, author_name, content, like_count, comment_count, created_at)
SELECT * FROM (VALUES
  (
    'team@mindbalance.com',
    'MindBalance Team',
    'If you''re struggling to fall asleep, try a "wind-down" routine: same time nightly, dim lights 60 minutes before bed, and keep your phone out of reach. Small changes beat perfect plans.',
    24,
    8,
    NOW() - INTERVAL '1 day'
  ),
  (
    'support@mindbalance.com',
    'Student Support',
    'If your thoughts spiral before a test, try a 60-second reset: inhale 4 seconds, hold 4, exhale 6. Repeat 5 times. It doesn''t erase anxiety — it lowers the volume.',
    18,
    5,
    NOW() - INTERVAL '2 days'
  ),
  (
    'team@mindbalance.com',
    'MindBalance Team',
    'How do you manage exam anxiety? Share your tips with the community! Whether it''s breathing exercises, study techniques, or self-care routines - every strategy helps someone.',
    32,
    12,
    NOW() - INTERVAL '3 days'
  ),
  (
    'team@mindbalance.com',
    'MindBalance Team',
    'Best sleep routine for teens? Here''s what research shows: consistent bedtime, no screens 1 hour before sleep, cool room temperature (65-68°F), and a relaxing pre-sleep activity like reading or stretching.',
    28,
    8,
    NOW() - INTERVAL '4 days'
  ),
  (
    'community@mindbalance.com',
    'Community Wellness',
    'Weekly check-in: How are you feeling today? Remember, it''s okay to not be okay. This is a safe space to share, support, and connect with others on similar journeys.',
    45,
    15,
    NOW() - INTERVAL '5 days'
  ),
  (
    'support@mindbalance.com',
    'Student Support',
    'Stress management tip: The 5-4-3-2-1 grounding technique works wonders when you''re feeling overwhelmed. Name 5 things you see, 4 you hear, 3 you can touch, 2 you smell, 1 you taste.',
    22,
    6,
    NOW() - INTERVAL '6 days'
  )
) AS seed_data(author_email, author_name, content, like_count, comment_count, created_at)
WHERE NOT EXISTS (SELECT 1 FROM posts WHERE author_email IN ('team@mindbalance.com', 'support@mindbalance.com', 'community@mindbalance.com'));

-- Note: These seed posts don't have an author_id (they're system posts)
-- Users can still create their own posts which will have proper author_id linking

-- =====================================================
-- SEED COMMENTS: Replies to the seed posts
-- =====================================================

-- Insert seed comments (replies) for the posts
-- We need to get the post IDs first, so we use a CTE
INSERT INTO post_comments (post_id, author_email, author_name, content, created_at)
SELECT posts.id, comments.author_email, comments.author_name, comments.content, comments.created_at
FROM posts
CROSS JOIN (VALUES
  ('team@mindbalance.com', 'MindBalance Team', 'Great question! Remember that everyone''s journey is different.', NOW() - INTERVAL '2 days 2 hours'),
  ('support@mindbalance.com', 'Student Support', 'These tips really work! I''ve been using them for a month now.', NOW() - INTERVAL '2 days 5 hours'),
  ('community@mindbalance.com', 'Community Wellness', 'Thank you for sharing. It helps knowing we''re not alone.', NOW() - INTERVAL '3 days 1 hour')
) AS comments(author_email, author_name, content, created_at)
WHERE posts.author_email = 'team@mindbalance.com' 
  AND posts.content LIKE '%exam anxiety%'
  AND NOT EXISTS (SELECT 1 FROM post_comments WHERE post_comments.post_id = posts.id);

-- Comments on the sleep routine post
INSERT INTO post_comments (post_id, author_email, author_name, content, created_at)
SELECT posts.id, comments.author_email, comments.author_name, comments.content, comments.created_at
FROM posts
CROSS JOIN (VALUES
  ('support@mindbalance.com', 'Student Support', 'The no-screens rule is so important! Blue light really affects sleep quality.', NOW() - INTERVAL '3 days 3 hours'),
  ('team@mindbalance.com', 'MindBalance Team', 'Has anyone tried reading before bed? It works wonders for me!', NOW() - INTERVAL '3 days 6 hours')
) AS comments(author_email, author_name, content, created_at)
WHERE posts.author_email = 'team@mindbalance.com' 
  AND posts.content LIKE '%Best sleep routine%'
  AND NOT EXISTS (SELECT 1 FROM post_comments WHERE post_comments.post_id = posts.id);

-- Comments on the weekly check-in post
INSERT INTO post_comments (post_id, author_email, author_name, content, created_at)
SELECT posts.id, comments.author_email, comments.author_name, comments.content, comments.created_at
FROM posts
CROSS JOIN (VALUES
  ('team@mindbalance.com', 'MindBalance Team', 'Feeling better today! Small wins matter.', NOW() - INTERVAL '4 days 2 hours'),
  ('support@mindbalance.com', 'Student Support', 'Remember to be kind to yourself. Progress isn''t always linear.', NOW() - INTERVAL '4 days 4 hours'),
  ('community@mindbalance.com', 'Community Wellness', 'This community is so supportive. Thank you all!', NOW() - INTERVAL '4 days 8 hours')
) AS comments(author_email, author_name, content, created_at)
WHERE posts.author_email = 'community@mindbalance.com' 
  AND posts.content LIKE '%Weekly check-in%'
  AND NOT EXISTS (SELECT 1 FROM post_comments WHERE post_comments.post_id = posts.id);

-- Comments on the grounding technique post
INSERT INTO post_comments (post_id, author_email, author_name, content, created_at)
SELECT posts.id, comments.author_email, comments.author_name, comments.content, comments.created_at
FROM posts
CROSS JOIN (VALUES
  ('team@mindbalance.com', 'MindBalance Team', 'This technique saved me during my last presentation!', NOW() - INTERVAL '5 days 3 hours'),
  ('community@mindbalance.com', 'Community Wellness', 'I teach this to my friends now. It''s so helpful!', NOW() - INTERVAL '5 days 5 hours')
) AS comments(author_email, author_name, content, created_at)
WHERE posts.author_email = 'support@mindbalance.com' 
  AND posts.content LIKE '%5-4-3-2-1 grounding%'
  AND NOT EXISTS (SELECT 1 FROM post_comments WHERE post_comments.post_id = posts.id);

-- ============================================
-- ADDITIONAL FEATURES: Post Editing & Reports
-- ============================================

-- Add edited_at column to posts table (for edit tracking)
ALTER TABLE posts ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ DEFAULT NULL;

-- Create post_reports table for reporting inappropriate posts
CREATE TABLE IF NOT EXISTS post_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  reporter_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  reporter_email TEXT NOT NULL,
  reason TEXT NOT NULL CHECK (reason IN ('spam', 'harassment', 'inappropriate', 'self-harm', 'other')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ DEFAULT NULL,
  UNIQUE(post_id, reporter_id)
);

-- Enable RLS on post_reports
ALTER TABLE post_reports ENABLE ROW LEVEL SECURITY;

-- Reports policies: Users can create reports, only admin can view/update
CREATE POLICY "Authenticated users can submit reports" ON post_reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can view own reports" ON post_reports
  FOR SELECT USING (
    auth.uid() = reporter_id 
    OR auth.jwt()->>'email' = 'marlonsalmeron871@gmail.com'
  );

CREATE POLICY "Only admin can update reports" ON post_reports
  FOR UPDATE USING (auth.jwt()->>'email' = 'marlonsalmeron871@gmail.com');

CREATE POLICY "Only admin can delete reports" ON post_reports
  FOR DELETE USING (auth.jwt()->>'email' = 'marlonsalmeron871@gmail.com');

-- ============================================
-- PIN POSTS FEATURE (Admin only)
-- ============================================

-- Add is_pinned, pinned_at, and media_url columns to posts
ALTER TABLE posts ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS pinned_at TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS media_url TEXT DEFAULT NULL;

-- Policy for admin to pin/unpin posts (allows admin to update is_pinned on any post)
-- Drop existing conflicting policies first if they exist
DROP POLICY IF EXISTS "Admin can pin posts" ON posts;
DROP POLICY IF EXISTS "Admin can update any post" ON posts;

-- Admin can update any post (for pinning and moderation)
-- USING clause: admin can see/select posts to update
-- WITH CHECK clause: admin can set new values on any post
CREATE POLICY "Admin can update any post" ON posts
  FOR UPDATE 
  USING (auth.jwt()->>'email' = 'marlonsalmeron871@gmail.com')
  WITH CHECK (auth.jwt()->>'email' = 'marlonsalmeron871@gmail.com');

-- Note: The "Users can update own posts" policy allows users to update their own posts (content, edited_at)
-- The "Admin can update any post" policy allows admin to pin/edit any post (is_pinned, pinned_at, etc.)
-- Both policies are evaluated with OR logic, so admin can update ANY post while users can only update their own

-- ============================================
-- MEDIA POSTS FEATURE (Image attachments)
-- ============================================

-- Create post_media table for tracking media attachments
CREATE TABLE IF NOT EXISTS post_media (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_size INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on post_media
ALTER TABLE post_media ENABLE ROW LEVEL SECURITY;

-- Media policies
CREATE POLICY "Anyone can view media" ON post_media
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can add media" ON post_media
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Post authors can delete media" ON post_media
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM posts 
      WHERE posts.id = post_media.post_id 
      AND posts.author_id = auth.uid()
    )
  );

-- Add realtime for post_media
ALTER PUBLICATION supabase_realtime ADD TABLE post_media;

-- ============================================
-- STORAGE BUCKET SETUP (Do this in Supabase Dashboard)
-- ============================================
-- 1. Go to Storage in your Supabase Dashboard
-- 2. Create a new bucket called "post-media"
-- 3. Set the bucket to "Public" (required for images to display without auth tokens)
-- 4. Add storage policies in the bucket "Policies" tab:
--
-- Policy 1 - Public Read Access:
--   Name: "Public read access"
--   Allowed operation: SELECT
--   Target roles: anon, authenticated
--   Policy: true
--
-- Policy 2 - Authenticated Upload:
--   Name: "Authenticated users can upload"
--   Allowed operation: INSERT
--   Target roles: authenticated
--   Policy: (bucket_id = 'post-media')
--
-- Policy 3 - Owner Delete:
--   Name: "Users can delete own files"
--   Allowed operation: DELETE
--   Target roles: authenticated
--   Policy: (auth.uid()::text = (storage.foldername(name))[2])
--
-- Note: The folder structure is posts/{user_id}/{filename}
-- This ensures users can only delete their own uploaded files

-- =====================================================
-- PROFILE AVATARS STORAGE BUCKET SETUP
-- =====================================================
-- 
-- STEP 1: Create Avatars Bucket in Supabase Dashboard
-- Go to Storage > Create new bucket
-- 1. Bucket name: avatars
-- 2. Set to "Public"
-- 3. Create bucket
--
-- STEP 2: Add Storage Policies (in Policies tab)
--
-- Policy 1 - Public Read Access:
--   Name: "Public read access for avatars"
--   Allowed operation: SELECT
--   Target roles: anon, authenticated
--   Policy: true
--
-- Policy 2 - Authenticated Upload:
--   Name: "Authenticated users can upload avatars"
--   Allowed operation: INSERT
--   Target roles: authenticated
--   Policy: (bucket_id = 'avatars')
--
-- Policy 3 - Owner Update (with ownership check):
--   Name: "Users can update own files"
--   Allowed operation: UPDATE
--   Target roles: authenticated
--   Policy: (bucket_id = 'avatars' AND auth.uid()::text = split_part(name, '_', 1))
--   Note: This checks that the filename starts with the user's ID
--
-- Policy 4 - Owner Delete (with ownership check):
--   Name: "Users can delete own files"
--   Allowed operation: DELETE
--   Target roles: authenticated
--   Policy: (bucket_id = 'avatars' AND auth.uid()::text = split_part(name, '_', 1))
--   Note: This checks that the filename starts with the user's ID
--
-- IMPORTANT: The file naming convention is: {user_id}_{type}_{timestamp}.{ext}
-- This ensures each user can only modify/delete their own files
--
-- Example file paths:
--   avatars/avatars/abc123-def456_avatar_1704067200.jpg
--   avatars/covers/abc123-def456_cover_1704067200.jpg

-- =============================================
-- NEWSLETTER SUBSCRIBERS
-- =============================================

-- Create newsletter_subscribers table
CREATE TABLE IF NOT EXISTS newsletter_subscribers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  subscribed_at TIMESTAMPTZ DEFAULT NOW(),
  unsubscribed_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE
);

-- Enable RLS
ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;

-- Allow anyone to subscribe (insert)
CREATE POLICY "Anyone can subscribe to newsletter"
ON newsletter_subscribers FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Only service role can read/update/delete subscribers
CREATE POLICY "Service role can manage subscribers"
ON newsletter_subscribers FOR ALL
TO service_role
USING (true)
WITH CHECK (true);
