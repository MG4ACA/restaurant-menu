-- ============================================
-- Migration 004: Add Logo Column to Restaurants
-- ============================================

alter table public.restaurants 
add column if not exists logo_path text;
