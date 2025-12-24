begin;

-- =========================================================
-- ANALYTICS ACCESS GATE FRAMEWORK (v1)
-- Goal:
--   - Centralize analytics permission decisions in ONE function
--   - Provide admin audit views to see analytics exposure surfaces
-- Notes:
--   - Does not change any existing analytics view definitions yet
--   - Does not drop anything
-- =========================================================

-- 1) Canonical gate function
-- Rules (tight + extensible):
--   - service_role always allowed
--   - admin role allowed
--   - vendor/institution allowed if tier in (premium, premium_plus)
--   - individuals allowed only if you later explicitly opt-in (currently false)
create or replace function public.can_access_analytics_v1(
  p_context text default null
)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  u uuid := auth.uid();
  r text;
  t text;
begin
  -- service_role bypass (server side only)
  if current_role = 'service_role' then
    return true;
  end if;

  if u is null then
    return false;
  end if;

  select ut.role, ut.tier
    into r, t
  from public.user_tiers ut
  where ut.user_id = u;

  -- hard deny if missing record
  if r is null then
    return false;
  end if;

  if r = 'admin' then
    return true;
  end if;

  if r in ('vendor','institution') and t in ('premium','premium_plus') then
    return true;
  end if;

  return false;
end $$;

revoke all on function public.can_access_analytics_v1(text) from anon;
revoke all on function public.can_access_analytics_v1(text) from authenticated;
grant execute on function public.can_access_analytics_v1(text) to service_role;

-- Optional: allow authenticated to call the gate (useful inside view RLS patterns)
-- (Safe because function returns boolean only)
grant execute on function public.can_access_analytics_v1(text) to authenticated;

-- 2) Admin audit view: show tables/views in public that look like analytics surfaces
drop view if exists public.admin_public_analytics_objects_v1 cascade;
create view public.admin_public_analytics_objects_v1 as
select
  n.nspname::text as schema_name,
  c.relname::text as object_name,
  case c.relkind
    when 'r' then 'table'
    when 'p' then 'partitioned_table'
    when 'v' then 'view'
    when 'm' then 'materialized_view'
    else c.relkind::text
  end as object_type,
  pg_get_userbyid(c.relowner)::text as owner
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and (
    c.relname ilike '%analytics%'
    or c.relname ilike '%_stats%'
    or c.relname ilike '%_metrics%'
    or c.relname ilike 'admin_%'
  )
order by object_type, object_name;

-- 3) Admin audit view: which analytics-ish objects have SELECT grants to anon/authenticated
drop view if exists public.admin_analytics_select_grants_v1 cascade;
create view public.admin_analytics_select_grants_v1 as
select
  g.table_schema,
  g.table_name,
  g.grantee,
  g.privilege_type
from information_schema.role_table_grants g
where g.table_schema = 'public'
  and g.privilege_type = 'SELECT'
  and g.grantee in ('anon','authenticated')
  and (
    g.table_name ilike '%analytics%'
    or g.table_name ilike '%_stats%'
    or g.table_name ilike '%_metrics%'
    or g.table_name ilike 'admin_%'
  )
order by g.grantee, g.table_name;

-- 4) Admin audit view: routine EXECUTE grants that might expose analytics
drop view if exists public.admin_analytics_routine_exec_grants_v1 cascade;
create view public.admin_analytics_routine_exec_grants_v1 as
select
  n.nspname::text as routine_schema,
  p.proname::text as routine_name,
  pg_get_function_identity_arguments(p.oid)::text as identity_args,
  case when p.prokind = 'p' then 'procedure' else 'function' end::text as routine_kind,
  r.rolname::text as grantee,
  a.privilege_type::text as privilege_type
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a on true
join pg_roles r on r.oid = a.grantee
where n.nspname = 'public'
  and a.privilege_type = 'EXECUTE'
  and r.rolname in ('anon','authenticated','public')
  and (
    p.proname ilike '%analytics%'
    or p.proname ilike '%stats%'
    or p.proname ilike '%metrics%'
  )
order by r.rolname, p.proname;

commit;