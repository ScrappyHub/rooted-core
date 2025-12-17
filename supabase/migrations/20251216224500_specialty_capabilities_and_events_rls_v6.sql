-- 20251216224500_specialty_capabilities_and_events_rls_v6.sql
-- Canonical: specialty-driven capabilities (NOT vertical-wide access)
-- Applies to vendor-hosted events (host_vendor_id).
-- Locks Sanctuary specialty to volunteer-only at DB layer.

begin;

-- ---------------------------------------------------------------------
-- A) Capability tables (keyed off specialty_code)
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

-- Sanctuary specialties live here (so you can have 8-9 of them cleanly)
create table if not exists public.sanctuary_specialties (
  specialty_code text primary key
    references public.canonical_specialties(specialty_code) on delete cascade,
  created_at timestamptz not null default now()
);

-- seed canonical capability keys
insert into public.specialty_capabilities (capability_key, description) values
  ('can_host_events', 'Specialty can create/update/delete hosted events (draft/submitted; publish requires approval)'),
  ('can_host_volunteer_events', 'Specialty can create volunteer events'),
  ('can_publish_if_approved', 'Allows publish only when moderation_status=approved (still enforced by RLS)'),
  ('can_host_kids_safe_events', 'Specialty may mark events as kids-safe (still subject to moderation)'),
  ('can_host_large_scale_volunteer', 'Specialty may set is_large_scale_volunteer=true')
on conflict (capability_key) do nothing;

-- ---------------------------------------------------------------------
-- B) Helper functions (SECURITY DEFINER, stable)
-- ---------------------------------------------------------------------

create or replace function public._provider_owned(vendor_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.providers p
    where p.id = vendor_id
      and p.owner_user_id = auth.uid()
  );
$$;

create or replace function public._provider_is_verified(vendor_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select p.is_verified from public.providers p where p.id = vendor_id), false);
$$;

create or replace function public._provider_effective_vertical(vendor_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(p.primary_vertical, p.vertical)
  from public.providers p
  where p.id = vendor_id;
$$;

create or replace function public._provider_specialty_code(vendor_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.specialty
  from public.providers p
  where p.id = vendor_id;
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
-- C) Replace vendor-host event policies with capability-aware v6
-- IMPORTANT: policies are OR'd, so we must drop v5 or it will bypass v6.
-- ---------------------------------------------------------------------

drop policy if exists events_host_vendor_insert_v5 on public.events;
drop policy if exists events_host_vendor_update_v5 on public.events;
drop policy if exists events_host_vendor_delete_v5 on public.events;

-- INSERT (vendor-hosted)
create policy events_host_vendor_insert_v6
on public.events
for insert
to authenticated
with check (
  created_by = auth.uid()
  and host_vendor_id is not null
  and public._provider_owned(host_vendor_id)
  -- vertical must match provider effective vertical
  and event_vertical = public._provider_effective_vertical(host_vendor_id)

  -- capability gate: must be allowed to host events
  and public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_events')

  -- volunteer gate
  and (
    coalesce(is_volunteer,false) = false
    or public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_volunteer_events')
  )

  -- sanctuary hard-lock: volunteer only (no exceptions)
  and (
    public._specialty_is_sanctuary(public._provider_specialty_code(host_vendor_id)) = false
    or coalesce(is_volunteer,false) = true
  )

  -- unverified providers: draft only
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

  -- large scale volunteer is an explicit capability
  and (
    coalesce(is_large_scale_volunteer,false) = false
    or public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_large_scale_volunteer')
  )
);

-- UPDATE (vendor-hosted)
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

  -- publish requires approval even for verified providers
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

-- DELETE (vendor-hosted)
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
