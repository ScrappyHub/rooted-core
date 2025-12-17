begin;

-- ============================================================
-- 1) Governance groups (tiny, stable)
-- ============================================================
create table if not exists public.specialty_governance_groups (
  group_key text primary key,
  description text,
  created_at timestamptz not null default now()
);

insert into public.specialty_governance_groups (group_key, description)
values
  ('SANCTUARY_RESCUE', 'Animal sanctuaries + wildlife rescue/rehab. Volunteer-only events, conservative access.'),
  ('STANDARD_VENDOR', 'Normal local vendors/providers (default commercial rules).'),
  ('INSTITUTION', 'Institutions (schools, hospitals, nonprofits, civic orgs).'),
  ('YOUTH_RESTRICTED', 'Specialties restricted in teen/kids contexts; conservative posting rules.'),
  ('LOCAL_BUSINESS_STAPLE', 'Long-standing community staples; special discovery treatment later (invites/cross-overlays).')
on conflict (group_key) do update
  set description = excluded.description;

-- ============================================================
-- 2) Group -> capability grants (small list only)
--    NOTE: capability keys must already exist in specialty_capabilities
-- ============================================================
create table if not exists public.group_capability_grants (
  group_key text not null references public.specialty_governance_groups(group_key) on delete cascade,
  capability_key text not null references public.specialty_capabilities(capability_key) on delete cascade,
  is_allowed boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (group_key, capability_key)
);

-- Sanctuary: hard-lock volunteer-only
insert into public.group_capability_grants (group_key, capability_key, is_allowed)
values
  ('SANCTUARY_RESCUE', 'EVENT_VOLUNTEER', true),
  ('SANCTUARY_RESCUE', 'EVENT_NON_VOLUNTEER', false),
  ('SANCTUARY_RESCUE', 'EVENT_PUBLISH', false),
  ('SANCTUARY_RESCUE', 'FEED_POST_CREATE', false)
on conflict (group_key, capability_key) do update
  set is_allowed = excluded.is_allowed;

-- Standard vendors: allow typical operations, still block publish unless you explicitly grant
insert into public.group_capability_grants (group_key, capability_key, is_allowed)
values
  ('STANDARD_VENDOR', 'EVENT_VOLUNTEER', true),
  ('STANDARD_VENDOR', 'EVENT_NON_VOLUNTEER', true),
  ('STANDARD_VENDOR', 'EVENT_PUBLISH', false),
  ('STANDARD_VENDOR', 'FEED_POST_CREATE', true),
  ('STANDARD_VENDOR', 'FEED_POST_COMMENT', true),
  ('STANDARD_VENDOR', 'FEED_POST_REACT', true)
on conflict (group_key, capability_key) do update
  set is_allowed = excluded.is_allowed;

-- Institutions: conservative feed + events (adjust later)
insert into public.group_capability_grants (group_key, capability_key, is_allowed)
values
  ('INSTITUTION', 'EVENT_VOLUNTEER', true),
  ('INSTITUTION', 'EVENT_NON_VOLUNTEER', true),
  ('INSTITUTION', 'EVENT_PUBLISH', false),
  ('INSTITUTION', 'FEED_POST_CREATE', true),
  ('INSTITUTION', 'FEED_POST_COMMENT', true),
  ('INSTITUTION', 'FEED_POST_REACT', true)
on conflict (group_key, capability_key) do update
  set is_allowed = excluded.is_allowed;

-- Youth restricted: block risky surfaces by default
insert into public.group_capability_grants (group_key, capability_key, is_allowed)
values
  ('YOUTH_RESTRICTED', 'FEED_POST_CREATE', false),
  ('YOUTH_RESTRICTED', 'EVENT_NON_VOLUNTEER', false),
  ('YOUTH_RESTRICTED', 'EVENT_PUBLISH', false)
on conflict (group_key, capability_key) do update
  set is_allowed = excluded.is_allowed;

-- ============================================================
-- 3) Computed specialty -> group mapping (no manual 138 mapping)
-- ============================================================
create or replace view public.specialty_effective_groups_v1 as
with base as (
  select distinct
    vs.specialty_code,
    vs.specialty_label,
    vs.vertical_code
  from public.vertical_specialties_v1 vs
),
grp as (
  select
    b.specialty_code,
    -- sanctuary table is the strongest signal
    case
      when exists (select 1 from public.sanctuary_specialties s where s.specialty_code = b.specialty_code)
        then 'SANCTUARY_RESCUE'

      -- you can add more deterministic signals over time:
      -- when b.vertical_code in ('EDUCATION', ...) then 'INSTITUTION'
      -- when ... overlay marks youth-restricted ... then 'YOUTH_RESTRICTED'

      else 'STANDARD_VENDOR'
    end as group_key
  from base b
)
select * from grp;

-- ============================================================
-- 4) Effective grants view (capability resolution order)
--    Order of precedence:
--      A) explicit specialty_capability_grants
--      B) group_capability_grants (computed group)
--      C) specialty_capabilities.default_allowed
-- ============================================================
create or replace view public.specialty_effective_capabilities_v1 as
with s as (
  select distinct specialty_code from public.vertical_specialties_v1
),
g as (
  select s.specialty_code, eg.group_key
  from s
  join public.specialty_effective_groups_v1 eg using (specialty_code)
),
c as (
  select capability_key, default_allowed from public.specialty_capabilities
),
explicit as (
  select specialty_code, capability_key, is_allowed
  from public.specialty_capability_grants
),
grouped as (
  select g.specialty_code, gg.capability_key, gg.is_allowed
  from g
  join public.group_capability_grants gg on gg.group_key = g.group_key
)
select
  s.specialty_code,
  c.capability_key,
  coalesce(explicit.is_allowed, grouped.is_allowed, c.default_allowed, false) as is_allowed,
  case
    when explicit.is_allowed is not null then 'SPECIALTY_OVERRIDE'
    when grouped.is_allowed is not null then 'GROUP_RULE'
    else 'CAPABILITY_DEFAULT'
  end as source
from s
cross join c
left join explicit on explicit.specialty_code = s.specialty_code and explicit.capability_key = c.capability_key
left join grouped  on grouped.specialty_code  = s.specialty_code  and grouped.capability_key  = c.capability_key;

commit;
