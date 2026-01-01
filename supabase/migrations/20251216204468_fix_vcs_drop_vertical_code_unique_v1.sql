-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251216204468_fix_vcs_drop_vertical_code_unique_v1.sql
-- Fix: earlier patch added UNIQUE(vertical_code) which breaks multi-specialty-per-vertical seeds.
-- Canonical model: allow multiple (vertical_code, specialty_code) rows.
-- We drop the UNIQUE(vertical_code) constraint if present.

begin;

do $$
begin
  if to_regclass('public.vertical_canonical_specialties') is null then
    raise notice 'vertical_canonical_specialties missing; skipping constraint fix';
    return;
  end if;

  -- Drop the legacy UNIQUE(vertical_code) constraint if it exists
  if exists (
    select 1
    from pg_constraint
    where conname = 'vertical_canonical_specialties_vertical_code_key'
      and conrelid = 'public.vertical_canonical_specialties'::regclass
  ) then
    execute 'alter table public.vertical_canonical_specialties drop constraint vertical_canonical_specialties_vertical_code_key';
  end if;
end;
$$;

commit;