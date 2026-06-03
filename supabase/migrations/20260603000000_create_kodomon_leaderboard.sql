create table if not exists public.leaderboard (
  id uuid primary key default gen_random_uuid(),
  pet_name text not null check (char_length(pet_name) between 1 and 50),
  total_xp double precision not null default 0 check (total_xp >= 0 and total_xp <= 200000),
  lifetime_xp double precision not null default 0 check (lifetime_xp >= 0 and lifetime_xp <= 500000),
  stage text not null default 'tamago' check (stage in ('tamago', 'kobito', 'kani', 'kamisama')),
  species_id text not null default 'tamago_crab' check (char_length(species_id) between 1 and 64 and species_id ~ '^[a-z0-9_-]+$'),
  current_streak integer not null default 0 check (current_streak >= 0 and current_streak <= 365),
  longest_streak integer not null default 0 check (longest_streak >= 0 and longest_streak <= 365),
  active_days integer not null default 0 check (active_days >= 0 and active_days <= 3650),
  total_commits integer not null default 0 check (total_commits >= 0 and total_commits <= 100000),
  lines_written integer not null default 0 check (lines_written >= 0 and lines_written <= 10000000),
  mood double precision not null default 50 check (mood >= 0 and mood <= 100),
  equipped_accessories text[] not null default '{}',
  active_background text not null default 'none' check (char_length(active_background) <= 30),
  pet_hue double precision not null default 0 check (pet_hue >= 0 and pet_hue <= 1),
  sprite_url text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.leaderboard enable row level security;

revoke insert, update, delete on table public.leaderboard from anon, authenticated;
grant select on table public.leaderboard to anon, authenticated;

drop policy if exists "Public read access" on public.leaderboard;
create policy "Public read access"
  on public.leaderboard
  for select
  to anon, authenticated
  using (true);

create index if not exists idx_kodomon_leaderboard_total_xp on public.leaderboard (total_xp desc, updated_at desc);
create index if not exists idx_kodomon_leaderboard_lifetime_xp on public.leaderboard (lifetime_xp desc, updated_at desc);
create index if not exists idx_kodomon_leaderboard_current_streak on public.leaderboard (current_streak desc, updated_at desc);
create index if not exists idx_kodomon_leaderboard_active_days on public.leaderboard (active_days desc, updated_at desc);
create index if not exists idx_kodomon_leaderboard_lines_written on public.leaderboard (lines_written desc, updated_at desc);
create index if not exists idx_kodomon_leaderboard_species_id on public.leaderboard (species_id);

comment on table public.leaderboard is 'Opt-in Kodomon leaderboard rows. Writes happen through the leaderboard-sync Edge Function; reads are public.';
comment on column public.leaderboard.id is 'Anonymous per-install Kodomon UUID from the macOS app UserDefaults.';
comment on column public.leaderboard.total_xp is 'Active Kodomon species XP retained for v1/v2 compatibility.';
comment on column public.leaderboard.lifetime_xp is 'Player-wide lifetime XP used as the default leaderboard sort.';
comment on column public.leaderboard.species_id is 'Stable species catalog id for rendering the correct leaderboard sprite.';
