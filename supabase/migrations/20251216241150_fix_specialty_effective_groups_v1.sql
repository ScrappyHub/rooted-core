-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251216241150_fix_specialty_effective_groups_v1.sql
-- Fix: specialty_effective_groups_v1 referenced vs.specialty_label, but vertical_specialties_v1 no longer exposes it.
-- Canonical: labels live in public.specialty_types.
-- This rebuild makes specialty_effective_groups_v1 remote-safe + schema-stable.

begin;

do $$
begin
  -- Drop view if exists (CASCADE in case downstream views depend on it; they will be recreated later)
  if to_regclass('public.specialty_effective_groups_v1') is not null then
    execute 'drop view public.specialty_effective_groups_v1 cascade';
  end if;
end;
$$;

-- Recreate view with label sourced from specialty_types
create view public.specialty_effective_groups_v1 as
with base as (
  select distinct
    vs.specialty_code,
    st.label as specialty_label
  from public.vertical_specialties_v1 vs
  left join public.specialty_types st
    on st.code = vs.specialty_code
)
select
  b.specialty_code,
  b.specialty_label,
  -- Placeholder "group_code" logic:
  -- If you have real grouping rules, plug them in here.
  -- For now, default to the specialty_code as its own group to keep pipeline unblocked.
  b.specialty_code as group_code
from base b;

commit;