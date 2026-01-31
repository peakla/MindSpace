-- MindBalance Database CLEANUP Script
-- Run this FIRST to drop all existing tables before fresh install
-- Order matters: drop tables with foreign keys first, then parent tables

-- =====================================================
-- STEP 1: DROP ALL TRIGGERS FIRST
-- =====================================================
DROP TRIGGER IF EXISTS on_like_change ON post_likes;
DROP TRIGGER IF EXISTS on_comment_change ON post_comments;

-- =====================================================
-- STEP 2: DROP ALL FUNCTIONS
-- =====================================================
DROP FUNCTION IF EXISTS update_like_count();
DROP FUNCTION IF EXISTS update_comment_count();

-- =====================================================
-- STEP 3: REMOVE TABLES FROM REALTIME PUBLICATION
-- =====================================================
-- (Ignore errors if tables don't exist in publication)
ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS posts;
ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS post_likes;
ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS post_comments;
ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS post_media;

-- =====================================================
-- STEP 4: DROP ALL TABLES (in dependency order)
-- Child tables first, then parent tables
-- =====================================================

-- Drop child/dependent tables first
DROP TABLE IF EXISTS post_media CASCADE;
DROP TABLE IF EXISTS post_reports CASCADE;
DROP TABLE IF EXISTS post_likes CASCADE;
DROP TABLE IF EXISTS post_comments CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS newsletter_subscribers CASCADE;

-- Drop parent tables last
DROP TABLE IF EXISTS posts CASCADE;

-- =====================================================
-- STEP 5: DROP PROFILE-RELATED TABLES
-- =====================================================
DROP TABLE IF EXISTS user_achievements CASCADE;
DROP TABLE IF EXISTS user_activity_logs CASCADE;
DROP TABLE IF EXISTS reading_progress CASCADE;
DROP TABLE IF EXISTS user_engagement CASCADE;
DROP TABLE IF EXISTS wellness_goals CASCADE;
DROP TABLE IF EXISTS mood_entries CASCADE;
DROP TABLE IF EXISTS saved_articles CASCADE;
DROP TABLE IF EXISTS followers CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS resource_suggestions CASCADE;

-- =====================================================
-- DONE! All tables have been dropped.
-- Now run supabase-setup.sql to recreate everything fresh.
-- =====================================================
