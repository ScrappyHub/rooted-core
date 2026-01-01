-- ROOTED: STRIP-EXECUTE-DOLLAR-QUOTES-STEP-1P (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
-- ROOTED: AUTO-FIX-EXECUTE-CLOSER-MISMATCH-STEP-1N (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- ROOTED: AUTO-FIX-NESTED-EXECUTE-DOLLAR-TAG-STEP-1L (canonical)
-- ROOTED: AUTO-FIX-DO-TAG-MISMATCH-STEP-1K (canonical)
-- ROOTED: AUTO-FIX-DO-OPENERS-STEP-1J2C (canonical)
-- 20251216224500_specialty_capabilities_and_events_rls_v6.sql
-- Add canonical_specialties table, specialty capabilities, and Events RLS v6 (vendor-host)
-- GUARDED: this repo may not include base tables/views yet (events/providers/vertical_specialties_v1).
-- Goal: never hard-fail boot; apply what we can, skip what depends on missing objects.

begin;

-- ---------------------------------------------------------------------
-- A) Canonical specialties (PK table)
-- ---------------------------------------------------------------------

create table if not exists public.canonical_specialties (
  specialty_code text primary key,
  created_at timestamptz not null default now()
);

-- Seed from vertical_specialties_v1 ONLY if it exists

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $sql$
begin
  if to_regclass('public.vertical_specialties_v1') is null then
    raise notice 'Skipping canonical_specialties seed from vertical_specialties_v1: view does not exist.';
  else
      insert into public.canonical_specialties (specialty_code)
      select distinct specialty_code
      from public.vertical_specialties_v1
      where specialty_code is not null and btrim(specialty_code) <> ''
      on conflict do nothing
    $sql$;
  end if;
end
$do$;

-- Seed from vertical_canonical_specialties ONLY if it exists

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $sql$
begin
  if to_regclass('public.vertical_canonical_specialties') is null then
    raise notice 'Skipping canonical_specialties seed from vertical_canonical_specialties: relation does not exist.';
  else
    execute $q$
      insert into public.canonical_specialties (specialty_code)
      select distinct specialty_code
      from public.vertical_canonical_specialties
      where specialty_code is not null and btrim(specialty_code) <> ''
      on conflict do nothing
    $sql$;
  end if;
end
$do$;

-- ---------------------------------------------------------------------
-- B) Capability tables
-- ---------------------------------------------------------------------

create table if not exists public.specialty_capabilities (
  capability_key text primary key,
  description text not null
);

create table if not exists public.specialty_capability_grants (
  specialty_code text not null
    references public.canonical_specialties(specialty_code) on delete cascade,
  capability_key text not null
    references public.specialty_capabilities(capability_key) on delete cascade,
  is_allowed boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (specialty_code, capability_key)
);

create table if not exists public.sanctuary_specialties (
  specialty_code text primary key
    references public.canonical_specialties(specialty_code) on delete cascade,
  created_at timestamptz not null default now()
);

-- Capability keys (idempotent)
insert into public.specialty_capabilities (capability_key, description) values
  ('can_host_events', 'Specialty can create/update/delete hosted events (draft/submitted; publish requires approval)'),
  ('can_host_volunteer_events', 'Specialty can create volunteer events'),
  ('can_publish_if_approved', 'Allows publish only when moderation_status=approved (still enforced by RLS)'),
  ('can_host_kids_safe_events', 'Specialty may set events kids-safe (still subject to moderation and Kids Mode overlays)'),
  ('can_host_large_scale_volunteer', 'Specialty may set is_large_scale_volunteer=true')
on conflict (capability_key) do nothing;

-- ---------------------------------------------------------------------
-- C) Default grants (safe baseline)
-- ---------------------------------------------------------------------

insert into public.specialty_capability_grants (specialty_code, capability_key, is_allowed)
select cs.specialty_code, 'can_host_events', true
from public.canonical_specialties cs
on conflict do nothing;

insert into public.specialty_capability_grants (specialty_code, capability_key, is_allowed)
select cs.specialty_code, 'can_publish_if_approved', true
from public.canonical_specialties cs
on conflict do nothing;

