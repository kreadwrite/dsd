create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Listener',
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.tracks (
  id uuid primary key default gen_random_uuid(),
  source text not null,
  source_id text,
  title text not null,
  artist text not null,
  genre text,
  duration integer not null default 0,
  artwork_url text,
  stream_url text not null,
  lyrics text,
  owner_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  track_id text not null,
  user_id uuid references public.profiles(id) on delete set null,
  parent_id uuid references public.comments(id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.track_likes (
  user_id uuid not null references public.profiles(id) on delete cascade,
  track_id text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, track_id)
);

create table if not exists public.comment_likes (
  user_id uuid not null references public.profiles(id) on delete cascade,
  comment_id uuid not null references public.comments(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, comment_id)
);

create table if not exists public.listening_events (
  id bigint generated always as identity primary key,
  user_id uuid references public.profiles(id) on delete set null,
  track_id text not null,
  genre text,
  seconds integer not null check (seconds > 0),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.tracks enable row level security;
alter table public.comments enable row level security;
alter table public.track_likes enable row level security;
alter table public.comment_likes enable row level security;
alter table public.listening_events enable row level security;

create policy "profiles readable" on public.profiles for select using (true);
create policy "own profile update" on public.profiles for update using (auth.uid() = id);

create policy "tracks readable" on public.tracks for select using (true);
create policy "own tracks write" on public.tracks for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create policy "comments readable" on public.comments for select using (true);
create policy "signed comments insert" on public.comments for insert with check (auth.uid() = user_id);
create policy "own comments update" on public.comments for update using (auth.uid() = user_id);
create policy "own comments delete" on public.comments for delete using (auth.uid() = user_id);

create policy "likes readable" on public.track_likes for select using (true);
create policy "own track likes" on public.track_likes for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "comment likes readable" on public.comment_likes for select using (true);
create policy "own comment likes" on public.comment_likes for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own listening events" on public.listening_events for insert with check (auth.uid() = user_id or user_id is null);
