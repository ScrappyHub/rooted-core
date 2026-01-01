-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
begin;

-- =========================================================
-- ANALYTICS LOCKDOWN SWEEP (v3)
-- Fixes:
--   - Drop/recreate admin_public_analytics_objects_v1 to avoid
--     CREATE OR REPLACE VIEW column rename errors.
-- Adds:
--   - analytics_guarded_daily_v1 (gate-controlled)
--   - admin diagnostics for remaining grants
-- =========================================================

-- 0) Drop conflicting admin view so we can recreate with new columns
drop view if exists public.admin_public_analytics_objects_v1 cascade;

-- 1) Identify analytics-like PUBLIC TABLES ONLY (not indexes/views)
create view public.admin_public_analytics_objects_v1 as
select
  n.nspname::text as table_schema,
  c.relname::text as table_name,
  c.relkind::text as relkind,
  c.relrowsecurity as rls_on,
  c.relforcerowsecurity as rls_forced,
  pg_get_userbyid(c.relowner)::text as owner
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind in ('r','p')  -- tables + partitioned tables
  and (
    c.relname ilike '%analytics%'
    or c.relname ilike '%_stats%'
    or c.relname ilike '%_metrics%'
  )
order by c.relname;

-- 2) Force RLS + revoke grants for anon/authenticated across these tables
do $$
declare r record;
begin
  for r in
    select format('%I.%I', table_schema, table_name) as fqtn
    from public.admin_public_analytics_objects_v1
  loop
    execute format('alter table %s enable row level security', r.fqtn);
    execute format('alter table %s force row level security', r.fqtn);

    execute format('revoke all on table %s from anon', r.fqtn);
    execute format('revoke all on table %s from authenticated', r.fqtn);
  end loop;
end;
$$;

-- 3) Admin diagnostics: any remaining SELECT grants?
drop view if exists public.admin_analytics_select_grants_v1 cascade;
create view public.admin_analytics_select_grants_v1 as
select
  g.table_schema,
  g.table_name,
  g.grantee,
  g.privilege_type
from information_schema.role_table_grants g
where g.table_schema='public'
  and g.grantee in ('anon','authenticated')
  and g.privilege_type='SELECT'
  and (
    g.table_name ilike '%analytics%'
    or g.table_name ilike '%_stats%'
    or g.table_name ilike '%_metrics%'
  )
order by g.grantee, g.table_name;

-- 4) Guarded unified access view (only returns rows when gate passes)
--    Uses UNION ALL across known tables. If a table is missing, migration would fail,
--    but we know these exist from your earlier output.
drop view if exists public.analytics_guarded_daily_v1 cascade;

create view public.analytics_guarded_daily_v1 as
with gate as (
  select public.can_access_analytics_v1('analytics_guarded_daily_v1') as ok
)
select * from (
  select 'vendor_analytics_daily'::text as source_table, to_jsonb(t.*) as row_data
  from public.vendor_analytics_daily t
  where (select ok from gate) = true

  union all
  select 'vendor_analytics_basic_daily'::text as source_table, to_jsonb(t.*) as row_data
  from public.vendor_analytics_basic_daily t
  where (select ok from gate) = true

  union all
  select 'vendor_analytics_advanced_daily'::text as source_table, to_jsonb(t.*) as row_data
  from public.vendor_analytics_advanced_daily t
  where (select ok from gate) = true

  union all
  select 'event_analytics_daily'::text as source_table, to_jsonb(t.*) as row_data
  from public.event_analytics_daily t
  where (select ok from gate) = true

  union all
  select 'seasonal_content_analytics_daily'::text as source_table, to_jsonb(t.*) as row_data
  from public.seasonal_content_analytics_daily t
  where (select ok from gate) = true

  union all
  select 'bulk_offer_analytics'::text as source_table, to_jsonb(t.*) as row_data
  from public.bulk_offer_analytics t
  where (select ok from gate) = true
) s;

revoke all on table public.analytics_guarded_daily_v1 from anon;
revoke all on table public.analytics_guarded_daily_v1 from authenticated;
grant select on table public.analytics_guarded_daily_v1 to authenticated;

commit;