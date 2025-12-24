begin;

-- =========================================================
-- STORAGE ADMIN REPORT VIEWS (v1)
-- No ALTER TABLE here (owner-only). These are diagnostics only.
-- =========================================================

drop view if exists public.admin_storage_table_grants_v1 cascade;
create view public.admin_storage_table_grants_v1 as
select
  g.table_schema,
  g.table_name,
  g.grantee,
  g.privilege_type
from information_schema.role_table_grants g
where g.table_schema = 'storage'
  and g.grantee in ('anon','authenticated')
order by g.grantee, g.table_name, g.privilege_type;

drop view if exists public.admin_storage_policies_v1 cascade;
create view public.admin_storage_policies_v1 as
select
  schemaname,
  tablename,
  policyname,
  roles,
  cmd
from pg_policies
where schemaname='storage'
  and tablename in ('buckets','objects')
order by tablename, policyname;

commit;