begin;

-- =========================================================
-- SECURITY DEFINER SEARCH_PATH LOCK (v2)
-- For every SECURITY DEFINER function in public:
--   - enforce a safe search_path
--     (prevents hijacking via attacker-created objects)
-- =========================================================

do $$
declare
  r record;
begin
  for r in
    select p.oid, n.nspname, p.proname
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef = true
  loop
    execute format(
      'alter function %s set search_path = public, pg_temp;',
      r.oid::regprocedure
    );
  end loop;
end $$;

commit;