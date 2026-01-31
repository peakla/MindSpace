-- Add new achievements to expand the badge system (25+ total)
-- Run this in Supabase SQL Editor after the initial setup

INSERT INTO achievements (id, name, description, icon, category, points, criteria) VALUES
  -- Community achievements
  ('ten_posts', 'Prolific Writer', 'Created 10 community posts', 'document-text-outline', 'community', 50, '{"posts": 10}'),
  ('twenty_five_posts', 'Community Pillar', 'Created 25 community posts', 'podium-outline', 'community', 100, '{"posts": 25}'),
  ('ten_comments', 'Conversationalist', 'Left 10 comments', 'chatbubbles-outline', 'community', 25, '{"comments": 10}'),
  ('twenty_five_comments', 'Discussion Leader', 'Left 25 comments', 'megaphone-outline', 'community', 50, '{"comments": 25}'),
  ('hundred_likes', 'Beloved Member', 'Received 100 likes on your posts', 'heart-circle-outline', 'community', 150, '{"likes_received": 100}'),
  
  -- Engagement achievements
  ('two_week_streak', '14 Day Streak', 'Visited MindBalance 14 days in a row', 'calendar-outline', 'engagement', 50, '{"streak": 14}'),
  ('hundred_day_streak', '100 Day Champion', 'Visited MindBalance 100 days in a row', 'medal-outline', 'engagement', 200, '{"streak": 100}'),
  
  -- Reading achievements
  ('five_saves', 'Avid Reader', 'Saved 5 articles', 'library-outline', 'reading', 25, '{"saves": 5}'),
  ('ten_saves', 'Knowledge Seeker', 'Saved 10 articles', 'school-outline', 'reading', 50, '{"saves": 10}'),
  
  -- Wellness achievements
  ('mood_dedicated', 'Mood Dedicated', 'Logged your mood 14 times', 'pulse-outline', 'wellness', 35, '{"mood_logs": 14}'),
  ('mood_master', 'Mood Master', 'Logged your mood 30 times', 'analytics-outline', 'wellness', 75, '{"mood_logs": 30}'),
  ('three_goals', 'Goal Oriented', 'Created 3 wellness goals', 'list-outline', 'wellness', 25, '{"goals": 3}'),
  ('five_goals_complete', 'Goal Champion', 'Completed 5 wellness goals', 'checkmark-done-outline', 'wellness', 100, '{"goals_completed": 5}'),
  
  -- Social achievements (requires followers criteria)
  ('first_follower', 'Making Friends', 'Got your first follower', 'person-add-outline', 'social', 15, '{"followers": 1}'),
  ('five_followers', 'Growing Network', 'Gained 5 followers', 'people-outline', 'social', 40, '{"followers": 5}'),
  ('ten_followers', 'Social Butterfly', 'Gained 10 followers', 'globe-outline', 'social', 75, '{"followers": 10}')
ON CONFLICT (id) DO NOTHING;
