begin;

-- =========================================================
-- ROUTINE EXECUTE + SECURITY DEFINER AUDIT (v1)
-- Hard rule: drop + create to avoid "cannot change type" errors.
-- =========================================================

drop view if exists public.admin_routine_execute_surface_v1;
drop view if exists public.admin_security_definer_functions_v1;

-- A) EXECUTE surface for anon/authenticated/public on routines in public schema
create view public.admin_routine_execute_surface_v1 as
select
  n.nspname::text                             as routine_schema,
  p.proname::text                             as routine_name,
  pg_get_function_identity_arguments(p.oid)::text as identity_args,
  case when p.prokind = 'p' then 'procedure' else 'function' end::text as routine_kind,
  r.rolname::text                             as grantee,
  a.privilege_type::text                      as privilege_type
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a on true
join pg_roles r on r.oid = a.grantee
where n.nspname = 'public'
  and a.privilege_type = 'EXECUTE'
  and r.rolname in ('anon','authenticated','public')
order by r.rolname, p.proname;

-- B) SECURITY DEFINER audit (high risk class)
create view public.admin_security_definer_functions_v1 as
select
  n.nspname::text                               as routine_schema,
  p.proname::text                               as routine_name,
  pg_get_function_identity_arguments(p.oid)::text as identity_args,
  pg_get_userbyid(p.proowner)::text             as owner,
  p.prosecdef                                   as security_definer,
  p.proleakproof                                as leakproof,
  (p.proconfig is not null)                     as has_proconfig,
  p.proconfig                                   as proconfig
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public'
  and p.prosecdef = true
order by p.proname;

commit;