-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- For any public table with RLS enabled but 0 policies,
-- create a service_role manage policy (ALL) so backend can operate.
-- =========================================================
do $$
declare
  r record;
  pol text;
begin
  for r in
    select n.nspname as schemaname, c.relname as tablename
    from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    left join (
      select schemaname, tablename, count(*) as policy_count
      from pg_policies
      group by schemaname, tablename
    ) p on p.schemaname=n.nspname and p.tablename=c.relname
    where n.nspname='public'
      and c.relkind='r'
      and c.relrowsecurity = true
      and coalesce(p.policy_count,0) = 0
  loop
    pol := format('%s_service_role_manage_v1', r.tablename);

    execute format(
      'create policy %I on %I.%I for all to service_role using (true) with check (true);',
      pol, r.schemaname, r.tablename
    );
  end loop;
end;
$$;

commit;