-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- Revoke execute on ALL functions in public from anon/authenticated,
-- then you explicitly grant back only whitelisted RPCs.
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
    execute format('revoke all on function %s from authenticated', f.fqn);
  end loop;
end;
$$;

commit;