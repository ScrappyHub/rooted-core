-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- FORCE RLS ON ALL TABLES IN public
-- =========================================================
do $$
declare
  r record;
begin
  for r in
    select c.oid::regclass as fqtn
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public'
      and c.relkind='r'
  loop
    execute format('alter table %s enable row level security', r.fqtn);
    execute format('alter table %s force row level security', r.fqtn);
  end loop;
end;
$$;

commit;