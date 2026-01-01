-- ROOTED: ENFORCE-DO-CLOSE-DELIMITER-STEP-1S (canonical)
-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251216241202_fix_specialty_effective_views_dependency_order_v1.sql
-- Fix: specialty_effective_capabilities_v1 depends on specialty_effective_groups_v1
-- so we must drop/recreate in dependency order (no schema drift, reuse canonical definitions).

begin;

-- 1) Drop dependent view first
do $$
begin
  if to_regclass('public.specialty_effective_capabilities_v1') is not null then
    execute 'drop view public.specialty_effective_capabilities_v1';
  end if;
end;
$$;

-- 2) Drop groups view now that dependents are gone
do $$
begin
  if to_regclass('public.specialty_effective_groups_v1') is not null then
    execute 'drop view public.specialty_effective_groups_v1';
  end if;
end;
$$;

-- 3) Recreate groups view with stable column contract
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

-- 4) Recreate capabilities view (PASTE CANONICAL SQL BELOW)
-- >>> PASTE the exact CREATE VIEW for public.specialty_effective_capabilities_v1 here <<<
-- Example:
-- create view public.specialty_effective_capabilities_v1 as
--   ...;

commit;