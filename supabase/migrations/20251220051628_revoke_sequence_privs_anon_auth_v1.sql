-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

do $$
declare
  s record;
begin
  for s in
    select c.oid::regclass as fqsn
    from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relkind='S'
  loop
    execute format('revoke all on sequence %s from anon', s.fqsn);
    execute format('revoke all on sequence %s from authenticated', s.fqsn);
  end loop;
end;
$$;

commit;