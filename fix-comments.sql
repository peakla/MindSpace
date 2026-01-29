-- FIX: Add missing post_id column to post_comments table
-- Run this in your Supabase SQL Editor

-- Step 1: Drop existing post_comments table (it's missing the post_id column)
DROP TABLE IF EXISTS post_comments CASCADE;

-- Step 2: Recreate with correct schema
CREATE TABLE post_comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  author_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  author_email TEXT NOT NULL,
  author_name TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 3: Enable Row Level Security
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;

-- Step 4: Create RLS policies
CREATE POLICY "Anyone can view comments" ON post_comments
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can comment" ON post_comments
  FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can delete own comments" ON post_comments
  FOR DELETE USING (auth.uid() = author_id);

-- Step 5: Recreate comment count trigger
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

DROP TRIGGER IF EXISTS on_comment_change ON post_comments;
CREATE TRIGGER on_comment_change
  AFTER INSERT OR DELETE ON post_comments
  FOR EACH ROW EXECUTE FUNCTION update_comment_count();

-- Step 6: Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE post_comments;

-- Step 7: Insert seed comments linked to posts
-- Comments on the exam anxiety post
INSERT INTO post_comments (post_id, author_email, author_name, content, created_at)
SELECT posts.id, comments.author_email, comments.author_name, comments.content, comments.created_at
FROM posts
CROSS JOIN (VALUES
  ('team@mindbalance.com', 'MindBalance Team', 'Great question! Remember that everyone''s journey is different.', NOW() - INTERVAL '2 days 2 hours'),
  ('support@mindbalance.com', 'Student Support', 'These tips really work! I''ve been using them for a month now.', NOW() - INTERVAL '2 days 5 hours'),
  ('community@mindbalance.com', 'Community Wellness', 'Thank you for sharing. It helps knowing we''re not alone.', NOW() - INTERVAL '3 days 1 hour')
) AS comments(author_email, author_name, content, created_at)
WHERE posts.content LIKE '%exam anxiety%';

-- Comments on the sleep routine post
INSERT INTO post_comments (post_id, author_email, author_name, content, created_at)
SELECT posts.id, comments.author_email, comments.author_name, comments.content, comments.created_at
FROM posts
CROSS JOIN (VALUES
  ('support@mindbalance.com', 'Student Support', 'The no-screens rule is so important! Blue light really affects sleep quality.', NOW() - INTERVAL '3 days 3 hours'),
  ('team@mindbalance.com', 'MindBalance Team', 'Has anyone tried reading before bed? It works wonders for me!', NOW() - INTERVAL '3 days 6 hours')
) AS comments(author_email, author_name, content, created_at)
WHERE posts.content LIKE '%Best sleep routine%';

-- Comments on the weekly check-in post
INSERT INTO post_comments (post_id, author_email, author_name, content, created_at)
SELECT posts.id, comments.author_email, comments.author_name, comments.content, comments.created_at
FROM posts
CROSS JOIN (VALUES
  ('team@mindbalance.com', 'MindBalance Team', 'Feeling better today! Small wins matter.', NOW() - INTERVAL '4 days 2 hours'),
  ('support@mindbalance.com', 'Student Support', 'Remember to be kind to yourself. Progress isn''t always linear.', NOW() - INTERVAL '4 days 4 hours'),
  ('community@mindbalance.com', 'Community Wellness', 'This community is so supportive. Thank you all!', NOW() - INTERVAL '4 days 8 hours')
) AS comments(author_email, author_name, content, created_at)
WHERE posts.content LIKE '%Weekly check-in%';

-- Comments on the grounding technique post
INSERT INTO post_comments (post_id, author_email, author_name, content, created_at)
SELECT posts.id, comments.author_email, comments.author_name, comments.content, comments.created_at
FROM posts
CROSS JOIN (VALUES
  ('team@mindbalance.com', 'MindBalance Team', 'This technique saved me during my last presentation!', NOW() - INTERVAL '5 days 3 hours'),
  ('community@mindbalance.com', 'Community Wellness', 'I teach this to my friends now. It''s so helpful!', NOW() - INTERVAL '5 days 5 hours')
) AS comments(author_email, author_name, content, created_at)
WHERE posts.content LIKE '%5-4-3-2-1 grounding%';

-- Reset comment counts to match actual comments
UPDATE posts SET comment_count = (
  SELECT COUNT(*) FROM post_comments WHERE post_comments.post_id = posts.id
);
