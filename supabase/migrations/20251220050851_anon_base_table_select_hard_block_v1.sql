-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- HARD BLOCK: anon must NOT have privileges on base tables
-- public schema
-- =========================================================

do $$
declare
  t record;
begin
  -- revoke all privileges from anon on ALL base tables
  for t in
    select c.oid::regclass as fqtn
    from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relkind='r' -- base tables only
  loop
    execute format('revoke all on table %s from anon', t.fqtn);
  end loop;
end;
$$;

commit;