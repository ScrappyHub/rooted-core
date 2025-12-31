-- ROOTED: AUTO-FIX-NESTED-EXECUTE-DOLLAR-TAG-STEP-1L (canonical)
-- ROOTED: AUTO-FIX-DO-TAG-MISMATCH-STEP-1K (canonical)
-- ROOTED: AUTO-FIX-DO-OPENERS-STEP-1J2C (canonical)
-- 20251216233000_events_sanctuary_capabilities_and_vendor_rls_v7.sql
-- Adds a minimal capability framework + hard-locks sanctuary specialties to volunteer-only events
-- by replacing the vendor-hosted event RLS policies with capability-aware v7.
--
-- GUARDED: safe if events/providers/canonical_specialties/sanctuary_specialties don't exist yet.

begin;

-- ------------------------------------------------------------
-- A) Capability framework (schema-safe, idempotent)
-- ------------------------------------------------------------

create table if not exists public.specialty_capabilities (
  capability_key text primary key,
  description text,
  created_at timestamptz not null default now()
);

-- Ensure column exists even if table was created earlier without it
alter table public.specialty_capabilities
  add column if not exists default_allowed boolean not null default false;

create table if not exists public.specialty_capability_grants (
  specialty_code text not null
    references public.canonical_specialties(specialty_code) on delete cascade,
  capability_key text not null
    references public.specialty_capabilities(capability_key) on delete cascade,
  is_allowed boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (specialty_code, capability_key)
);

-- Base capability keys (defaults are conservative; expand later as needed)
insert into public.specialty_capabilities (capability_key, description, default_allowed)
values
  ('EVENT_CREATE',        'May create events (draft/submitted).', true),
  ('EVENT_UPDATE',        'May update events they own.', true),
  ('EVENT_DELETE',        'May delete events they own.', true),
  ('EVENT_PUBLISH',       'May publish events (status=published).', false),
  ('EVENT_VOLUNTEER',     'May create volunteer events (is_volunteer=true).', true),
  ('EVENT_NON_VOLUNTEER', 'May create non-volunteer events (is_volunteer=false).', true)
on conflict (capability_key) do update
  set description = excluded.description,
      default_allowed = excluded.default_allowed;

-- Helper: effective capability check
create or replace function public._specialty_capability_allowed(
  p_specialty_code text,
  p_capability_key text
) returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select g.is_allowed
       from public.specialty_capability_grants g
      where g.specialty_code = p_specialty_code
        and g.capability_key = p_capability_key),
    (select c.default_allowed
       from public.specialty_capabilities c
      where c.capability_key = p_capability_key),
    false
  );
$$;

-- Helper: sanctuary detector
create or replace function public._is_sanctuary_specialty(p_specialty_code text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.sanctuary_specialties s
     where s.specialty_code = p_specialty_code
  );
$$;

-- Sanctuary grants (explicitly deny non-volunteer; publish stays denied by default)
-- NOTE: only safe to run if canonical_specialties exists due to FK on specialty_capability_grants.

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $seed$
begin
  if to_regclass('public.canonical_specialties') is null then
    raise notice 'Skipping sanctuary capability grants: public.canonical_specialties does not exist.';
    return;
  end if;

  if to_regclass('public.specialty_capability_grants') is null then
    raise notice 'Skipping sanctuary capability grants: public.specialty_capability_grants does not exist.';
    return;
  end if;

  insert into public.specialty_capability_grants (specialty_code, capability_key, is_allowed)
  values
    ('AGRI_ANIMAL_SANCTUARY',        'EVENT_NON_VOLUNTEER', false),
    ('AGRI_WILDLIFE_RESCUE_REHAB',   'EVENT_NON_VOLUNTEER', false),
    ('AGRI_ANIMAL_SANCTUARY',        'EVENT_VOLUNTEER',     true),
    ('AGRI_WILDLIFE_RESCUE_REHAB',   'EVENT_VOLUNTEER',     true)
  on conflict (specialty_code, capability_key) do update
    set is_allowed = excluded.is_allowed;
