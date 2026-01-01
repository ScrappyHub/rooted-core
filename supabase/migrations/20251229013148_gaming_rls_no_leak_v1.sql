-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
begin;

alter table public.gamer_accounts enable row level security;
alter table public.gamer_profiles_public enable row level security;
alter table public.gamer_private_stats enable row level security;

-- Public can read public gamer profiles (no user_id stored here).
do begin;

-- Gamer account is the ONLY identity visible in gaming.
-- It is not linked publicly to provider/vendor/institution identities.
create table if not exists public.gamer_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique, -- 1 gamer account per auth user
  screen_name text not null unique,
  status text not null default 'active', -- active/suspended/etc
  age_lane text not null default 'adult', -- kid/teen/adult (derived/enforced elsewhere)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Public gamer profile: intentionally minimal.
create table if not exists public.gamer_profiles_public (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  display_name text not null, -- usually screen_name copy
  bio text null,
  avatar_url text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Private stats/progress: never public.
create table if not exists public.gamer_private_stats (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  total_play_time_seconds bigint not null default 0,
  save_state jsonb not null default '{}'::jsonb,
  nsfw_activity_hidden boolean not null default true, -- hard safety default
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- timestamps
create or replace function public._touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_accounts_touch') then
    create trigger trg_gamer_accounts_touch
    before update on public.gamer_accounts
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_profiles_public_touch') then
    create trigger trg_gamer_profiles_public_touch
    before update on public.gamer_profiles_public
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_private_stats_touch') then
    create trigger trg_gamer_private_stats_touch
    before update on public.gamer_private_stats
    for each row execute function public._touch_updated_at();
  end if;
end;
$$;

commit;
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_read_v1'
  ) then
    create policy gamer_profiles_public_read_v1
    on public.gamer_profiles_public
    for select
    using (true);
  end if;
end begin;

-- Gamer account is the ONLY identity visible in gaming.
-- It is not linked publicly to provider/vendor/institution identities.
create table if not exists public.gamer_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique, -- 1 gamer account per auth user
  screen_name text not null unique,
  status text not null default 'active', -- active/suspended/etc
  age_lane text not null default 'adult', -- kid/teen/adult (derived/enforced elsewhere)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Public gamer profile: intentionally minimal.
create table if not exists public.gamer_profiles_public (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  display_name text not null, -- usually screen_name copy
  bio text null,
  avatar_url text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Private stats/progress: never public.
create table if not exists public.gamer_private_stats (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  total_play_time_seconds bigint not null default 0,
  save_state jsonb not null default '{}'::jsonb,
  nsfw_activity_hidden boolean not null default true, -- hard safety default
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- timestamps
create or replace function public._touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_accounts_touch') then
    create trigger trg_gamer_accounts_touch
    before update on public.gamer_accounts
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_profiles_public_touch') then
    create trigger trg_gamer_profiles_public_touch
    before update on public.gamer_profiles_public
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_private_stats_touch') then
    create trigger trg_gamer_private_stats_touch
    before update on public.gamer_private_stats
    for each row execute function public._touch_updated_at();
  end if;
end;
$$;

commit;;

-- Owner can manage their gamer profile row.
do begin;

-- Gamer account is the ONLY identity visible in gaming.
-- It is not linked publicly to provider/vendor/institution identities.
create table if not exists public.gamer_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique, -- 1 gamer account per auth user
  screen_name text not null unique,
  status text not null default 'active', -- active/suspended/etc
  age_lane text not null default 'adult', -- kid/teen/adult (derived/enforced elsewhere)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Public gamer profile: intentionally minimal.
create table if not exists public.gamer_profiles_public (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  display_name text not null, -- usually screen_name copy
  bio text null,
  avatar_url text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Private stats/progress: never public.
create table if not exists public.gamer_private_stats (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  total_play_time_seconds bigint not null default 0,
  save_state jsonb not null default '{}'::jsonb,
  nsfw_activity_hidden boolean not null default true, -- hard safety default
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- timestamps
create or replace function public._touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_accounts_touch') then
    create trigger trg_gamer_accounts_touch
    before update on public.gamer_accounts
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_profiles_public_touch') then
    create trigger trg_gamer_profiles_public_touch
    before update on public.gamer_profiles_public
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_private_stats_touch') then
    create trigger trg_gamer_private_stats_touch
    before update on public.gamer_private_stats
    for each row execute function public._touch_updated_at();
  end if;
end;
$$;

commit;
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_owner_write_v1'
  ) then
    create policy gamer_profiles_public_owner_write_v1
    on public.gamer_profiles_public
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end begin;

-- Gamer account is the ONLY identity visible in gaming.
-- It is not linked publicly to provider/vendor/institution identities.
create table if not exists public.gamer_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique, -- 1 gamer account per auth user
  screen_name text not null unique,
  status text not null default 'active', -- active/suspended/etc
  age_lane text not null default 'adult', -- kid/teen/adult (derived/enforced elsewhere)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Public gamer profile: intentionally minimal.
create table if not exists public.gamer_profiles_public (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  display_name text not null, -- usually screen_name copy
  bio text null,
  avatar_url text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Private stats/progress: never public.
create table if not exists public.gamer_private_stats (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  total_play_time_seconds bigint not null default 0,
  save_state jsonb not null default '{}'::jsonb,
  nsfw_activity_hidden boolean not null default true, -- hard safety default
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- timestamps
create or replace function public._touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_accounts_touch') then
    create trigger trg_gamer_accounts_touch
    before update on public.gamer_accounts
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_profiles_public_touch') then
    create trigger trg_gamer_profiles_public_touch
    before update on public.gamer_profiles_public
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_private_stats_touch') then
    create trigger trg_gamer_private_stats_touch
    before update on public.gamer_private_stats
    for each row execute function public._touch_updated_at();
  end if;
end;
$$;

commit;;

-- Gamer accounts: only owner can select/update/insert.
do begin;

-- Gamer account is the ONLY identity visible in gaming.
-- It is not linked publicly to provider/vendor/institution identities.
create table if not exists public.gamer_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique, -- 1 gamer account per auth user
  screen_name text not null unique,
  status text not null default 'active', -- active/suspended/etc
  age_lane text not null default 'adult', -- kid/teen/adult (derived/enforced elsewhere)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Public gamer profile: intentionally minimal.
create table if not exists public.gamer_profiles_public (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  display_name text not null, -- usually screen_name copy
  bio text null,
  avatar_url text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Private stats/progress: never public.
create table if not exists public.gamer_private_stats (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  total_play_time_seconds bigint not null default 0,
  save_state jsonb not null default '{}'::jsonb,
  nsfw_activity_hidden boolean not null default true, -- hard safety default
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- timestamps
create or replace function public._touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_accounts_touch') then
    create trigger trg_gamer_accounts_touch
    before update on public.gamer_accounts
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_profiles_public_touch') then
    create trigger trg_gamer_profiles_public_touch
    before update on public.gamer_profiles_public
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_private_stats_touch') then
    create trigger trg_gamer_private_stats_touch
    before update on public.gamer_private_stats
    for each row execute function public._touch_updated_at();
  end if;
end;
$$;

commit;
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_accounts' and policyname='gamer_accounts_owner_manage_v1'
  ) then
    create policy gamer_accounts_owner_manage_v1
    on public.gamer_accounts
    for all
    using (user_id = auth.uid())
    with check (user_id = auth.uid());
  end if;
end begin;

-- Gamer account is the ONLY identity visible in gaming.
-- It is not linked publicly to provider/vendor/institution identities.
create table if not exists public.gamer_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique, -- 1 gamer account per auth user
  screen_name text not null unique,
  status text not null default 'active', -- active/suspended/etc
  age_lane text not null default 'adult', -- kid/teen/adult (derived/enforced elsewhere)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Public gamer profile: intentionally minimal.
create table if not exists public.gamer_profiles_public (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  display_name text not null, -- usually screen_name copy
  bio text null,
  avatar_url text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Private stats/progress: never public.
create table if not exists public.gamer_private_stats (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  total_play_time_seconds bigint not null default 0,
  save_state jsonb not null default '{}'::jsonb,
  nsfw_activity_hidden boolean not null default true, -- hard safety default
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- timestamps
create or replace function public._touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_accounts_touch') then
    create trigger trg_gamer_accounts_touch
    before update on public.gamer_accounts
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_profiles_public_touch') then
    create trigger trg_gamer_profiles_public_touch
    before update on public.gamer_profiles_public
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_private_stats_touch') then
    create trigger trg_gamer_private_stats_touch
    before update on public.gamer_private_stats
    for each row execute function public._touch_updated_at();
  end if;
end;
$$;

commit;;

-- Private stats: only owner.
do begin;

-- Gamer account is the ONLY identity visible in gaming.
-- It is not linked publicly to provider/vendor/institution identities.
create table if not exists public.gamer_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique, -- 1 gamer account per auth user
  screen_name text not null unique,
  status text not null default 'active', -- active/suspended/etc
  age_lane text not null default 'adult', -- kid/teen/adult (derived/enforced elsewhere)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Public gamer profile: intentionally minimal.
create table if not exists public.gamer_profiles_public (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  display_name text not null, -- usually screen_name copy
  bio text null,
  avatar_url text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Private stats/progress: never public.
create table if not exists public.gamer_private_stats (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  total_play_time_seconds bigint not null default 0,
  save_state jsonb not null default '{}'::jsonb,
  nsfw_activity_hidden boolean not null default true, -- hard safety default
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- timestamps
create or replace function public._touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_accounts_touch') then
    create trigger trg_gamer_accounts_touch
    before update on public.gamer_accounts
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_profiles_public_touch') then
    create trigger trg_gamer_profiles_public_touch
    before update on public.gamer_profiles_public
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_private_stats_touch') then
    create trigger trg_gamer_private_stats_touch
    before update on public.gamer_private_stats
    for each row execute function public._touch_updated_at();
  end if;
end;
$$;

commit;
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_private_stats' and policyname='gamer_private_stats_owner_manage_v1'
  ) then
    create policy gamer_private_stats_owner_manage_v1
    on public.gamer_private_stats
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end begin;

-- Gamer account is the ONLY identity visible in gaming.
-- It is not linked publicly to provider/vendor/institution identities.
create table if not exists public.gamer_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique, -- 1 gamer account per auth user
  screen_name text not null unique,
  status text not null default 'active', -- active/suspended/etc
  age_lane text not null default 'adult', -- kid/teen/adult (derived/enforced elsewhere)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Public gamer profile: intentionally minimal.
create table if not exists public.gamer_profiles_public (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  display_name text not null, -- usually screen_name copy
  bio text null,
  avatar_url text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Private stats/progress: never public.
create table if not exists public.gamer_private_stats (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  total_play_time_seconds bigint not null default 0,
  save_state jsonb not null default '{}'::jsonb,
  nsfw_activity_hidden boolean not null default true, -- hard safety default
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- timestamps
create or replace function public._touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_accounts_touch') then
    create trigger trg_gamer_accounts_touch
    before update on public.gamer_accounts
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_profiles_public_touch') then
    create trigger trg_gamer_profiles_public_touch
    before update on public.gamer_profiles_public
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_private_stats_touch') then
    create trigger trg_gamer_private_stats_touch
    before update on public.gamer_private_stats
    for each row execute function public._touch_updated_at();
  end if;
end;
$$;

commit;;

commit;