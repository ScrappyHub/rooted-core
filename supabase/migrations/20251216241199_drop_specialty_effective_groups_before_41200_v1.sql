-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251216241199_drop_specialty_effective_groups_before_41200_v1.sql
-- Fix: 41200 does CREATE OR REPLACE VIEW specialty_effective_groups_v1 with a smaller column set.
-- If the view exists with more columns (ex: recreated by 41161), Postgres errors ("cannot drop columns").
-- So we DROP it right before 41200 runs.

begin;

do $$
begin
  if to_regclass('public.specialty_effective_groups_v1') is not null then
    execute 'drop view public.specialty_effective_groups_v1';
  end if;
end;
$$;

commit;