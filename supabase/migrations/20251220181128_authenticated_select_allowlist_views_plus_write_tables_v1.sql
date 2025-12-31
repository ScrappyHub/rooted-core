-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- AUTHENTICATED SELECT: ALLOWLIST ONLY (v1)
-- Policy:
--   - authenticated gets NO SELECT on any public base table by default
--   - authenticated gets SELECT only on:
--       (A) the 12 public discovery views
--       (B) the 10 authenticated write tables (so app flows still work under RLS)
-- Notes:
--   - Does NOT change anon grants (your anon 12-view allowlist stays as-is)
--   - RLS remains authority for row-level access
-- =========================================================

do $$
declare
  r record;
begin
  -- Revoke SELECT from authenticated on ALL base relations in public (tables only)
  for r in
    select c.oid::regclass as obj
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public'
      and c.relkind in ('r','p','f')  -- tables, partitioned tables, foreign tables
  loop
    execute format('revoke select on %s from authenticated', r.obj);
  end loop;
end;
$$;

-- (A) Re-grant SELECT on the 12 public discovery views
DO $$
BEGIN
  IF to_regclass('public.arts_culture_events_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.arts_culture_events_discovery_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.arts_culture_events_discovery_v1 to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.arts_culture_providers_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.arts_culture_providers_discovery_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.arts_culture_providers_discovery_v1 to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.community_landmarks_kidsafe_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.community_landmarks_kidsafe_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.community_landmarks_kidsafe_v1 to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.community_providers_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.community_providers_discovery_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.community_providers_discovery_v1 to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.education_providers_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.education_providers_discovery_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.education_providers_discovery_v1 to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.events_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.events_discovery_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.events_discovery_v1 to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.events_public_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.events_public_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.events_public_v1 to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.experiences_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.experiences_discovery_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.experiences_discovery_v1 to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.landmarks_public_kids_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.landmarks_public_kids_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.landmarks_public_kids_v1 to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.landmarks_public_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.landmarks_public_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.landmarks_public_v1 to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.providers_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.providers_discovery_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.providers_discovery_v1 to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.providers_public_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.providers_public_v1 to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.providers_public_v1 to authenticated';
  END IF;
end;
$$;
-- (B) Re-grant SELECT on the authenticated write surface tables (RLS governs rows)
DO $$
BEGIN
  IF to_regclass('public.account_deletion_requests') IS NOT NULL THEN
    EXECUTE 'grant select on public.account_deletion_requests to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.account_deletion_requests to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.conversation_participants') IS NOT NULL THEN
    EXECUTE 'grant select on public.conversation_participants to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.conversation_participants to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.conversations') IS NOT NULL THEN
    EXECUTE 'grant select on public.conversations to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.conversations to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.event_registrations') IS NOT NULL THEN
    EXECUTE 'grant select on public.event_registrations to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.event_registrations to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.experience_requests') IS NOT NULL THEN
    EXECUTE 'grant select on public.experience_requests to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.experience_requests to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.institution_applications') IS NOT NULL THEN
    EXECUTE 'grant select on public.institution_applications to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.institution_applications to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.messages') IS NOT NULL THEN
    EXECUTE 'grant select on public.messages to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.messages to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.user_consents') IS NOT NULL THEN
    EXECUTE 'grant select on public.user_consents to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.user_consents to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.user_devices') IS NOT NULL THEN
    EXECUTE 'grant select on public.user_devices to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.user_devices to authenticated';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.vendor_applications') IS NOT NULL THEN
    EXECUTE 'grant select on public.vendor_applications to authenticated';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.vendor_applications to authenticated';
  END IF;
end;
$$;
commit;