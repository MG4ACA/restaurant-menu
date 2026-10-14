-- ============================================
-- Lumicore Labs - Restaurant Menu MVP
-- Migration 001: Initial Schema
-- ============================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================
-- TABLES
-- ============================================

-- Restaurants table
create table public.restaurants (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  slug text not null unique,
  description text,
  phone text,
  address text,
  logo_path text,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Categories table
create table public.categories (
  id uuid primary key default uuid_generate_v4(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- Menu items table
create table public.menu_items (
  id uuid primary key default uuid_generate_v4(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  name text not null,
  description text,
  price integer not null, -- price in LKR cents for precision
  photo_path text, -- path in Supabase Storage
  is_available boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Indexes
create index idx_restaurants_owner on public.restaurants(owner_id);
create index idx_restaurants_slug on public.restaurants(slug);
create index idx_categories_restaurant on public.categories(restaurant_id);
create index idx_menu_items_restaurant on public.menu_items(restaurant_id);
create index idx_menu_items_category on public.menu_items(category_id);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

alter table public.restaurants enable row level security;
alter table public.categories enable row level security;
alter table public.menu_items enable row level security;

-- Restaurants policies
create policy "Owners can view their own restaurants"
  on public.restaurants for select
  to authenticated
  using (owner_id = auth.uid());

create policy "Owners can insert their own restaurants"
  on public.restaurants for insert
  to authenticated
  with check (owner_id = auth.uid());

create policy "Owners can update their own restaurants"
  on public.restaurants for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "Owners can delete their own restaurants"
  on public.restaurants for delete
  to authenticated
  using (owner_id = auth.uid());

create policy "Public can view published restaurants"
  on public.restaurants for select
  to anon, authenticated
  using (is_published = true);

-- Categories policies
create policy "Owners can manage categories of their restaurants"
  on public.categories for all
  to authenticated
  using (
    restaurant_id in (
      select id from public.restaurants where owner_id = auth.uid()
    )
  )
  with check (
    restaurant_id in (
      select id from public.restaurants where owner_id = auth.uid()
    )
  );

create policy "Public can view categories of published restaurants"
  on public.categories for select
  to anon, authenticated
  using (
    restaurant_id in (
      select id from public.restaurants where is_published = true
    )
  );

-- Menu items policies
create policy "Owners can manage items of their restaurants"
  on public.menu_items for all
  to authenticated
  using (
    restaurant_id in (
      select id from public.restaurants where owner_id = auth.uid()
    )
  )
  with check (
    restaurant_id in (
      select id from public.restaurants where owner_id = auth.uid()
    )
  );

create policy "Public can view items of published restaurants"
  on public.menu_items for select
  to anon, authenticated
  using (
    restaurant_id in (
      select id from public.restaurants where is_published = true
    )
  );

-- ============================================
-- STORAGE
-- ============================================
-- Note: Storage bucket and policies must be created via Supabase dashboard
-- or supabase CLI. The bucket name is 'menu-photos'.
--
-- Bucket: menu-photos (public)
--
-- Storage policies to create:
-- 1. "Owners can upload photos" (INSERT):
--    bucket_id = 'menu-photos' AND auth.uid()::text = (storage.foldername(name))[1]
--
-- 2. "Owners can update their photos" (UPDATE):
--    bucket_id = 'menu-photos' AND auth.uid()::text = (storage.foldername(name))[1]
--
-- 3. "Owners can delete their photos" (DELETE):
--    bucket_id = 'menu-photos' AND auth.uid()::text = (storage.foldername(name))[1]
--
-- 4. "Anyone can view photos" (SELECT):
--    bucket_id = 'menu-photos'

-- ============================================
-- HELPER FUNCTION: auto-update updated_at
-- ============================================
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_restaurant_updated
  before update on public.restaurants
  for each row execute function public.handle_updated_at();

create trigger on_menu_item_updated
  before update on public.menu_items
  for each row execute function public.handle_updated_at();
