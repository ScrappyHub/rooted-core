-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251216241203_fix_specialty_effective_views_final_canonical_v1.sql
-- Canonical fix: enforce stable contracts + correct dependency order.
-- We do NOT mutate earlier migrations; we assert final state.

begin;

-- Drop dependent view first (capabilities depends on groups)
do $$
begin
  if to_regclass('public.specialty_effective_capabilities_v1') is not null then
    execute 'drop view public.specialty_effective_capabilities_v1';
  end if;
end;
$$;

-- Now drop groups
do $$
begin
  if to_regclass('public.specialty_effective_groups_v1') is not null then
    execute 'drop view public.specialty_effective_groups_v1';
  end if;
end;
$$;

-- Recreate specialty_effective_groups_v1 with a stable 4-column contract:
-- (specialty_code, specialty_label, vertical_code, group_key)
create view public.specialty_effective_groups_v1 as
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
    b.specialty_label,
    b.vertical_code,
    case
      when exists (
        select 1
        from public.sanctuary_specialties s
        where s.specialty_code = b.specialty_code
      )
      then 'SANCTUARY_RESCUE'
      else 'STANDARD_VENDOR'
    end as group_key
  from base b
)
select
  g.specialty_code,
  g.specialty_label,
  g.vertical_code,
  g.group_key
from grp g;

-- Recreate specialty_effective_capabilities_v1 (canonical precedence)
-- A) explicit specialty_capability_grants
-- B) group_capability_grants via specialty_effective_groups_v1
-- C) specialty_capabilities.default_allowed
create view public.specialty_effective_capabilities_v1 as
with s as (
  select distinct specialty_code
  from public.vertical_specialties_v1
),
g as (
  select s.specialty_code, eg.group_key
  from s
  join public.specialty_effective_groups_v1 eg using (specialty_code)
),
c as (
  select capability_key, default_allowed
  from public.specialty_capabilities
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
left join explicit
  on explicit.specialty_code = s.specialty_code
 and explicit.capability_key = c.capability_key
left join grouped
  on grouped.specialty_code = s.specialty_code
 and grouped.capability_key = c.capability_key;

commit;