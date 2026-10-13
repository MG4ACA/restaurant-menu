# 🚀 Hostinger VPS Deployment Guide

## Lumicore Labs — Smart Digital Menu (Static SPA + Supabase)

- **Domain/Subdomain:** `demo-menu.lumicore-labs.com`
- **Frontend Stack:** Nuxt 4 (Static SPA Mode)
- **Backend / Database:** Cloud Supabase (PostgreSQL + Auth + Storage)
- **Hosting Strategy:** Pre-built locally in `dist/` → committed to Git → served via **Nginx** on your Hostinger VPS.
- **Node.js on VPS:** **Not required!** Since the app is built locally and served as static files via Nginx, your VPS's Node.js version (Node 22) will **never cause conflicts**.

---

## 🎯 Architecture Overview

```
┌────────────────────────────────────────────────────────┐
│             Hostinger VPS Server                       │
│                                                        │
│   ┌──────────────────────────────────────────────┐    │
│   │  Nginx Web Server (Port 80 / 443 SSL)        │    │
│   │  server_name demo-menu.lumicore-labs.com      │    │
│   └──────────────────────┬───────────────────────┘    │
│                          │                             │
│   ┌──────────────────────▼───────────────────────┐    │
│   │  Static Files (/var/www/restaurant-menu/dist)│    │
│   │  HTML / JS Chunks / CSS / Fonts              │    │
│   └──────────────────────────────────────────────┘    │
└──────────────────────────┬─────────────────────────────┘
                           │ (Direct client HTTPS calls)
                           ▼
            ┌──────────────────────────────┐
            │  Cloud Supabase Backend      │
            │  - Auth (Owners)             │
            │  - PostgreSQL Database       │
            │  - Image Storage             │
            └──────────────────────────────┘
```

---

## 📋 Prerequisites

1. **Hostinger VPS** with Ubuntu 22.04 (or any Linux distribution).
2. **DNS Record Set**:
   - Add an **A Record** in your DNS provider (Cloudflare, Hostinger DNS, etc.):
     - **Host / Name:** `demo-menu`
     - **Points to / Value:** `<YOUR_VPS_IP>`
     - **TTL:** Auto or 3600
3. **Local Machine**:
   - Node.js installed locally to run `npm run generate`.

---

## 📦 Step 1: Build Locally & Commit to Git

Before touching the server, generate the static build on your local machine and push to your Git repository:

```bash
# 1. Generate the static production build (outputs to dist/)
npm run generate

# 2. Stage and commit all changes including dist/
git add .
git commit -m "chore: build static production files in dist/"

# 3. Push to your GitHub / Git repository
git push origin main
```

*(Note: `.gitignore` has already been configured to allow tracking `dist/`).*

---

## 🔧 Step 2: Connect to Your VPS

Open your terminal or PowerShell and connect to your VPS:

```bash
ssh root@<YOUR_VPS_IP>
```

---

## 📁 Step 3: Set Up Project Directory on VPS

### 3.1 Install Git & Nginx (if not already installed)

```bash
sudo apt update
sudo apt install -y git nginx
```

### 3.2 Create Directory & Clone Repository

```bash
# Create web root
sudo mkdir -p /var/www/restaurant-menu
cd /var/www/restaurant-menu

# Clone your repository (replace with your repository URL)
sudo git clone <YOUR_GIT_REPOSITORY_URL> .

# Set ownership and permissions so Nginx can read the files
sudo chown -R www-data:www-data /var/www/restaurant-menu
sudo chmod -R 755 /var/www/restaurant-menu
```

---

## 🌐 Step 4: Configure Nginx for `demo-menu.lumicore-labs.com`

### 4.1 Create the Nginx Server Configuration

```bash
sudo nano /etc/nginx/sites-available/demo-menu.lumicore-labs.com
```

Paste the following configuration:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name demo-menu.lumicore-labs.com;

    # Point directly to the pre-built dist folder
    root /var/www/restaurant-menu/dist;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Gzip Compression for fast mobile loading
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml
        image/svg+xml
        font/woff2;

    # SPA routing: fallback all non-file routes to index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache immutable static assets (JavaScript, CSS, fonts)
    location ~* \.(js|css|woff|woff2|ttf|eot|svg|png|jpg|jpeg|gif|ico|webp)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # Disable access logs for favicon and robots.txt
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
    location = /robots.txt {
        log_not_found off;
        access_log off;
    }
}
```

Save and exit (`Ctrl + O`, `Enter`, `Ctrl + X`).

### 4.2 Enable the Site & Test Nginx

```bash
# Enable the site configuration
sudo ln -sf /etc/nginx/sites-available/demo-menu.lumicore-labs.com /etc/nginx/sites-enabled/

# Test Nginx syntax
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

You should see:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

---

## 🔒 Step 5: Install Free SSL Certificate (Certbot)

Ensure your DNS A record (`demo-menu.lumicore-labs.com`) is pointing to your VPS IP before running this step.

```bash
# 1. Install Certbot for Nginx
sudo apt install -y certbot python3-certbot-nginx

# 2. Obtain and automatically install the SSL certificate
sudo certbot --nginx -d demo-menu.lumicore-labs.com
```

- Enter your email when prompted.
- Accept terms of service.
- Choose whether to redirect HTTP to HTTPS (**Recommended: Yes / 2**).

### Verify Auto-Renewal:
```bash
sudo certbot renew --dry-run
```

---

## 🚀 Step 6: Easy Future Updates (Deployment Script)

Whenever you make changes to the app, you just need to:
1. Locally run `npm run generate`
2. Commit and push to Git
3. Run `git pull` on the VPS

To automate this on the VPS, create a simple script:

```bash
sudo nano /var/www/restaurant-menu/deploy.sh
```

Paste:

```bash
#!/bin/bash
set -e

echo "🚀 Deploying Lumicore Menu to demo-menu.lumicore-labs.com..."

cd /var/www/restaurant-menu

# Pull latest pre-built files
git pull origin main

# Fix permissions
sudo chown -R www-data:www-data /var/www/restaurant-menu/dist
sudo chmod -R 755 /var/www/restaurant-menu/dist

# Reload Nginx cache
sudo systemctl reload nginx

echo "✅ Deployment successful! Visit https://demo-menu.lumicore-labs.com"
```

Make it executable:

```bash
sudo chmod +x /var/www/restaurant-menu/deploy.sh
```

Now, whenever you want to update the live site:
```bash
# On your VPS, simply run:
/var/www/restaurant-menu/deploy.sh
```

---

## 🛠️ Verification & Troubleshooting

### 1. Test Application in Browser
Open:
- `https://demo-menu.lumicore-labs.com/login` (Owner Portal)
- `https://demo-menu.lumicore-labs.com/dashboard`
- `https://demo-menu.lumicore-labs.com/menu/<your-slug>` (Customer Mobile View)

### 2. View Nginx Logs (If issues arise)
```bash
# Check error logs
sudo tail -f /var/log/nginx/error.log

# Check access logs
sudo tail -f /var/log/nginx/access.log
```

### 3. Check Nginx Status
```bash
sudo systemctl status nginx
```
