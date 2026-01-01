-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- =========================================================
-- STORAGE POSTURE GUARD (AUTHORITATIVE v1)
-- Rooted stance:
--  - Supabase Storage requires broad GRANTs to anon/authenticated.
--  - Security is enforced by RLS + policies.
--
-- Enforces:
--  1) RLS must be ON for storage.objects, storage.buckets, storage.prefixes
--  2) anon has NO mutation policies anywhere in storage
--  3) authenticated mutation policies are ONLY these 3 on storage.objects:
--       - rooted_storage_objects_auth_insert_v1
--       - rooted_storage_objects_auth_update_v1
--       - rooted_storage_objects_auth_delete_v1
--  4) Those 3 policies must be bucket-gated by storage_bucket_policies.auth_write = true
-- =========================================================

DO $$
DECLARE
  rls_off int := 0;

  anon_mut int := 0;

  auth_mut_non_allow int := 0;
  missing_rooted int := 0;
  bad_rooted_gating int := 0;

  rooted_insert text := 'rooted_storage_objects_auth_insert_v1';
  rooted_update text := 'rooted_storage_objects_auth_update_v1';
  rooted_delete text := 'rooted_storage_objects_auth_delete_v1';
BEGIN
  -- 1) RLS must be ON for critical storage tables
  SELECT count(*) INTO rls_off
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname='storage'
    AND c.relkind='r'
    AND c.relname IN ('objects','buckets','prefixes')
    AND c.relrowsecurity = false;

  IF rls_off > 0 THEN
    RAISE EXCEPTION 'Hardening violation: RLS is OFF on one or more storage tables (objects/buckets/prefixes).';
  END IF;

  -- 2) anon must have zero mutation policies anywhere in storage
  SELECT count(*) INTO anon_mut
  FROM pg_policies p
  WHERE p.schemaname='storage'
    AND p.cmd IN ('INSERT','UPDATE','DELETE')
    AND (p.roles @> ARRAY['anon']::name[]);

  IF anon_mut > 0 THEN
    RAISE EXCEPTION 'Hardening violation: anon has storage mutation policies (count=%).', anon_mut;
  END IF;

  -- 3) authenticated mutation policies must be ONLY allowlisted, only on storage.objects
  SELECT count(*) INTO auth_mut_non_allow
  FROM pg_policies p
  WHERE p.schemaname='storage'
    AND p.cmd IN ('INSERT','UPDATE','DELETE')
    AND (p.roles @> ARRAY['authenticated']::name[])
    AND NOT (
      p.tablename = 'objects'
      AND p.policyname IN (rooted_insert, rooted_update, rooted_delete)
    );

  IF auth_mut_non_allow > 0 THEN
    RAISE EXCEPTION 'Hardening violation: authenticated has non-allowlisted storage mutation policies (count=%).', auth_mut_non_allow;
  END IF;

  -- 4) rooted policies must exist (all 3)
  SELECT count(*) INTO missing_rooted
  FROM (VALUES (rooted_insert),(rooted_update),(rooted_delete)) v(name)
  WHERE NOT EXISTS (
    SELECT 1
    FROM pg_policies p
    WHERE p.schemaname='storage'
      AND p.tablename='objects'
      AND p.policyname=v.name
      AND p.cmd IN ('INSERT','UPDATE','DELETE')
      AND (p.roles @> ARRAY['authenticated']::name[])
  );

  IF missing_rooted > 0 THEN
    RAISE EXCEPTION 'Hardening violation: missing required rooted authenticated mutation policies (missing=%).', missing_rooted;
  END IF;

  -- 5) rooted policies must be bucket-gated by storage_bucket_policies.auth_write = true
  -- We accept formatting variance, but require the presence of:
  --   storage_bucket_policies  AND  auth_write  AND  true
  -- in either qual or with_check (INSERT gates with_check; DELETE gates qual; UPDATE often both).
  SELECT count(*) INTO bad_rooted_gating
  FROM pg_policies p
  WHERE p.schemaname='storage'
    AND p.tablename='objects'
    AND p.policyname IN (rooted_insert, rooted_update, rooted_delete)
    AND p.cmd IN ('INSERT','UPDATE','DELETE')
    AND (
      (coalesce(p.qual,'')       NOT ILIKE '%storage_bucket_policies%auth_write%true%')
      AND
      (coalesce(p.with_check,'') NOT ILIKE '%storage_bucket_policies%auth_write%true%')
    );

  IF bad_rooted_gating > 0 THEN
    RAISE EXCEPTION 'Hardening violation: rooted storage mutation policy gating missing auth_write=true (bad=%).', bad_rooted_gating;
  END IF;

  RAISE NOTICE 'OK: storage posture guard passed (Rooted policy allowlist enforced).';
END;
$$;