-- Sanctuary: explicitly allow volunteer hosting (but RLS will force volunteer-only)
insert into public.specialty_capability_grants (specialty_code, capability_key, is_allowed)
select s.specialty_code, 'can_host_volunteer_events', true
from public.sanctuary_specialties s
on conflict do nothing;

-- ---------------------------------------------------------------------
-- D) Helper functions + E) Events RLS policies
-- These depend on public.providers and public.events existing.
-- Guard the whole block to prevent boot failure in repos without those tables.
-- ---------------------------------------------------------------------

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $$
begin
  if to_regclass('public.providers') is null then
    raise notice 'Skipping specialty capability helper functions/policies: public.providers does not exist.';
    return;
  end if;

  if to_regclass('public.events') is null then
    raise notice 'Skipping specialty capability helper functions/policies: public.events does not exist.';
    return;
  end if;

  -- Helper functions (vendor-hosted uses host_vendor_id)
  execute $q$
    create or replace function public._provider_owned(p_vendor_id uuid)
    returns boolean
    language sql
    stable
    security definer
    set search_path = public
    as $$
      select exists (
        select 1
        from public.providers p
        where p.id = p_vendor_id
          and p.owner_user_id = auth.uid()
      );
    $$;

    create or replace function public._provider_is_verified(p_vendor_id uuid)
    returns boolean
    language sql
    stable
    security definer
    set search_path = public
    as $$
      select coalesce((select p.is_verified from public.providers p where p.id = p_vendor_id), false);
    $$;

    create or replace function public._provider_effective_vertical(p_vendor_id uuid)
    returns text
    language sql
    stable
    security definer
    set search_path = public
    as $$
      select coalesce(p.primary_vertical, p.vertical)
      from public.providers p
      where p.id = p_vendor_id;
    $$;

    create or replace function public._provider_specialty_code(p_vendor_id uuid)
    returns text
    language sql
    stable
    security definer
    set search_path = public
    as $$
      select p.specialty
      from public.providers p
      where p.id = p_vendor_id;
    $$;

    create or replace function public._specialty_has_capability(p_specialty text, p_capability text)
    returns boolean
    language sql
    stable
    security definer
    set search_path = public
    as $$
      select exists (
        select 1
        from public.specialty_capability_grants g
        where g.specialty_code = p_specialty
          and g.capability_key = p_capability
          and g.is_allowed = true
      );
    $$;

    create or replace function public._specialty_is_sanctuary(p_specialty text)
    returns boolean
    language sql
    stable
    security definer
    set search_path = public
    as $$
      select exists (
        select 1
        from public.sanctuary_specialties s
        where s.specialty_code = p_specialty
      );
    $$;

  -- Replace vendor-host policies with capability-aware v6
    alter table public.events enable row level security;

    drop policy if exists events_host_vendor_insert_v5 on public.events;
    drop policy if exists events_host_vendor_update_v5 on public.events;
    drop policy if exists events_host_vendor_delete_v5 on public.events;

    drop policy if exists events_host_vendor_insert_v6 on public.events;
    drop policy if exists events_host_vendor_update_v6 on public.events;
    drop policy if exists events_host_vendor_delete_v6 on public.events;

    create policy events_host_vendor_insert_v6
    on public.events
    for insert
    to authenticated
    with check (
      created_by = auth.uid()
      and host_vendor_id is not null
      and public._provider_owned(host_vendor_id)
      and event_vertical = public._provider_effective_vertical(host_vendor_id)

      and public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_events')

      and (
        coalesce(is_volunteer,false) = false
        or public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_volunteer_events')
      )

      -- Sanctuary volunteer-only (hard law)
      and (
        public._specialty_is_sanctuary(public._provider_specialty_code(host_vendor_id)) = false
        or coalesce(is_volunteer,false) = true
      )

      -- Unverified providers: draft only
      and (
        (public._provider_is_verified(host_vendor_id) = false and coalesce(status,'') = 'draft')
        or
        (public._provider_is_verified(host_vendor_id) = true
          and (
            coalesce(status,'') <> 'published'
            or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
          )
        )
      )

      and (
        coalesce(is_large_scale_volunteer,false) = false
        or public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_large_scale_volunteer')
      )
    );

end
$do$;

commit;