# Lumicore Menu — Smart Digital Menu for Restaurants

A modern digital menu platform for Sri Lankan restaurants. Restaurant owners manage their menu from a dashboard. Customers open a live menu by scanning a QR code or tapping an NFC tag — no app required.

**Stack:** Nuxt 3 · Nuxt UI v4 · Tailwind CSS v4 · Supabase (Postgres, Auth, Storage)

---

## Features

### Owner Dashboard
- Restaurant profile (name, slug, description, phone, address, publish toggle)
- Category management (add, rename, delete)
- Menu item management (name, description, price in LKR, photo, availability)
- Photo upload, replace and remove per item
- One-click mark item sold out / available
- QR code generation and download (PNG)
- Public menu preview link

### Public Menu (`/menu/:slug`)
- No login required — works for anyone with the URL, QR code, or NFC tag
- Mobile-first layout with sticky category navigation
- Sold-out items clearly labelled and dimmed
- Prices shown as **Rs. 1,250** format
- SSR rendered for fast first load

---

## Local Development

### Prerequisites
- Node.js 20+
- npm 10+
- A Supabase project (free tier works)

### Setup

```bash
# 1. Clone and install
git clone <repo-url>
cd restaurant-menu
npm install

# 2. Configure environment
cp .env.example .env
# Edit .env — fill in your Supabase URL and anon key

# 3. Apply database migrations (see Supabase Setup below)

# 4. Start dev server
npm run dev
```

App runs at **http://localhost:3000**

---

## Environment Variables

| Variable | Description |
|---|---|
| `NUXT_PUBLIC_SUPABASE_URL` | Your Supabase project URL (e.g. `https://abc.supabase.co`) |
| `NUXT_PUBLIC_SUPABASE_ANON_KEY` | Your Supabase **anon/public** key |

> ⚠️ **Never** use the service role key in the frontend. RLS policies enforce all access control.

Copy `.env.example` to `.env` and fill in real values. `.env` is gitignored.

---

## Supabase Project Setup

### 1. Create a project
Go to [supabase.com](https://supabase.com) → New project. Choose a region close to Sri Lanka (Singapore or Mumbai).

### 2. Apply database migrations

Open the **SQL editor** in your Supabase dashboard and run the migration files in order:

```
supabase/migrations/001_initial_schema.sql
```

This creates:
- `restaurants`, `categories`, `menu_items` tables
- All Row Level Security (RLS) policies
- Auto-update trigger for `updated_at`

### 3. Configure Storage

In the Supabase Dashboard → **Storage**:

1. Create a new bucket named **`menu-photos`**
   - Set **Public** = ON
   - File size limit: `5242880` (5 MB)
   - Allowed MIME types: `image/jpeg, image/png, image/webp`

2. Open the **SQL editor** and paste the storage policies from `supabase/migrations/002_storage_notes.sql` (the uncommented SQL at the bottom of that file).

### 4. Get your API keys

Supabase Dashboard → **Settings** → **API**:
- Copy **Project URL** → `NUXT_PUBLIC_SUPABASE_URL`
- Copy **anon / public** key → `NUXT_PUBLIC_SUPABASE_ANON_KEY`

---

## Creating the First Owner Account

Owner sign-up is **invite-only** in this MVP. To create the first account:

### Option A: Supabase Dashboard (recommended)

1. Go to Supabase Dashboard → **Authentication** → **Users**
2. Click **Invite user**
3. Enter the owner's email address
4. The owner receives an email with a magic link to set their password

### Option B: SQL (for testing only)

In the Supabase SQL editor:
```sql
-- This creates a user directly — use only for development
select * from auth.users; -- check existing users
```

Or use the Supabase CLI:
```bash
supabase auth admin create-user --email owner@restaurant.com --password securepassword123
```

### Connecting a user to a restaurant

After the owner signs in for the first time at `/login`, the dashboard will prompt them to create their restaurant profile. The restaurant is automatically linked to their Supabase user ID via `owner_id`.

---

## Available Routes

| Route | Description | Auth |
|---|---|---|
| `/` | Redirects to dashboard or login | — |
| `/login` | Owner sign-in | No |
| `/dashboard` | Owner menu management | ✅ Required |
| `/menu/:slug` | Public customer menu | No |

---

## Database Schema

```
auth.users (managed by Supabase Auth)
  └── restaurants (owner_id → auth.users.id)
        ├── categories (restaurant_id)
        └── menu_items (restaurant_id, category_id)

Storage: menu-photos/{user_id}/{restaurant_id}/{item_id}.{ext}
```

### RLS Summary

| Table | Authenticated owner | Anonymous public |
|---|---|---|
| `restaurants` | Full CRUD (own restaurant only) | SELECT if `is_published = true` |
| `categories` | Full CRUD (own restaurant only) | SELECT if restaurant is published |
| `menu_items` | Full CRUD (own restaurant only) | SELECT if restaurant is published |

---

## Deployment

### Vercel (recommended)

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

Set environment variables in Vercel project settings:
- `NUXT_PUBLIC_SUPABASE_URL`
- `NUXT_PUBLIC_SUPABASE_ANON_KEY`

### Netlify

```bash
npm run build
# Upload .output/public to Netlify
# Or use Netlify CLI: netlify deploy --prod
```

For SSR (recommended), use the Nuxt Netlify preset:
```bash
NITRO_PRESET=netlify npm run build
```

### Node.js server

```bash
npm run build
node .output/server/index.mjs
```

---

## Scripts

| Command | Description |
|---|---|
| `npm run dev` | Start dev server on port 3000 |
| `npm run build` | Build for production |
| `npm run preview` | Preview production build locally |
| `npm run lint` | Run ESLint |
| `npm run typecheck` | Run TypeScript type checking |

---

## Known Limitations (MVP)

- **One restaurant per owner** — each Supabase user can create one restaurant
- **No item re-ordering via drag-and-drop** — sort order is set at creation time
- **Storage policies** require manual setup via Supabase Dashboard (SQL migration only documents the steps)
- **No email templates** customised — uses Supabase default invite emails
- **No analytics** — page views, scan counts etc. are out of scope for MVP
- **No multiple languages** — English only

---

## What Works

✅ Owner authentication (email + password)  
✅ Restaurant profile create & edit  
✅ Publish / unpublish toggle  
✅ Category CRUD  
✅ Menu item CRUD with photo upload  
✅ Mark items sold out / available  
✅ QR code generation and download  
✅ Public menu at `/menu/:slug`  
✅ RLS on all database tables  
✅ Storage upload scoped to owner folder  
✅ Version-controlled SQL migrations  
✅ Environment-variable based config  

## What Remains Before Production

- [ ] Apply migrations and storage policies to your Supabase project
- [ ] Customise Supabase auth email templates with your branding
- [ ] Set up a custom domain
- [ ] Add CORS/CSP headers for production
- [ ] Load test with realistic menu sizes

---

*Built with [Nuxt](https://nuxt.com) · [Nuxt UI](https://ui.nuxt.com) · [Supabase](https://supabase.com)*
