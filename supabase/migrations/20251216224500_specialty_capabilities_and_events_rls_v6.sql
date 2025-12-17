-- 20251216224500_specialty_capabilities_and_events_rls_v6.sql
-- Add canonical_specialties table, specialty capabilities, and Events RLS v6 (vendor-host)
-- Anchors specialty_code to a real PK table to avoid “table does not exist” errors.

begin;

-- ---------------------------------------------------------------------
-- A) Canonical specialties (PK table)
-- ---------------------------------------------------------------------

create table if not exists public.canonical_specialties (
  specialty_code text primary key,
  created_at timestamptz not null default now()
);

-- Seed from your canonical sources (idempotent)
insert into public.canonical_specialties (specialty_code)
select distinct specialty_code
from public.vertical_specialties_v1
where specialty_code is not null and btrim(specialty_code) <> ''
on conflict do nothing;

insert into public.canonical_specialties (specialty_code)
select distinct specialty_code
from public.vertical_canonical_specialties
where specialty_code is not null and btrim(specialty_code) <> ''
on conflict do nothing;

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
-- Baseline: everyone can host events, but publish is still blocked unless approved by existing moderation policy gates.
-- You can later tighten per-vertical via specialty_vertical_overlays / specialty_kids_mode_overlays.

insert into public.specialty_capability_grants (specialty_code, capability_key, is_allowed)
select cs.specialty_code, 'can_host_events', true
from public.canonical_specialties cs
on conflict do nothing;

insert into public.specialty_capability_grants (specialty_code, capability_key, is_allowed)
select cs.specialty_code, 'can_publish_if_approved', true
from public.canonical_specialties cs
on conflict do nothing;

-- Sanctuary: explicitly allow volunteer hosting (but RLS will force volunteer-only)
-- NOTE: You still need to seed sanctuary_specialties with the actual specialty_codes you consider “sanctuary”.
insert into public.specialty_capability_grants (specialty_code, capability_key, is_allowed)
select s.specialty_code, 'can_host_volunteer_events', true
from public.sanctuary_specialties s
on conflict do nothing;

-- ---------------------------------------------------------------------
-- D) Helper functions (vendor-hosted uses host_vendor_id)
-- ---------------------------------------------------------------------

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

-- ---------------------------------------------------------------------
-- E) Replace vendor-host policies with capability-aware v6
-- Policies are OR'd -> drop the older vendor-host ones so there’s no bypass.
-- ---------------------------------------------------------------------

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

create policy events_host_vendor_update_v6
on public.events
for update
to authenticated
using (
  created_by = auth.uid()
  and host_vendor_id is not null
  and public._provider_owned(host_vendor_id)
)
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

  and (
    public._specialty_is_sanctuary(public._provider_specialty_code(host_vendor_id)) = false
    or coalesce(is_volunteer,false) = true
  )

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

create policy events_host_vendor_delete_v6
on public.events
for delete
to authenticated
using (
  created_by = auth.uid()
  and host_vendor_id is not null
  and public._provider_owned(host_vendor_id)
  and public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_events')
);

commit;
