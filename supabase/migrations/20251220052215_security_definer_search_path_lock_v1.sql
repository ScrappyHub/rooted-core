begin;

-- =========================================================
-- SECURITY DEFINER HARDENING: pin search_path
-- =========================================================
do $$
declare
  f record;
begin
  for f in
    select p.oid::regprocedure as fqn
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and p.prosecdef = true
  loop
    execute format('alter function %s set search_path = public, pg_temp', f.fqn);
  end loop;
end $$;

commit;