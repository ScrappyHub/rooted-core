-- =========================================================
-- STORAGE GRANT SURFACE REPORT (Hosted-compatible)
-- Supabase Hosted Storage is platform-managed.
-- Default storage grants for anon/authenticated are expected.
-- Enforce via storage.objects RLS policies instead of revoking grants.
-- =========================================================

do $$
declare
  r record;
begin
  for r in
    select g.grantee, g.table_schema, g.table_name, g.table_name, g.privilege_type
    from information_schema.role_table_grants g
    where g.table_schema = 'storage'
      and g.grantee in ('anon','authenticated')
    order by 1,2,3,4,5
  loop
    raise notice 'storage grant: grantee=% table=%.% privilege=%',
      r.grantee, r.table_schema, r.table_name, r.privilege_type;
  end loop;
end $$;