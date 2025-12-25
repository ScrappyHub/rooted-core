-- 20251216241159_drop_vertical_specialties_v1_before_replace.sql
-- Fix: 20251216241160 uses CREATE OR REPLACE VIEW with a column reorder,
-- which fails if the view already exists.
-- Solution: drop the view right before 41160 runs so 41160 becomes a fresh CREATE.

begin;

do $$
begin
  if to_regclass('public.vertical_specialties_v1') is not null then
    execute 'drop view public.vertical_specialties_v1 cascade';
  end if;
end $$;

commit;