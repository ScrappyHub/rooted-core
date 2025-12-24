begin;

-- =========================================================
-- ANALYTICS LOCKDOWN + GUARD (v1)
-- - Force RLS on any PUBLIC tables matching analytics-ish naming
-- - Revoke all grants on those tables from anon/authenticated
-- - Add a GUARD that hard-fails if any analytics-ish object becomes SELECTable
--   by anon/authenticated in public schema
-- =========================================================

-- 1) Force RLS on analytics-ish TABLES (not views)
do $$
declare r record;
begin
  for r in
    select c.oid::regclass as obj
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r','p') -- table or partitioned table
      and (
        c.relname ilike '%analytics%'
        or c.relname ilike '%_stats%'
        or c.relname ilike '%_metrics%'
        or c.relname ilike 'admin_%'
      )
  loop
    execute format('alter table %s enable row level security', r.obj);
    execute format('alter table %s force row level security', r.obj);

    execute format('revoke all on table %s from anon', r.obj);
    execute format('revoke all on table %s from authenticated', r.obj);
  end loop;
end $$;

-- 2) Guardrail: fail if any analytics-ish relation is SELECT-granted to anon/authenticated
--    (views or tables). This protects against accidental GRANTs in future migrations.
do $$
declare bad int;
begin
  select count(*) into bad
  from information_schema.role_table_grants g
  where g.table_schema='public'
    and g.privilege_type='SELECT'
    and g.grantee in ('anon','authenticated')
    and (
      g.table_name ilike '%analytics%'
      or g.table_name ilike '%_stats%'
      or g.table_name ilike '%_metrics%'
      or g.table_name ilike 'admin_%'
    );

  if bad > 0 then
    raise exception
      'Hardening violation: analytics-ish objects in public have SELECT grants to anon/authenticated.';
  end if;
end $$;

commit;