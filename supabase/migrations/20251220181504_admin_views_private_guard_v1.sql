-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- ADMIN VIEWS PRIVATE GUARD (v1)
-- Ensures any public.admin_* views are NOT accessible to anon/authenticated.
-- Creates audit view:
--   public.admin_admin_view_grants_leak_v1  (should be empty)
-- =========================================================

-- Revoke on any existing admin_* views (safe even if none exist)
do $$
declare
  r record;
begin
  for r in
    select c.oid::regclass as obj
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public'
      and c.relkind='v'
      and c.relname like 'admin\_%' escape '\'
  loop
    execute format('revoke all on %s from anon', r.obj);
    execute format('revoke all on %s from authenticated', r.obj);
  end loop;
end;
$$;

drop view if exists public.admin_admin_view_grants_leak_v1;

create view public.admin_admin_view_grants_leak_v1 as
select
  g.table_schema,
  g.table_name,
  g.grantee,
  g.privilege_type
from information_schema.role_table_grants g
where g.table_schema='public'
  and g.table_name like 'admin\_%' escape '\'
  and g.grantee in ('anon','authenticated')
order by g.table_name, g.grantee, g.privilege_type;

-- keep audit view private too
revoke all on public.admin_admin_view_grants_leak_v1 from anon;
revoke all on public.admin_admin_view_grants_leak_v1 from authenticated;

commit;