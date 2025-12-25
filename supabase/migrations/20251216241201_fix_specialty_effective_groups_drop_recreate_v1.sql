-- 20251216241201_fix_specialty_effective_groups_drop_recreate_v1.sql
-- Fix: 41200 uses CREATE OR REPLACE VIEW specialty_effective_groups_v1 with a different column set.
-- Postgres forbids dropping columns via CREATE OR REPLACE VIEW.
-- We DROP + CREATE with a stable column contract (no SELECT *).

begin;

do $$
begin
  if to_regclass('public.specialty_effective_groups_v1') is not null then
    execute 'drop view public.specialty_effective_groups_v1';
  end if;
end $$;

-- Canonical column contract for specialty_effective_groups_v1
-- Keep these columns stable so future "replace" doesn't break:
-- specialty_code, specialty_label, vertical_code, group_key
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