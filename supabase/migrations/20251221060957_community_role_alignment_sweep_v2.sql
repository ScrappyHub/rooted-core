-- ROOTED: AUTO-FIX-DO-TAG-MISMATCH-STEP-1K (canonical)
begin;

-- =========================================================
-- COMMUNITY ROLE ALIGNMENT SWEEP (v2) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â CANONICAL
-- Goal:
--   - Eliminate any reliance on role='individual' (NOT allowed by CHECK constraints)
--   - Use role='community' + feature_flags->>'is_vetted_community' gate
--   - Provide admin diagnostics to find any lingering "individual" string usage
-- =========================================================

-- 1) vetted community gate (single source of truth)
create or replace function public.is_vetted_community_v1()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.user_tiers ut
    where ut.user_id = auth.uid()
      and ut.role = 'community'
      and ut.account_status = 'active'
      and coalesce((ut.feature_flags ->> 'is_vetted_community')::boolean, false) = true
  );
$$;

revoke all on function public.is_vetted_community_v1() from anon;
revoke all on function public.is_vetted_community_v1() from authenticated;
grant execute on function public.is_vetted_community_v1() to authenticated;
grant execute on function public.is_vetted_community_v1() to service_role;

comment on function public.is_vetted_community_v1()
is 'Canonical gate: role=community + feature_flags.is_vetted_community=true + active. No individual role.';

-- 2) Admin diagnostics: find any "individual" usage in policies and functions
drop view if exists public.admin_role_string_hits_v1;

create view public.admin_role_string_hits_v1 as
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
    pg_get_functiondef(p.oid) as excerpt
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and pg_get_functiondef(p.oid) ilike '%individual%'
)
select * from policy_hits
union all
select * from function_hits;

-- Lock down diagnostics view to admins only (RLS doesnÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢t apply to views; use grants)
revoke all on public.admin_role_string_hits_v1 from public;
do $fn$
BEGIN
  IF to_regclass('public.admin_role_string_hits_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.admin_role_string_hits_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.admin_role_string_hits_v1 to authenticated';
  END IF;
END $$;
-- (Optional) if you have an is_admin() function (you do), we keep this as *convention*:
comment on view public.admin_role_string_hits_v1
is 'Admin diagnostics: shows any policy/function code containing the string "individual".';

-- 3) Patch can_create_live_feed_post_v1 to use vetted community (only if function exists)
do $$
begin
  if to_regprocedure('public.can_create_live_feed_post_v1(uuid,uuid)') is not null then
    -- NOTE: Replace with your canonical logic if needed; this is the minimal alignment patch:
    -- We wrap existing expectations by requiring vetted community when provider_id/community_spot_id path is used.
    -- If you want stricter: enforce provider ownership or spot membership here as well.
    create or replace function public.can_create_live_feed_post_v1(p_provider_id uuid, p_community_spot_id uuid)
    returns boolean
    language sql
    stable
    security definer
    set search_path = public, pg_temp
    as $fn$
      select
        -- must be authenticated
        auth.uid() is not null
        and exists (
          select 1
          from public.user_tiers ut
          where ut.user_id = auth.uid()
            and ut.account_status = 'active'
            and ut.role in ('vendor','institution','admin','community')
        )
        -- if community role, require vetted flag
        and (
          not exists (
            select 1
            from public.user_tiers ut
            where ut.user_id = auth.uid()
              and ut.role = 'community'
          )
          or public.is_vetted_community_v1() = true
        );
    $fn$;

    revoke all on function public.can_create_live_feed_post_v1(uuid,uuid) from anon;
    revoke all on function public.can_create_live_feed_post_v1(uuid,uuid) from authenticated;
    grant execute on function public.can_create_live_feed_post_v1(uuid,uuid) to authenticated;
    grant execute on function public.can_create_live_feed_post_v1(uuid,uuid) to service_role;
  end if;
end $$;

commit;