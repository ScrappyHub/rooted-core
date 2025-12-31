-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- GRANTS GUARD: ANON SELECT ALLOWLIST (12 views) (v1)
-- Hard fail if anon has SELECT on anything outside the 12-view allowlist
-- =========================================================

do $$
declare
  bad int;
begin
  select count(*) into bad
  from information_schema.role_table_grants g
  where g.table_schema='public'
    and g.grantee='anon'
    and g.privilege_type='SELECT'
    and g.table_name not in (
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
      'Hardening violation: anon has SELECT outside 12-view allowlist (count=%).', bad;
  end if;
end;
$$;

commit;