-- 20251216241161_fix_vertical_specialties_view_column_order_v1.sql
-- Fix: 41160 creates vertical_specialties_v1 with (vertical_code, specialty_code, specialty_label, is_default).
-- 41161 must NOT "create or replace" with reordered columns (Postgres forbids column renames on replace).
-- We DROP + CREATE to guarantee stable column order and we also recreate specialty_effective_groups_v1
-- because prior drops may have CASCADE'd it.

begin;

do $$
begin
  -- If specialty_effective_groups_v1 depends on vertical_specialties_v1, it may have been dropped earlier via CASCADE.
  if to_regclass('public.specialty_effective_groups_v1') is not null then
    execute 'drop view public.specialty_effective_groups_v1';
  end if;

  if to_regclass('public.vertical_specialties_v1') is not null then
    execute 'drop view public.vertical_specialties_v1';
  end if;
end $$;

-- Recreate vertical_specialties_v1 with the FINAL canonical order:
-- (vertical_code, specialty_code, is_default, specialty_label)
create view public.vertical_specialties_v1 as
select
  vcs.vertical_code,
  vcs.specialty_code,
  vcs.is_default,
  st.label as specialty_label
from public.vertical_canonical_specialties vcs
left join public.specialty_types st
  on st.code = vcs.specialty_code;

-- Recreate specialty_effective_groups_v1 (must expose specialty_code + specialty_label at minimum)
-- Deterministic "group" derivation (no manual 138 mapping): use prefix of specialty_code before first underscore.
create view public.specialty_effective_groups_v1 as
with base as (
  select distinct
    vs.vertical_code,
    vs.specialty_code,
    vs.specialty_label
  from public.vertical_specialties_v1 vs
),
grp as (
  select
    b.*,
    split_part(b.specialty_code, '_', 1) as group_code
  from base b
)
select
  g.vertical_code,
  g.specialty_code,
  g.specialty_label,
  g.group_code,
  initcap(replace(g.group_code, '_', ' ')) as group_label
from grp g;

commit;