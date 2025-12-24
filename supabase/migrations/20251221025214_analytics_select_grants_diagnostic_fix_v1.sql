begin;

create or replace view public.admin_analytics_select_grants_v1 as
select
  g.table_schema,
  g.table_name,
  g.grantee,
  g.privilege_type
from information_schema.role_table_grants g
where g.table_schema = 'public'
  and g.grantee in ('anon','authenticated')
  and g.privilege_type = 'SELECT'
  and (
    g.table_name ilike '%analytics%'
    or g.table_name ilike '%_stats%'
    or g.table_name ilike '%_metrics%'
  )
  -- allow the single guarded surface
  and g.table_name <> 'analytics_guarded_daily_v1'
order by g.grantee, g.table_name;

commit;