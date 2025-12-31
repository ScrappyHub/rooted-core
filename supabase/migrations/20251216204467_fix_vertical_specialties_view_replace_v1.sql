-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251216204467_fix_vertical_specialties_view_replace_v1.sql
-- Fix: remote may already have vertical_specialties_v1 with different columns.
-- CREATE OR REPLACE VIEW cannot remove columns; must DROP VIEW then CREATE.

begin;

do $$
begin
  -- Drop view if it exists (CASCADE is safe if later objects reference it; they'll be recreated by later migrations)
  if to_regclass('public.vertical_specialties_v1') is not null then
    execute 'drop view public.vertical_specialties_v1 cascade';
  end if;
end;
$$;

-- Recreate canonical view
create view public.vertical_specialties_v1 as
select
  vcs.vertical_code,
  vcs.specialty_code,
  vcs.is_default
from public.vertical_canonical_specialties vcs;

commit;