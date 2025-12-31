-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- RLS GUARD: WRITE ALLOWLIST TABLES (v1)
-- Hard fail if any write-allowlisted table:
--   - missing, OR
--   - RLS not enabled, OR
--   - RLS not forced, OR
--   - has zero policies
-- =========================================================

do $$
declare
  t text;
  missing int := 0;
  no_rls int := 0;
  no_force int := 0;
  no_policies int := 0;
begin
  for t in
    select v.t from (values
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
    ) as v(t)
  loop
    -- missing?
    if not exists (
      select 1
      from pg_class c
      join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='public'
        and c.relname=t
        and c.relkind in ('r','p','f')
    ) then
      missing := missing + 1;
      continue;
    end if;

    -- rls enabled?
    if not exists (
      select 1
      from pg_class c
      join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='public'
        and c.relname=t
        and c.relrowsecurity=true
    ) then
      no_rls := no_rls + 1;
    end if;

    -- rls forced?
    if not exists (
      select 1
      from pg_class c
      join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='public'
        and c.relname=t
        and c.relforcerowsecurity=true
    ) then
      no_force := no_force + 1;
    end if;

    -- policies exist?
    if not exists (
      select 1
      from pg_policies p
      where p.schemaname='public'
        and p.tablename=t
    ) then
      no_policies := no_policies + 1;
    end if;
  end loop;

  if missing > 0 or no_rls > 0 or no_force > 0 or no_policies > 0 then
    raise exception
      'Hardening violation (write allowlist): missing=% no_rls=% no_force=% no_policies=%',
      missing, no_rls, no_force, no_policies;
  end if;
end;
$$;

commit;