begin;

-- =========================================================
-- ADMIN REPORT VIEWS (RECREATE) (v1)
-- Purpose:
--   - drop + recreate admin audit views to avoid view type/shape conflicts
--   - these are admin-only diagnostic surfaces (not app-facing)
-- =========================================================

-- -------------------------
-- A) anon SELECT surface
-- -------------------------
drop view if exists public.admin_anon_select_surface_v1 cascade;

create view public.admin_anon_select_surface_v1 as
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
where g.table_schema='public'
  and g.grantee='anon'
  and g.privilege_type='SELECT'
order by g.table_name;

-- -------------------------
-- B) authenticated SELECT surface
-- -------------------------
drop view if exists public.admin_authenticated_select_surface_v1 cascade;

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
where g.table_schema='public'
  and g.grantee='authenticated'
  and g.privilege_type='SELECT'
order by g.table_name;

-- -------------------------
-- C) authenticated WRITE surface
-- -------------------------
drop view if exists public.admin_authenticated_write_surface_v1 cascade;

create view public.admin_authenticated_write_surface_v1 as
select
  g.table_schema,
  g.table_name,
  g.privilege_type
from information_schema.role_table_grants g
where g.table_schema='public'
  and g.grantee='authenticated'
  and g.privilege_type in ('INSERT','UPDATE','DELETE')
order by g.table_name, g.privilege_type;

-- -------------------------
-- D) routine EXECUTE surface (anon/auth/public) in public schema
-- -------------------------
drop view if exists public.admin_routine_execute_surface_v1 cascade;

create view public.admin_routine_execute_surface_v1 as
select
  n.nspname::text                              as routine_schema,
  p.proname::text                              as routine_name,
  pg_get_function_identity_arguments(p.oid)::text as identity_args,
  case when p.prokind = 'p' then 'procedure' else 'function' end::text as routine_kind,
  r.rolname::text                              as grantee,
  a.privilege_type::text                       as privilege_type
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a on true
join pg_roles r on r.oid = a.grantee
where n.nspname = 'public'
  and a.privilege_type = 'EXECUTE'
  and r.rolname in ('anon','authenticated','public')
order by r.rolname, p.proname;

-- -------------------------
-- E) SECURITY DEFINER function audit in public schema
-- -------------------------
drop view if exists public.admin_security_definer_functions_v1 cascade;

create view public.admin_security_definer_functions_v1 as
select
  n.nspname::text                              as routine_schema,
  p.proname::text                              as routine_name,
  pg_get_function_identity_arguments(p.oid)::text as identity_args,
  pg_get_userbyid(p.proowner)::text            as owner,
  p.prosecdef                                  as security_definer,
  (p.proconfig is not null)                    as has_proconfig,
  p.proconfig                                  as proconfig
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public'
  and p.prosecdef = true
order by p.proname;

commit;