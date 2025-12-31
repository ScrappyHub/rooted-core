-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- FUNCTIONS: revoke execute from anon only
-- (authenticated left intact to avoid breaking RLS/policies)
-- =========================================================
do $$
declare
  f record;
begin
  for f in
    select p.oid::regprocedure as fqn
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='public'
  loop
    execute format('revoke all on function %s from anon', f.fqn);
  end loop;
end;
$$;

commit;