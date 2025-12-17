begin;

-- ------------------------------------------------------------
-- 1) Capability catalog (keys are stable API)
-- ------------------------------------------------------------
create table if not exists public.specialty_capabilities (
  capability_key text primary key,
  description text,
  default_allowed boolean not null default false,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 2) Specialty -> Capability grants (matrix)
-- ------------------------------------------------------------
create table if not exists public.specialty_capability_grants (
  specialty_code text not null
    references public.canonical_specialties(specialty_code) on delete cascade,
  capability_key text not null
    references public.specialty_capabilities(capability_key) on delete cascade,
  is_allowed boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (specialty_code, capability_key)
);

-- ------------------------------------------------------------
-- 3) Helpers (single source of truth)
-- ------------------------------------------------------------

-- return specialty for a provider; blocks blank
create or replace function public._provider_specialty(p_provider_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select nullif(btrim(p.specialty), '')
  from public.providers p
  where p.id = p_provider_id;
$$;

-- confirm ownership + specialty exists
create or replace function public._is_owned_provider_with_specialty(p_provider_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.providers p
    where p.id = p_provider_id
      and p.owner_user_id = auth.uid()
      and nullif(btrim(p.specialty), '') is not null
  );
$$;

-- effective capability: explicit grant overrides default
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

-- check capability for a provider (ownership + specialty + grants)
create or replace function public._provider_has_capability(
  p_provider_id uuid,
  p_capability_key text
) returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public._is_owned_provider_with_specialty(p_provider_id)
    and public._specialty_capability_allowed(public._provider_specialty(p_provider_id), p_capability_key);
$$;

commit;
