-- Run this in your Supabase SQL editor (Dashboard → SQL Editor → New query)
-- Adds visitor tracking columns to profile_views table

ALTER TABLE profile_views
  ADD COLUMN IF NOT EXISTS ip_address  TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS device_name TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS user_agent  TEXT DEFAULT '';
