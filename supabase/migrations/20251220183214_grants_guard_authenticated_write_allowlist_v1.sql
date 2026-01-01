-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- GRANTS GUARD: AUTHENTICATED WRITE ALLOWLIST (v1)
-- Hard fail if authenticated has INSERT/UPDATE/DELETE on any table
-- outside the write allowlist.
-- =========================================================

do $$
declare
  bad int;
begin
  select count(*) into bad
  from information_schema.role_table_grants g
  where g.table_schema='public'
    and g.grantee='authenticated'
    and g.privilege_type in ('INSERT','UPDATE','DELETE')
    and g.table_name not in (
      'account_deletion_requests',
      'conversation_participants',
      'conversations',
      'event_registrations',
      'experience_requests',
      'institution_applications',
      'messages',
      'user_consents',
      'user_devices',
      'vendor_applications'
    );

  if bad > 0 then
    raise exception
      'Hardening violation: authenticated has WRITE outside allowlist (count=%).', bad;
  end if;
end;
$$;

commit;