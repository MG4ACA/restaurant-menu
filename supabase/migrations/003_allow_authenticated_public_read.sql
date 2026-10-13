-- ============================================
-- Migration 003: Allow Authenticated Users to Read Published Menus
-- ============================================
-- By default, "to anon" only applies when unauthenticated.
-- Adding "to anon, authenticated" ensures logged-in owners/users can also
-- view any published public menu URL without permission errors.

drop policy if exists "Public can view published restaurants" on public.restaurants;
create policy "Public can view published restaurants"
  on public.restaurants for select
  to anon, authenticated
  using (is_published = true);

drop policy if exists "Public can view categories of published restaurants" on public.categories;
create policy "Public can view categories of published restaurants"
  on public.categories for select
  to anon, authenticated
  using (
    restaurant_id in (
      select id from public.restaurants where is_published = true
    )
  );

drop policy if exists "Public can view items of published restaurants" on public.menu_items;
create policy "Public can view items of published restaurants"
  on public.menu_items for select
  to anon, authenticated
  using (
    restaurant_id in (
      select id from public.restaurants where is_published = true
    )
  );
