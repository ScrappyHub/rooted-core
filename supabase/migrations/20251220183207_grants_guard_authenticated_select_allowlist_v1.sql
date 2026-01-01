-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- GRANTS GUARD: AUTHENTICATED SELECT ALLOWLIST (v1)
-- Hard fail if authenticated has SELECT outside:
--   - 12 discovery views
--   - 10 write tables
-- =========================================================

do $$
declare
  bad int;
begin
  select count(*) into bad
  from information_schema.role_table_grants g
  where g.table_schema='public'
    and g.grantee='authenticated'
    and g.privilege_type='SELECT'
    and g.table_name not in (
      -- 10 write tables
      'account_deletion_requests',
      'conversation_participants',
      'conversations',
      'event_registrations',
      'experience_requests',
      'institution_applications',
      'messages',
      'user_consents',
      'user_devices',
      'vendor_applications',
      -- 12 discovery views
      'arts_culture_events_discovery_v1',
      'arts_culture_providers_discovery_v1',
      'community_landmarks_kidsafe_v1',
      'community_providers_discovery_v1',
      'education_providers_discovery_v1',
      'events_discovery_v1',
      'events_public_v1',
      'experiences_discovery_v1',
      'landmarks_public_kids_v1',
      'landmarks_public_v1',
      'providers_discovery_v1',
      'providers_public_v1'
    );

  if bad > 0 then
    raise exception
      'Hardening violation: authenticated has SELECT outside allowlist (count=%).', bad;
  end if;
end;
$$;

commit;