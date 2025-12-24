begin;

-- =========================================================
-- AUTHENTICATED SELECT SURFACE AUDIT (v1)
-- Creates:
--  - public.admin_authenticated_select_surface_v1
-- Shows SELECT grants for authenticated on public relations (tables+views).
-- =========================================================

drop view if exists public.admin_authenticated_select_surface_v1;

create view public.admin_authenticated_select_surface_v1 as
select
  g.table_schema,
  g.table_name,
  c.relkind,
  case c.relkind
    when 'r' then 'table'
    when 'p' then 'partitioned_table'
    when 'v' then 'view'
    when 'm' then 'materialized_view'
    when 'f' then 'foreign_table'
    else c.relkind::text
  end as object_type,
  g.privilege_type
from information_schema.role_table_grants g
join pg_namespace n
  on n.nspname = g.table_schema
join pg_class c
  on c.relnamespace = n.oid
 and c.relname = g.table_name
where g.table_schema = 'public'
  and g.grantee = 'authenticated'
  and g.privilege_type = 'SELECT'
order by object_type, g.table_name;

-- Keep this admin view private by default (no grants to anon/authenticated)
revoke all on public.admin_authenticated_select_surface_v1 from anon;
revoke all on public.admin_authenticated_select_surface_v1 from authenticated;

commit;