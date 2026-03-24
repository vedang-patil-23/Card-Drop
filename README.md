# CardDrop — POPL Alternative

A full-featured digital business card & networking app — iOS (Flutter) + Netlify public profile page.
**Backend: Supabase (PostgreSQL) — 100% free tier.**

---

## 🗂 Project Structure

```
popl_alternative/
├── flutter_app/              ← iOS app (Flutter + Supabase)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── supabase_config.dart     ← paste your credentials here
│   │   ├── theme/
│   │   ├── models/
│   │   ├── services/
│   │   │   ├── supabase_service.dart
│   │   │   ├── profile_service.dart
│   │   │   └── contacts_service.dart
│   │   ├── screens/
│   │   └── widgets/
│   ├── ios/Runner/Info.plist        ← camera/photo permissions
│   └── pubspec.yaml
└── netlify_profile/          ← Public profile web page (React + Vite + Supabase)
    ├── src/
    │   ├── supabase/client.js       ← paste your credentials here
    │   └── components/
    ├── netlify.toml
    └── package.json
```

---

## ✅ Features

| Feature | Status |
|---|---|
| Digital profile card (photo, bio, links) | ✅ |
| 8 card color themes | ✅ |
| 12 social platform links | ✅ |
| QR code generation | ✅ |
| QR code scanning (camera) | ✅ |
| Contact wallet (save scanned contacts) | ✅ |
| vCard / .vcf export | ✅ |
| Lead capture form (in-app) | ✅ |
| Lead capture form (web page) | ✅ |
| Analytics dashboard + 30-day chart | ✅ |
| Public Netlify profile page | ✅ |
| "Save Contact" on web page | ✅ |
| Supabase real-time sync | ✅ |
| No sign-in required | ✅ |
| Dark sleek UI | ✅ |

---

## 🚀 Setup Guide

### Step 1 — Create Supabase Project

