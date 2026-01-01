-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- =========================================================
-- STORAGE RLS GUARD (AUTHORITATIVE v2)
-- Supabase Storage requires table GRANTs; security is via RLS.
--
-- This guard enforces ROOTED's intended posture:
--  - RLS must be ON for storage.objects + storage.buckets
--  - anon must have NO mutation policies (INSERT/UPDATE/DELETE)
--  - authenticated MAY mutate storage.objects ONLY via the 3 rooted policies,
--    and each must be bucket-gated by storage_bucket_policies.auth_write = true
-- =========================================================

DO $$
DECLARE
  rls_off int := 0;

  anon_mut int := 0;

  auth_mut_total int := 0;
  auth_mut_non_rooted int := 0;

  missing_rooted int := 0;
  bad_rooted_gating int := 0;

  -- allowlist
  rooted_insert text := 'rooted_storage_objects_auth_insert_v1';
  rooted_update text := 'rooted_storage_objects_auth_update_v1';
  rooted_delete text := 'rooted_storage_objects_auth_delete_v1';
BEGIN
  -- 1) Ensure RLS is enabled on storage.objects and storage.buckets
  SELECT count(*) INTO rls_off
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname='storage'
    AND c.relname IN ('objects','buckets')
    AND c.relkind='r'
    AND c.relrowsecurity = false;

  IF rls_off > 0 THEN
    RAISE EXCEPTION 'Hardening violation: RLS is OFF on storage.objects and/or storage.buckets.';
  END IF;

  -- 2) anon must have zero mutation policies on storage.*
  SELECT count(*) INTO anon_mut
  FROM pg_policies p
  WHERE p.schemaname='storage'
    AND p.cmd IN ('INSERT','UPDATE','DELETE')
    AND (p.roles @> ARRAY['anon']::name[]);

  IF anon_mut > 0 THEN
    RAISE EXCEPTION 'Hardening violation: anon has storage mutation policies (count=%).', anon_mut;
  END IF;

  -- 3) authenticated mutation policies: ONLY allow rooted allowlist on storage.objects
  SELECT count(*) INTO auth_mut_total
  FROM pg_policies p
  WHERE p.schemaname='storage'
    AND p.cmd IN ('INSERT','UPDATE','DELETE')
    AND (p.roles @> ARRAY['authenticated']::name[]);

  -- any authenticated mutation policy that is NOT one of the rooted allowlist OR not on storage.objects is forbidden
  SELECT count(*) INTO auth_mut_non_rooted
  FROM pg_policies p
  WHERE p.schemaname='storage'
    AND p.cmd IN ('INSERT','UPDATE','DELETE')
    AND (p.roles @> ARRAY['authenticated']::name[])
    AND NOT (
      p.tablename = 'objects'
      AND p.policyname IN (rooted_insert, rooted_update, rooted_delete)
    );

  IF auth_mut_non_rooted > 0 THEN
    RAISE EXCEPTION 'Hardening violation: authenticated has non-allowlisted storage mutation policies (count=%).', auth_mut_non_rooted;
  END IF;

  -- 4) rooted policies must exist (exactly these 3)
  SELECT count(*) INTO missing_rooted
  FROM (VALUES (rooted_insert),(rooted_update),(rooted_delete)) v(name)
  WHERE NOT EXISTS (
    SELECT 1 FROM pg_policies p
    WHERE p.schemaname='storage'
      AND p.tablename='objects'
      AND p.policyname=v.name
      AND p.cmd IN ('INSERT','UPDATE','DELETE')
      AND (p.roles @> ARRAY['authenticated']::name[])
  );

  IF missing_rooted > 0 THEN
    RAISE EXCEPTION 'Hardening violation: missing one or more required rooted authenticated mutation policies (missing=%).', missing_rooted;
  END IF;

  -- 5) rooted policies must be bucket-gated by storage_bucket_policies.auth_write = true
  -- We accept minor formatting differences; we simply require the string "storage_bucket_policies" AND "auth_write = true"
  SELECT count(*) INTO bad_rooted_gating
  FROM pg_policies p
  WHERE p.schemaname='storage'
    AND p.tablename='objects'
    AND p.policyname IN (rooted_insert, rooted_update, rooted_delete)
    AND p.cmd IN ('INSERT','UPDATE','DELETE')
    AND (
      (coalesce(p.qual,'') NOT ILIKE '%storage_bucket_policies%auth_write%true%')
      AND (coalesce(p.with_check,'') NOT ILIKE '%storage_bucket_policies%auth_write%true%')
    );

  -- For INSERT, gating is in with_check; for UPDATE, it's in both; for DELETE, it's in qual.
  -- The above check requires that at least ONE of qual/with_check carries the auth_write gate.
  IF bad_rooted_gating > 0 THEN
    RAISE EXCEPTION 'Hardening violation: rooted storage mutation policy gating is not auth_write=true (bad=%).', bad_rooted_gating;
  END IF;

  RAISE NOTICE 'OK: storage RLS posture matches ROOTED allowlist. auth_mut_total=%', auth_mut_total;
END;
$$;