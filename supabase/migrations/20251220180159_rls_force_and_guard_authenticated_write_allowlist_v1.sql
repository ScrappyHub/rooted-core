-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- RLS FORCE + GUARD: AUTHENTICATED WRITE ALLOWLIST (v1)
-- Goals:
-- 1) Ensure RLS is ENABLED + FORCED on the allowlisted write tables.
-- 2) Hard fail if:
--    - table missing
--    - RLS not enabled
--    - RLS not forced
--    - table has zero policies
-- Notes:
-- - This does NOT change policies.
-- - This does NOT change grants.
-- - This keeps "grants -> surface", RLS -> authority.
-- =========================================================

do $$
declare
  r record;
  cls record;
  pol_count int;
begin
  -- 1) Ensure RLS enabled + forced on allowlist tables
  for r in
    select t.table_name
    from (values
      ('account_deletion_requests'),
      ('conversation_participants'),
      ('conversations'),
      ('event_registrations'),
      ('experience_requests'),
      ('institution_applications'),
      ('messages'),
      ('user_consents'),
      ('user_devices'),
      ('vendor_applications')
    ) as t(table_name)
  loop
    -- must exist
    if to_regclass('public.' || r.table_name) is null then
      raise exception 'Hardening violation: missing allowlist table public.%', r.table_name;
    end if;

    execute format('alter table public.%I enable row level security', r.table_name);
    execute format('alter table public.%I force row level security',  r.table_name);
  end loop;

  -- 2) Guard checks: RLS enabled + forced + at least 1 policy
  for r in
    select t.table_name
    from (values
      ('account_deletion_requests'),
      ('conversation_participants'),
      ('conversations'),
      ('event_registrations'),
      ('experience_requests'),
      ('institution_applications'),
      ('messages'),
      ('user_consents'),
      ('user_devices'),
      ('vendor_applications')
    ) as t(table_name)
  loop
    select c.relrowsecurity, c.relforcerowsecurity
      into cls
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public'
      and c.relname = r.table_name
      and c.relkind in ('r','p');

    if cls.relrowsecurity is distinct from true then
      raise exception 'Hardening violation: RLS not enabled on public.%', r.table_name;
    end if;

    if cls.relforcerowsecurity is distinct from true then
      raise exception 'Hardening violation: RLS not forced on public.%', r.table_name;
    end if;

    select count(*) into pol_count
    from pg_policies p
    where p.schemaname='public'
      and p.tablename = r.table_name;

    if pol_count = 0 then
      raise exception 'Hardening violation: public.% has zero RLS policies', r.table_name;
    end if;
  end loop;
end;
$$;

commit;