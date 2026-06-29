# Aura Supabase backend

Aura uses Supabase as the backend layer for the first networked version:

- Auth: user identity, display name, avatar.
- Database: profiles, tracks, comments, likes, listening events.
- Storage: future cover/audio uploads.
- Edge Functions: music-provider API keys stay outside the iOS app bundle.

## Setup

1. Create a Supabase project.
2. Apply `supabase/migrations/0001_aura_backend.sql`.
3. Deploy the `music-search` Edge Function.
4. Configure secrets:

```bash
supabase secrets set SOUNDCLOUD_CLIENT_ID=...
supabase secrets set AUDIUS_APP_NAME=Aura
supabase secrets set AUDIUS_DISCOVERY_HOST=https://discoveryprovider.audius.co
```

## iOS config

Add this key to the app Info.plist or build settings when the backend is ready:

```text
AURA_SUPABASE_FUNCTIONS_URL=https://<project-ref>.functions.supabase.co
```

If the key is missing, Aura still works with local tracks, built-in catalogue, and Jamendo.

## Providers

- Jamendo currently remains direct in the app for compatibility.
- Audius and SoundCloud are routed through `music-search`.
- Do not ship downloader tools such as `yt-dlp`, `musicdl`, or Spotify downloaders in the app. They are not legal App Store streaming providers.
