-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- =========================================================
-- STORAGE ACL HARDENING (LAND-FIRST v2)
-- Purpose:
--  - Harden DEFAULT PRIVILEGES in schema storage
--  - Revoke denied privileges on existing storage objects
--  - DO NOT RAISE EXCEPTION (so changes COMMIT)
--
-- Denied: INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER, REFERENCES, MAINTAIN
-- =========================================================

-- 0) Ensure storage schema exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'storage') THEN
    RAISE EXCEPTION 'storage schema not found';
  END IF;
END

-- 1) Fix DEFAULT PRIVILEGES for any role that has defaults in storage
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT DISTINCT defaclrole::regrole::text AS owner_role
    FROM pg_default_acl d
    JOIN pg_namespace n ON n.oid = d.defaclnamespace
    WHERE n.nspname = 'storage'
  LOOP
    EXECUTE format(
      'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA storage REVOKE INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER, REFERENCES, MAINTAIN ON TABLES FROM anon, authenticated',
      r.owner_role
    );

    EXECUTE format(
      'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA storage REVOKE USAGE, UPDATE ON SEQUENCES FROM anon, authenticated',
      r.owner_role
    );

    EXECUTE format(
      'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA storage REVOKE EXECUTE ON FUNCTIONS FROM anon, authenticated',
      r.owner_role
    );

    RAISE NOTICE 'storage default privileges hardened for role=%', r.owner_role;
  END LOOP;
END

-- 2) Revoke denied privileges on existing TABLES/Views in storage (includes MAINTAIN)
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER, REFERENCES, MAINTAIN
ON ALL TABLES IN SCHEMA storage
FROM anon, authenticated;

-- 3) Revoke sequence privileges
REVOKE USAGE, UPDATE
ON ALL SEQUENCES IN SCHEMA storage
FROM anon, authenticated;

-- 4) Report remaining denied grants (NO EXCEPTION)
DO $$
DECLARE
  bad int := 0;
BEGIN
  SELECT count(*) INTO bad
  FROM information_schema.role_table_grants g
  WHERE g.table_schema = 'storage'
    AND g.grantee IN ('anon','authenticated')
    AND g.privilege_type = ANY (ARRAY[
      'INSERT','UPDATE','DELETE','TRUNCATE','TRIGGER','REFERENCES','MAINTAIN'
    ]);

  RAISE NOTICE 'storage denied-grants remaining AFTER sweep (target 0): %', bad;
END
$$;