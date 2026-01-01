-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- OPTIONAL: authenticated read paths must go through views
-- Remove direct SELECT on base tables (keep INSERT/UPDATE/DELETE)
-- =========================================================

do $$
declare
  t record;
begin
  for t in
    select c.oid::regclass as fqtn
    from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relkind='r'
  loop
    execute format('revoke select on table %s from authenticated', t.fqtn);
  end loop;
end;
$$;

commit;