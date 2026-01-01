-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
begin;

-- =========================================================
-- ADMIN ROLE STRING DIAGNOSTICS (v2)
-- Fix: avoid pg_get_functiondef() which is erroring in this environment.
-- Uses pg_proc.prosrc for function scanning.
-- =========================================================

drop view if exists public.admin_role_string_hits_v2;

create view public.admin_role_string_hits_v2 as
with policy_hits as (
  select
    'policy'::text as kind,
    p.schemaname   as schema_name,
    p.tablename    as object_name,
    p.policyname   as detail,
    (coalesce(p.qual,'') || ' ' || coalesce(p.with_check,'')) as excerpt
  from pg_policies p
  where p.schemaname='public'
    and (coalesce(p.qual,'') ilike '%individual%'
      or coalesce(p.with_check,'') ilike '%individual%')
),
function_hits as (
  select
    'function'::text as kind,
    n.nspname        as schema_name,
    p.proname        as object_name,
    null::text       as detail,
    p.prosrc         as excerpt
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.prosrc ilike '%individual%'
)
select * from policy_hits
union all
select * from function_hits;

revoke all on public.admin_role_string_hits_v2 from public;

-- NOTE: keep same behavior as your v1 for now; if you want admin-only weÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ll change grants next.
DO $$
BEGIN
  IF to_regclass('public.admin_role_string_hits_v2') IS NOT NULL THEN
    EXECUTE 'grant select on public.admin_role_string_hits_v2 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.admin_role_string_hits_v2 to authenticated';
  END IF;
end;
$$;
comment on view public.admin_role_string_hits_v2
is 'Admin diagnostics (v2): finds string "individual" in policies and in functions via pg_proc.prosrc (no pg_get_functiondef).';

commit;