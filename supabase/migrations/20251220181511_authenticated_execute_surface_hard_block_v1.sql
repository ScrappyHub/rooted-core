-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- AUTHENTICATED/ANON EXECUTE SURFACE: HARD BLOCK (v1)
-- Revoke EXECUTE on ALL public functions from anon + authenticated.
-- (Later, if you need public RPCs, we add a tiny explicit allowlist.)
-- =========================================================

do $$
declare
  r record;
begin
  for r in
    select p.oid::regprocedure as obj
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='public'
  loop
    execute format('revoke all on function %s from anon', r.obj);
    execute format('revoke all on function %s from authenticated', r.obj);
  end loop;
end;
$$;

commit;