1. Go to [supabase.com](https://supabase.com) → **New project**
2. Name it (e.g. `carddrop`) and set a database password
3. Wait ~1 min for provisioning

---

### Step 2 — Create Database Tables

In your Supabase project → **SQL Editor** → paste and run:

```sql
-- Profiles
CREATE TABLE profiles (
  id            UUID PRIMARY KEY,
  display_name  TEXT DEFAULT '',
  job_title     TEXT DEFAULT '',
  company       TEXT DEFAULT '',
  bio           TEXT DEFAULT '',
  email         TEXT DEFAULT '',
  phone         TEXT DEFAULT '',
  website       TEXT DEFAULT '',
  photo_url     TEXT DEFAULT '',
  profile_color TEXT DEFAULT '#6C63FF',
  social_links  JSONB DEFAULT '[]'::jsonb,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Leads
CREATE TABLE leads (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  name             TEXT DEFAULT '',
  email            TEXT DEFAULT '',
  phone            TEXT DEFAULT '',
  organization     TEXT DEFAULT '',
  note             TEXT DEFAULT '',
  source           TEXT DEFAULT 'app',
  captured_at      TIMESTAMPTZ DEFAULT NOW(),
  is_new           BOOLEAN DEFAULT TRUE
);

-- Contacts (saved from scanning)
CREATE TABLE contacts (
  id               UUID PRIMARY KEY,
  owner_profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  profile_id       UUID,
  display_name     TEXT DEFAULT '',
  job_title        TEXT DEFAULT '',
  company          TEXT DEFAULT '',
  email            TEXT DEFAULT '',
  phone            TEXT DEFAULT '',
  website          TEXT DEFAULT '',
  photo_url        TEXT DEFAULT '',
  profile_color    TEXT DEFAULT '#6C63FF',
  saved_at         TIMESTAMPTZ DEFAULT NOW(),
  note             TEXT DEFAULT ''
);

-- Profile views (analytics)
CREATE TABLE profile_views (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  source     TEXT DEFAULT 'qr',
  country    TEXT DEFAULT '',
  viewed_at  TIMESTAMPTZ DEFAULT NOW()
);
```

---

### Step 3 — Enable Row Level Security (RLS)

Run this in SQL Editor to allow public read/write (no auth required):

```sql
-- Allow all operations on each table (no auth app)
ALTER TABLE profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads        ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts     ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public access" ON profiles      FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public access" ON leads         FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public access" ON contacts      FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public access" ON profile_views FOR ALL USING (true) WITH CHECK (true);
```

---

### Step 4 — Create Storage Bucket

1. Supabase dashboard → **Storage** → **New bucket**
2. Name: `profile-photos`
3. Check ✅ **Public bucket**
4. In SQL Editor, add storage policy:

```sql
CREATE POLICY "public access" ON storage.objects
  FOR ALL USING (bucket_id = 'profile-photos')
  WITH CHECK (bucket_id = 'profile-photos');
```

---

### Step 5 — Get Your API Credentials

Supabase dashboard → **Settings** → **API**:
- Copy **Project URL** (looks like `https://abcdef.supabase.co`)
- Copy **anon public** key

---

### Step 6 — Configure Flutter App

Paste into `flutter_app/lib/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url     = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String anonKey = 'YOUR_ANON_PUBLIC_KEY';
}
```

Then install packages and run:

```bash
cd flutter_app
flutter pub get
flutter run
```

---

### Step 7 — Deploy Netlify Profile Page

1. Paste credentials into `netlify_profile/src/supabase/client.js`:

```js
const SUPABASE_URL      = 'https://YOUR_PROJECT_ID.supabase.co'
const SUPABASE_ANON_KEY = 'YOUR_ANON_PUBLIC_KEY'
```

2. Push `netlify_profile/` to a GitHub repo
3. Go to [app.netlify.com](https://app.netlify.com) → **Add new site → Import from Git**
4. Build settings (auto-detected):
   - **Build command:** `npm run build`
   - **Publish directory:** `dist`
5. Deploy and copy your URL (e.g. `https://carddrop.netlify.app`)

---

### Step 8 — Connect Netlify URL to Flutter

In `flutter_app/lib/services/profile_service.dart`:

```dart
static const String netlifyBaseUrl = 'https://YOUR-SITE.netlify.app';
```

Re-run the Flutter app — your QR codes now point to the live Netlify page!

---

## 📱 App Screens

| Screen | Description |
|---|---|
| **Card** | Your digital card, share & copy link |
| **QR** | Your QR code + live camera scanner |
| **Contacts** | Saved contacts (swipe to delete, vCard export) |
| **Leads** | Capture leads form + leads inbox with "New" badges |
| **Analytics** | Views chart, stats, source breakdown |

---

## 🌐 Public Profile Web Page

When someone scans your QR code:

- Full profile card (photo, name, bio, social links)
- **"Save Contact"** → downloads `.vcf` file
- **"Share My Info"** → lead capture form → syncs to your Leads tab
- Mobile-responsive, dark design, hosted free on Netlify

URL format: `https://your-site.netlify.app/profile/{uuid}`

---

## 🛠 Tech Stack

| Layer | Tech | Cost |
|---|---|---|
| Mobile App | Flutter 3 (Dart) — iOS | Free |
| Database | Supabase (PostgreSQL) | Free tier |
| Storage | Supabase Storage | Free tier |
| QR Generate | qr_flutter | Free |
| QR Scan | mobile_scanner | Free |
| Charts | fl_chart | Free |
| Public Page | React 18 + Vite | Free |
| Hosting | Netlify | Free tier |
| Fonts | Google Fonts — Inter | Free |

---

## 💡 Roadmap

- [ ] NFC tap sharing (iOS Core NFC)
- [ ] CSV export of leads
- [ ] Multiple profiles per device
- [ ] Team / business accounts
- [ ] Push notifications for new leads
- [ ] Apple Sign-In for App Store submission
