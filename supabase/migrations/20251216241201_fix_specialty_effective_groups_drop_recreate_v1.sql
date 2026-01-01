-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: ENFORCE-DO-CLOSE-DELIMITER-STEP-1S (canonical)
-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251216241201_fix_specialty_effective_groups_drop_recreate_v1.sql
-- CANONICAL PATCH (rewritten via pipeline):
-- Fix Postgres dependency error:
-- specialty_effective_capabilities_v1 depends on specialty_effective_groups_v1
-- so we must drop capabilities FIRST, then groups.

begin;

-- Drop dependent view first (if it exists)
do $$
begin
  if to_regclass('public.specialty_effective_capabilities_v1') is not null then
    execute 'drop view public.specialty_effective_capabilities_v1';
  end if;
end;
$$;

-- Now safe to drop groups view
do $$
begin
  if to_regclass('public.specialty_effective_groups_v1') is not null then
    execute 'drop view public.specialty_effective_groups_v1';
  end if;
end;
$$;

-- Recreate specialty_effective_groups_v1 with STABLE column contract:
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

commit;