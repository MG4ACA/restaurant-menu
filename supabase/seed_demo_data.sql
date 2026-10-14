-- ========================================================
-- Lumicore Labs: Demo Account Seed Script
-- Restaurant: The Monarch Reign
-- Owner: demo@lumicore-labs.com / demo123456
-- ========================================================

do $$
declare
  demo_user_id uuid;
  resto_id uuid;
  cat_signatures uuid;
  cat_rice_curry uuid;
  cat_kottu uuid;
  cat_bites uuid;
  cat_desserts uuid;
begin

  -- 1. Ensure user exists in auth.users
  select id into demo_user_id from auth.users where email = 'demo@lumicore-labs.com';

  if demo_user_id is null then
    demo_user_id := gen_random_uuid();
    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      raw_app_meta_data,
      raw_user_meta_data
    )
    values (
      '00000000-0000-0000-0000-000000000000',
      demo_user_id,
      'authenticated',
      'authenticated',
      'demo@lumicore-labs.com',
      crypt('demo123456', gen_salt('bf')),
      now(),
      now(),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{}'
    );
  end if;

  -- 2. Clear old demo data for clean reset
  delete from public.restaurants where owner_id = demo_user_id or slug = 'monarch-reign';

  -- 3. Create Restaurant
  insert into public.restaurants (
    owner_id,
    name,
    slug,
    description,
    phone,
    address,
    is_published
  )
  values (
    demo_user_id,
    'The Monarch Reign',
    'monarch-reign',
    'Premier coastal Sri Lankan dining featuring fresh seafood, claypot curries, and tropical specialties along the Marine Drive.',
    '+94 11 234 5678',
    '42 Marine Drive, Colombo 03, Sri Lanka',
    true
  )
  returning id into resto_id;

  -- 4. Create Categories
  insert into public.categories (restaurant_id, name, sort_order)
  values (resto_id, 'Signatures & Chef Specials', 1)
  returning id into cat_signatures;

  insert into public.categories (restaurant_id, name, sort_order)
  values (resto_id, 'Ceylon Rice & Curries', 2)
  returning id into cat_rice_curry;

  insert into public.categories (restaurant_id, name, sort_order)
  values (resto_id, 'Kottu & Street Roti', 3)
  returning id into cat_kottu;

  insert into public.categories (restaurant_id, name, sort_order)
  values (resto_id, 'Bites & Appetizers', 4)
  returning id into cat_bites;

  insert into public.categories (restaurant_id, name, sort_order)
  values (resto_id, 'Desserts & Tropical Drinks', 5)
  returning id into cat_desserts;

  -- 5. Insert Menu Items
  -- Signatures
  insert into public.menu_items (restaurant_id, category_id, name, description, price, is_available, sort_order)
  values
    (resto_id, cat_signatures, 'Negombo Lagoon Black Pepper Crab', 'Fresh lagoon crab tossed in cracked black peppercorns, garlic, curry leaves, and tempered butter. Served with warm roast paan.', 4500, true, 1),
    (resto_id, cat_signatures, 'Claypot Ceylon Chicken Biryani', 'Slow-cooked fragrant basmati rice layered with spiced chicken, boiled egg, mint sambol, Malay pickle, and raita.', 1850, true, 2),
    (resto_id, cat_signatures, 'Butter Garlic Jumbo Prawns', 'Succulent Indian Ocean prawns sautéed with crushed garlic, lime zest, and herb-infused butter sauce.', 3200, true, 3);

  -- Rice & Curries
  insert into public.menu_items (restaurant_id, category_id, name, description, price, is_available, sort_order)
  values
    (resto_id, cat_rice_curry, 'Village Rice & Curry Feast', 'Red samba rice served with 4 daily vegetable curries, pol sambol, fried sprats, papadam, and dried chilli.', 1450, true, 1),
    (resto_id, cat_rice_curry, 'Jaffna Slow-Cooked Mutton Curry', 'Tender boneless mutton braised in roasted dark roasted curry powder, tamarind, and thick coconut gravy.', 2400, true, 2),
    (resto_id, cat_rice_curry, 'Creamy Dhal Tadka with Coconut Milk', 'Red lentils simmered in rich coconut milk with tempered mustard seeds, onions, garlic, and rampe.', 650, true, 3);

  -- Kottu & Roti
  insert into public.menu_items (restaurant_id, category_id, name, description, price, is_available, sort_order)
  values
    (resto_id, cat_kottu, 'Cheese Kottu with Crispy Chicken', 'Chopped Godamba roti tossed with shredded vegetables, melted cheddar cream sauce, and spicy fried chicken strips.', 1650, true, 1),
    (resto_id, cat_kottu, 'Seafood Roast Paan Platter', 'Crisp local oven roast paan served with devilled calamari, seeni sambol, and thick fish gravy.', 1200, true, 2),
    (resto_id, cat_kottu, 'Egg & Cheese Roti with Pol Sambol', 'Layered griddle flatbread filled with whisked egg, green chilies, and served with freshly scraped coconut sambol.', 750, true, 3);

  -- Bites & Appetizers
  insert into public.menu_items (restaurant_id, category_id, name, description, price, is_available, sort_order)
  values
    (resto_id, cat_bites, 'Crispy Hot Butter Cuttlefish (HBC)', 'The undisputed national favorite: crispy squid rings tossed in seasoned butter, dried chili flakes, and scallions.', 2200, true, 1),
    (resto_id, cat_bites, 'Spiced Ceylon Fish Cutlets (4 Pcs)', 'Deep-fried golden breadcrumb spheres filled with spiced mackerel, mashed potatoes, leeks, and black pepper.', 550, true, 2),
    (resto_id, cat_bites, 'Devilled Crispy Pork', 'Marinated pork belly cubes stir-fried with banana peppers, red onions, tomatoes, and sweet chili reduction.', 1950, true, 3);

  -- Desserts & Drinks
  insert into public.menu_items (restaurant_id, category_id, name, description, price, is_available, sort_order)
  values
    (resto_id, cat_desserts, 'Authentic Kithul Watalappam', 'Rich steamed coconut custard sweetened with pure organic Kithul jaggery, cardamom, nutmeg, and cashew nuts.', 650, true, 1),
    (resto_id, cat_desserts, 'Fresh Woodapple & Treacle Smoothie', 'Blended seasonal woodapple fruit pulp whipped with milk, crushed ice, and drizzled with dark wild bee honey.', 550, true, 2),
    (resto_id, cat_desserts, 'King Coconut & Mint Refresher', 'Chilled fresh Thambili king coconut water served with lime squeeze, crushed mint, and chia seeds.', 450, false, 3); -- Sold out example

  raise notice 'Demo restaurant "The Monarch Reign" successfully seeded for demo@lumicore-labs.com!';
end $$;
