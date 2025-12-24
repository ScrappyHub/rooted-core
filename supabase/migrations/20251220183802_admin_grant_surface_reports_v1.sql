begin;

-- =========================================================
-- ADMIN GRANT SURFACE REPORTS (v1) - TYPE-SAFE FIX
-- Fixes prior failure: cannot change view column type.
--
-- KEEP admin_authenticated_select_surface_v1 column types stable:
--   relkind stays CHAR(1) (pg_class.relkind)
--
-- Creates:
--   - public.admin_anon_select_surface_v1
--   - public.admin_authenticated_write_surface_v1
-- Replaces:
--   - public.admin_authenticated_select_surface_v1 (same shape + types)
-- =========================================================

create or replace view public.admin_authenticated_select_surface_v1 as
select
  g.table_schema,
  g.table_name,
  c.relkind as relkind,  -- CHAR(1) to match existing view column type
  case c.relkind
    when 'r' then 'table'
    when 'p' then 'partitioned_table'
    when 'v' then 'view'
    when 'm' then 'materialized_view'
    when 'f' then 'foreign_table'
    else c.relkind::text
  end as object_type,    -- TEXT is fine; this column already exists as text in your view
  g.privilege_type
from information_schema.role_table_grants g
join pg_namespace n
  on n.nspname = g.table_schema
join pg_class c
  on c.relnamespace = n.oid
 and c.relname = g.table_name
where g.table_schema='public'
  and g.grantee='authenticated'
  and g.privilege_type='SELECT'
order by g.table_name;

-- New view: anon SELECT surface (match same columns)
create view public.admin_anon_select_surface_v1 as
select
  g.table_schema,
  g.table_name,
  c.relkind as relkind,  -- CHAR(1)
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
where g.table_schema='public'
  and g.grantee='anon'
  and g.privilege_type='SELECT'
order by g.table_name;

-- New view: authenticated WRITE surface (match same columns)
create view public.admin_authenticated_write_surface_v1 as
select
  g.table_schema,
  g.table_name,
  c.relkind as relkind,  -- CHAR(1)
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
where g.table_schema='public'
  and g.grantee='authenticated'
  and g.privilege_type in ('INSERT','UPDATE','DELETE')
order by g.table_name, g.privilege_type;

commit;