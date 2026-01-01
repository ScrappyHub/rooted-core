-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
begin;

-- -----------------------------
-- Identity isolation tables
-- -----------------------------
create table if not exists public.gamer_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique,               -- 1 gamer account per auth user
  screen_name text not null unique,           -- public-facing identity
  status text not null default 'active',      -- active/suspended/etc
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- public gamer profile: only safe fields (NO user_id, NO linkage)
create table if not exists public.gamer_profiles_public (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  display_name text not null,
  bio text null,
  avatar_url text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- private stats/progress: only user can see
create table if not exists public.gamer_private_stats (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  total_play_time_seconds bigint not null default 0,
  save_state jsonb not null default '{}'::jsonb,
  nsfw_activity_hidden boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- touch helper
create or replace function public._touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname='trg_gamer_accounts_touch') then
    create trigger trg_gamer_accounts_touch before update on public.gamer_accounts
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname='trg_gamer_profiles_public_touch') then
    create trigger trg_gamer_profiles_public_touch before update on public.gamer_profiles_public
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname='trg_gamer_private_stats_touch') then
    create trigger trg_gamer_private_stats_touch before update on public.gamer_private_stats
    for each row execute function public._touch_updated_at();
  end if;
end;
$$;

-- -----------------------------
-- RLS: no leakage, strict visibility
-- -----------------------------
alter table public.gamer_accounts enable row level security;
alter table public.gamer_profiles_public enable row level security;
alter table public.gamer_private_stats enable row level security;

-- Public can read public gamer profiles only
do $$
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
end;
$$;

-- Owner can manage their gamer_profiles_public row
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_owner_manage_v1'
  ) then
    create policy gamer_profiles_public_owner_manage_v1
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
end;
$$;

-- Only owner can access gamer_accounts
do $$
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
end;
$$;

-- Only owner can access gamer_private_stats
do $$
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
end;
$$;

-- -----------------------------
-- NSFW gating helpers (verified + explicit opt-in)
-- Default OFF unless BOTH are ON:
--  - consent_type='adult_verified'
--  - consent_type='nsfw_opt_in'
-- You will additionally enforce "18.5" via your existing age rules pipeline.
-- -----------------------------
create or replace function public._consent_is_on(p_status text)
returns boolean
language sql
stable
as $$
  select coalesce(lower(p_status) in ('on','granted','accepted','true','enabled','verified','approved'), false);
$$;

create or replace function public.nsfw_opt_in_enabled(p_user_id uuid)
returns boolean
language sql
stable
as $$
  select
    exists (
      select 1 from public.user_consents c
      where c.user_id = p_user_id
        and c.consent_type = 'adult_verified'
        and public._consent_is_on(c.status)
    )
    and
    exists (
      select 1 from public.user_consents c
      where c.user_id = p_user_id
        and c.consent_type = 'nsfw_opt_in'
        and public._consent_is_on(c.status)
    );
$$;

create or replace function public.nsfw_visible_for_current_user()
returns boolean
language sql
stable
as $$
  select public.nsfw_opt_in_enabled(auth.uid());
$$;

commit;