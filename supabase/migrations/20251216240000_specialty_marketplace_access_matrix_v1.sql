-- 20251216240000_specialty_marketplace_access_matrix_v1.sql
-- Canonical capability matrix for marketplace + events (vertical defaults + specialty overrides)
-- Pre-Phase 1: locks enforcement in DB before multi-specialty tags.

begin;

-- ------------------------------------------------------------
-- A) Capability registry (columns of the matrix)
-- ------------------------------------------------------------

create table if not exists public.capabilities (
  capability_key text primary key,
  description text,
  default_allowed boolean not null default false,
  created_at timestamptz not null default now()
);

-- Upsert baseline capability keys (expand later, idempotent)
insert into public.capabilities (capability_key, description, default_allowed)
values
  -- Marketplace
  ('MKP_LISTING_CREATE',   'May create marketplace listings.', true),
  ('MKP_LISTING_UPDATE',   'May update marketplace listings they own.', true),
  ('MKP_LISTING_DELETE',   'May delete marketplace listings they own.', true),
  ('MKP_RFQ_RESPOND',      'May respond to RFQs / bids / quote requests.', true),
  ('MKP_MESSAGES_REPLY',   'May reply in marketplace messaging threads.', true),

  -- Events
  ('EVENT_CREATE',         'May create events (draft/submitted).', true),
  ('EVENT_UPDATE',         'May update events they own.', true),
  ('EVENT_DELETE',         'May delete events they own.', true),
  ('EVENT_VOLUNTEER',      'May create volunteer events (is_volunteer=true).', true),
  ('EVENT_NON_VOLUNTEER',  'May create non-volunteer events.', true),
  ('EVENT_PUBLISH',        'May publish events (status=published).', false),

  -- Cross-vertical overlays / invites
  ('INVITE_TO_LOCAL_BUSINESS',    'May be invited/activated into Local Business Discovery.', false),
  ('INVITE_TO_COMMUNITY_STAPLES', 'May be invited/activated into Community Staples overlays.', false)
on conflict (capability_key) do update
  set description = excluded.description,
      default_allowed = excluded.default_allowed;

-- ------------------------------------------------------------
-- B) Vertical defaults (base layer)
-- ------------------------------------------------------------

create table if not exists public.vertical_capability_defaults (
  vertical_code text not null
    references public.canonical_verticals(vertical_code) on delete cascade,
  capability_key text not null
    references public.capabilities(capability_key) on delete cascade,
  is_allowed boolean not null,
  created_at timestamptz not null default now(),
  primary key (vertical_code, capability_key)
);

-- Conservative base defaults:
-- - allow create/update/delete for events + marketplace in general
-- - publishing stays FALSE unless explicitly granted later
-- You can tighten per vertical later via upserts.
insert into public.vertical_capability_defaults (vertical_code, capability_key, is_allowed)
select v.vertical_code, c.capability_key,
       case
         when c.capability_key = 'EVENT_PUBLISH' then false
         else c.default_allowed
       end as is_allowed
from public.canonical_verticals v
cross join public.capabilities c
where v.vertical_code is not null
on conflict (vertical_code, capability_key) do nothing;

-- ------------------------------------------------------------
-- C) Specialty overrides (fine-grained “law” layer)
-- ------------------------------------------------------------

-- Uses your canonical specialties table (you confirmed it exists now)
create table if not exists public.specialty_capability_grants (
  specialty_code text not null
    references public.canonical_specialties(specialty_code) on delete cascade,
  capability_key text not null
    references public.capabilities(capability_key) on delete cascade,
  is_allowed boolean not null,
  created_at timestamptz not null default now(),
  primary key (specialty_code, capability_key)
);

-- ------------------------------------------------------------
-- D) Effective capability resolver
-- ------------------------------------------------------------

-- Note: We resolve against a provider’s effective vertical + specialty.
-- (Pre-Phase 1 uses providers.primary_vertical/vertical + providers.specialty;
-- Phase 1 will swap specialty source to provider_specialties without changing this contract.)
create or replace function public._capability_allowed_for_provider(
  p_provider_id uuid,
  p_capability_key text
) returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    -- 1) Specialty override wins
    (select g.is_allowed
       from public.providers p
       join public.specialty_capability_grants g
         on g.specialty_code = p.specialty
      where p.id = p_provider_id
        and g.capability_key = p_capability_key),

    -- 2) Vertical default
    (select d.is_allowed
       from public.providers p
       join public.vertical_capability_defaults d
         on d.vertical_code = coalesce(p.primary_vertical, p.vertical)
      where p.id = p_provider_id
        and d.capability_key = p_capability_key),

    -- 3) Capability default
    (select c.default_allowed
       from public.capabilities c
      where c.capability_key = p_capability_key),

    false
  );
$$;

-- ------------------------------------------------------------
-- E) Sanctuary hard locks (specialty overrides)
-- ------------------------------------------------------------

-- Ensure sanctuary specialties are volunteer-only forever at DB layer.
-- (You already have sanctuary_specialties table and seeded 2 rows.)
insert into public.specialty_capability_grants (specialty_code, capability_key, is_allowed)
values
  ('AGRI_ANIMAL_SANCTUARY',      'EVENT_NON_VOLUNTEER', false),
  ('AGRI_WILDLIFE_RESCUE_REHAB', 'EVENT_NON_VOLUNTEER', false),
  ('AGRI_ANIMAL_SANCTUARY',      'EVENT_VOLUNTEER',     true),
  ('AGRI_WILDLIFE_RESCUE_REHAB', 'EVENT_VOLUNTEER',     true)
on conflict (specialty_code, capability_key) do update
  set is_allowed = excluded.is_allowed;

commit;
