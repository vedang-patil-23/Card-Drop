# CardDrop

Open-source digital business card app. Create your card, share via QR or link, capture contacts at events, and track who viewed your profile.

Flutter (iOS/macOS) + Supabase + Netlify. Entirely free tier.

---

## Features

- Profile card with photo, bio, job title, company
- 12 social platforms (LinkedIn, Instagram, Twitter, GitHub, etc.)
- QR code sharing — online (link) or offline (embedded vCard)
- Public profile page hosted on Netlify
- Contact management with event categorization
- Swipe right to delete, swipe left to archive
- XLSX export — all contacts or filtered by event
- Visitor analytics — total views, devices, contact saves
- In-app card preview
- vCard file sharing for offline use
- Dark minimal UI

---

## Project Structure

```
flutter_app/            # iOS/macOS app (Flutter)
  lib/
    models/             # LeadModel, EventModel, ProfileModel, etc.
    services/           # SupabaseService, ProfileService
    screens/            # Home, Contacts, Share, Settings, Analytics, etc.
    widgets/            # ProfileCardWidget
    theme/              # AppTheme, colors
    supabase_config.dart  # Your credentials here

netlify_profile/        # Public profile web page (React + Vite)
  src/
    components/         # ProfilePage.jsx
    supabase/           # client.js
  .env.example          # Credential template

supabase/migrations/    # SQL migrations
```

---

## Setup

### 1. Supabase

Create a project at [supabase.com](https://supabase.com), then run in SQL Editor:

```sql
CREATE TABLE profiles (
  id            TEXT PRIMARY KEY,
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

CREATE TABLE leads (
  id               TEXT PRIMARY KEY,
  owner_profile_id TEXT NOT NULL,
  name             TEXT DEFAULT '',
  email            TEXT DEFAULT '',
  phone            TEXT DEFAULT '',
  organization     TEXT DEFAULT '',
  note             TEXT DEFAULT '',
  source           TEXT DEFAULT 'app',
  captured_at      TIMESTAMPTZ DEFAULT NOW(),
  is_new           BOOLEAN DEFAULT TRUE,
  event_id         TEXT DEFAULT '',
  archived         BOOLEAN DEFAULT FALSE
);

CREATE TABLE events (
  id               TEXT PRIMARY KEY,
  owner_profile_id TEXT NOT NULL,
  name             TEXT NOT NULL,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE profile_views (
  id             TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id     TEXT NOT NULL,
  source         TEXT DEFAULT 'qr',
  country        TEXT DEFAULT '',
  viewed_at      TIMESTAMPTZ DEFAULT NOW(),
  ip_address     TEXT DEFAULT '',
  device_name    TEXT DEFAULT '',
  user_agent     TEXT DEFAULT '',
  contact_saved  BOOLEAN DEFAULT FALSE
);

CREATE TABLE contacts (
  id               TEXT PRIMARY KEY,
  owner_profile_id TEXT NOT NULL,
  profile_id       TEXT,
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

ALTER TABLE profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads         ENABLE ROW LEVEL SECURITY;
ALTER TABLE events        ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts      ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "open" ON profiles      FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "open" ON leads         FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "open" ON events        FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "open" ON contacts      FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "open" ON profile_views FOR ALL USING (true) WITH CHECK (true);
```

Create a storage bucket named `profile-photos` (public), then:

```sql
CREATE POLICY "public access" ON storage.objects
  FOR ALL USING (bucket_id = 'profile-photos')
  WITH CHECK (bucket_id = 'profile-photos');
```

### 2. Flutter App

Edit `flutter_app/lib/supabase_config.dart` with your credentials:

```dart
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT.supabase.co';
  static const String anonKey = 'YOUR_ANON_KEY';
  static const String netlifyBaseUrl = 'https://YOUR_SITE.netlify.app';
}
```

Also update the Netlify URL in `flutter_app/lib/services/profile_service.dart`.

```bash
cd flutter_app
flutter pub get
flutter run
```

### 3. Netlify Profile Page

```bash
cd netlify_profile
cp .env.example .env
# Fill in your Supabase URL and anon key
npm install
npm run dev
```

Deploy to Netlify: build command `npm run build`, publish directory `dist`. Add the env vars from `.env` in Netlify dashboard.

---

## How It Works

1. Create a profile in the app with your info and social links
2. Share your QR code or link with someone
3. They see your public profile page on Netlify
4. They can save your contact (downloads .vcf) or share their info back
5. You see the view in Analytics and their details in Contacts
6. Categorize contacts by event and export to XLSX

---

## Tech Stack

| | |
|---|---|
| App | Flutter 3 (iOS/macOS) |
| Database | Supabase (PostgreSQL) |
| Storage | Supabase Storage |
| Public Page | React 18 + Vite |
| Hosting | Netlify |
| QR | qr_flutter |
| Charts | fl_chart |
| Export | excel (XLSX) |

All free tier.

---

## License

MIT