end
$seed$;

-- ------------------------------------------------------------
-- B) Replace vendor-hosted event RLS with capability-aware v7
--    (Your events table uses host_vendor_id, not provider_id)
-- ------------------------------------------------------------

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $pol$
begin
  if to_regclass('public.events') is null then
    raise notice 'Skipping v7 events RLS: public.events does not exist.';
    return;
  end if;

  if to_regclass('public.providers') is null then
    raise notice 'Skipping v7 events RLS: public.providers does not exist.';
    return;
  end if;

  -- RLS enable guarded
  execute 'alter table public.events enable row level security';

  -- Drop prior vendor-host policies (must be EXECUTE to avoid parse-time binding)
  execute 'drop policy if exists events_host_vendor_insert_v5 on public.events';
  execute 'drop policy if exists events_host_vendor_update_v5 on public.events';
  execute 'drop policy if exists events_host_vendor_delete_v5 on public.events';

  execute 'drop policy if exists events_host_vendor_insert_v7 on public.events';
  execute 'drop policy if exists events_host_vendor_update_v7 on public.events';
  execute 'drop policy if exists events_host_vendor_delete_v7 on public.events';

  -- Create policies via EXECUTE so the block is fully guarded
  execute $q$
    create policy events_host_vendor_insert_v7
    on public.events
    for insert
    to authenticated
    with check (
      created_by = auth.uid()
      and host_vendor_id is not null
      and exists (
        select 1
        from public.providers p
        where p.id = host_vendor_id
          and p.owner_user_id = auth.uid()
          and event_vertical = coalesce(p.primary_vertical, p.vertical)
          -- Sanctuary hard lock: volunteer only
          and (
            not public._is_sanctuary_specialty(p.specialty)
            or coalesce(is_volunteer,false) = true
          )
          -- Capability lock: sanctuary explicitly denies non-volunteer
          and (
            (coalesce(is_volunteer,false) = true  and public._specialty_capability_allowed(p.specialty,'EVENT_VOLUNTEER'))
            or
            (coalesce(is_volunteer,false) = false and public._specialty_capability_allowed(p.specialty,'EVENT_NON_VOLUNTEER'))
          )
      )
      -- Publish bypass blocked: publishing requires approved moderation
      and (
        coalesce(status,'') <> 'published'
        or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
      )
    );
  $q$;

  execute $q$
    create policy events_host_vendor_update_v7
    on public.events
    for update
    to authenticated
    using (
      created_by = auth.uid()
      and host_vendor_id is not null
      and exists (
        select 1
        from public.providers p
        where p.id = host_vendor_id
          and p.owner_user_id = auth.uid()
      )
    )
    with check (
      created_by = auth.uid()
      and host_vendor_id is not null
      and exists (
        select 1
        from public.providers p
        where p.id = host_vendor_id
          and p.owner_user_id = auth.uid()
          and event_vertical = coalesce(p.primary_vertical, p.vertical)
          and (
            not public._is_sanctuary_specialty(p.specialty)
            or coalesce(is_volunteer,false) = true
          )
          and (
            (coalesce(is_volunteer,false) = true  and public._specialty_capability_allowed(p.specialty,'EVENT_VOLUNTEER'))
            or
            (coalesce(is_volunteer,false) = false and public._specialty_capability_allowed(p.specialty,'EVENT_NON_VOLUNTEER'))
          )
      )
      and (
        coalesce(status,'') <> 'published'
        or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
      )
    );
  $q$;

  execute $q$
    create policy events_host_vendor_delete_v7
    on public.events
    for delete
    to authenticated
    using (
      created_by = auth.uid()
      and host_vendor_id is not null
      and exists (
        select 1
        from public.providers p
        where p.id = host_vendor_id
          and p.owner_user_id = auth.uid()
      )
    );
  $q$;

end
$do$;

commit;