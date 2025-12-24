begin;

-- =========================================================
-- ANON TABLE HARD BLOCK (public schema)
-- - anon must have ZERO privileges on base tables
-- =========================================================
do $$
declare
  t record;
begin
  for t in
    select c.oid::regclass as fqtn
    from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relkind='r'  -- base table only
  loop
    execute format('revoke all on table %s from anon', t.fqtn);
  end loop;
end $$;

commit;