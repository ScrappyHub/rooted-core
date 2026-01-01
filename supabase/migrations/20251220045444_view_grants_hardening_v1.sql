-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- VIEW GRANTS HARDENING (public schema)
-- - views should never have INSERT/UPDATE/DELETE/TRUNCATE/TRIGGER/REFERENCES
-- - anon/authenticated should be SELECT-only on allowed views
-- =========================================================
do $$
declare
  v record;
begin
  -- 1) revoke everything for anon/authenticated on ALL views
  for v in
    select c.oid::regclass as fqvn
    from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relkind in ('v','m')  -- view or matview
  loop
    execute format('revoke all on %s from anon', v.fqvn);
    execute format('revoke all on %s from authenticated', v.fqvn);
  end loop;

  -- 2) re-grant SELECT ONLY to anon/authenticated on truly public views
  for v in
    select c.oid::regclass as fqvn, c.relname
    from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relkind in ('v','m')
      and (
        c.relname like '%_public_v1'
        or c.relname like '%_discovery_v1'
        or c.relname like '%_kids_v1'
        or c.relname like '%_kidsafe_v1'
        or c.relname like '%_public_info_%'
      )
  loop
    execute format('grant select on %s to anon', v.fqvn);
    execute format('grant select on %s to authenticated', v.fqvn);
  end loop;

  -- 3) authenticated-only SELECT on non-public user-facing views (NOT anon, NOT admin)
  for v in
    select c.oid::regclass as fqvn, c.relname
    from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relkind in ('v','m')
      and c.relname not like 'admin_%'
      and not (
        c.relname like '%_public_v1'
        or c.relname like '%_discovery_v1'
        or c.relname like '%_kids_v1'
        or c.relname like '%_kidsafe_v1'
        or c.relname like '%_public_info_%'
      )
      and (
        c.relname like 'user_%_v1'
        or c.relname like 'vendor_%_v1'
        or c.relname like 'market_%_v1'
        or c.relname like 'vertical_%_v1'
        or c.relname like 'community_%_v1'
        or c.relname like 'education_%_v1'
        or c.relname like 'arts_culture_%_v1'
        or c.relname like 'experience_%_v1'
        or c.relname like 'sanctuary_%_v1'
      )
  loop
    execute format('grant select on %s to authenticated', v.fqvn);
  end loop;

end;
$$;

commit;