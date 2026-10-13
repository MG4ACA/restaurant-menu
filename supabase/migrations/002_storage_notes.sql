-- ============================================
-- Migration 002: Storage Bucket Setup Notes
-- ============================================
-- Supabase Storage bucket and policies cannot be created via SQL migrations
-- in the standard way. Use the Supabase Dashboard or CLI instead.
--
-- The instructions below describe what to configure manually in your
-- Supabase project after running migration 001.
--
-- ============================================
-- BUCKET CONFIGURATION
-- ============================================
--
-- 1. Go to: Supabase Dashboard > Storage > New bucket
--    Name:        menu-photos
--    Public:      YES (allows public image URL access)
--    File size limit: 5242880  (5 MB)
--    Allowed MIME types: image/jpeg, image/png, image/webp
--
-- ============================================
-- STORAGE RLS POLICIES (via SQL editor or Dashboard)
-- ============================================
--
-- Run these in the Supabase SQL editor AFTER creating the bucket:

-- Policy 1: Authenticated owners can upload to their own folder
-- INSERT policy on storage.objects:
--   bucket_id = 'menu-photos'
--   AND auth.role() = 'authenticated'
--   AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy 2: Owners can update (replace) photos in their own folder
-- UPDATE policy on storage.objects:
--   bucket_id = 'menu-photos'
--   AND auth.role() = 'authenticated'
--   AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy 3: Owners can delete photos from their own folder
-- DELETE policy on storage.objects:
--   bucket_id = 'menu-photos'
--   AND auth.role() = 'authenticated'
--   AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy 4: Anyone (public) can read photos from the bucket
-- SELECT policy on storage.objects:
--   bucket_id = 'menu-photos'

-- ============================================
-- QUICK SQL COPY-PASTE (for SQL editor):
-- ============================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'menu-photos',
  'menu-photos',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

CREATE POLICY "owner upload" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'menu-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "owner update" ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'menu-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "owner delete" ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'menu-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "public read" ON storage.objects FOR SELECT TO anon, authenticated
USING (bucket_id = 'menu-photos');
