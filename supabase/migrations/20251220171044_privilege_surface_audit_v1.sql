begin;

-- =========================================================
-- PRIVILEGE SURFACE AUDIT (v1)
-- Purpose:
-- - Report any EXECUTE grants for anon/authenticated on public routines
-- - Report authenticated table privileges (all + non-SELECT)
-- Non-breaking, read-only, no revokes except explicitly on these audit views
-- =========================================================

-- 1) Routine EXECUTE surface (anon/authenticated)
create or replace view public.admin_routine_execute_surface_v1 as
select
  r.routine_schema,
  r.routine_name,
  g.grantee,
  g.privilege_type
from information_schema.routines r
join information_schema.role_routine_grants g
  on g.specific_schema = r.routine_schema
 and g.routine_name    = r.routine_name
where r.routine_schema = 'public'
  and g.grantee in ('anon','authenticated')
  and g.privilege_type = 'EXECUTE'
order by g.grantee, r.routine_name;

-- 2) Authenticated table grants (full)
create or replace view public.admin_table_grants_surface_v1 as
select
  table_schema,
  table_name,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and grantee = 'authenticated'
order by table_name, privilege_type;

-- 3) Authenticated non-SELECT table grants (this is the risky list)
create or replace view public.admin_table_grants_nonselect_authenticated_v1 as
select
  table_schema,
  table_name,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and grantee = 'authenticated'
  and privilege_type <> 'SELECT'
order by table_name, privilege_type;

-- Lock these audit views to backend/admin usage only
revoke all on public.admin_routine_execute_surface_v1 from anon;
revoke all on public.admin_routine_execute_surface_v1 from authenticated;

revoke all on public.admin_table_grants_surface_v1 from anon;
revoke all on public.admin_table_grants_surface_v1 from authenticated;

revoke all on public.admin_table_grants_nonselect_authenticated_v1 from anon;
revoke all on public.admin_table_grants_nonselect_authenticated_v1 from authenticated;

grant select on public.admin_routine_execute_surface_v1 to service_role;
grant select on public.admin_table_grants_surface_v1 to service_role;
grant select on public.admin_table_grants_nonselect_authenticated_v1 to service_role;

commit;