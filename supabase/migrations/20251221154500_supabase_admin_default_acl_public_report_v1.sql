-- =========================================================
-- Hosted-safe: REPORT ONLY (no attempt to ALTER DEFAULT PRIVILEGES)
-- supabase_admin default privileges cannot be changed from project roles.
-- =========================================================

DO $$
DECLARE
  r RECORD;
BEGIN
  RAISE NOTICE 'INFO: Hosted projects cannot ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin. Reporting only.';

  FOR r IN
    SELECT
      pg_get_userbyid(d.defaclrole) AS defacl_role,
      n.nspname                    AS schema_name,
      d.defaclobjtype              AS objtype,
      d.defaclacl::text            AS acl
    FROM pg_default_acl d
    JOIN pg_namespace n ON n.oid = d.defaclnamespace
    WHERE n.nspname = 'public'
      AND pg_get_userbyid(d.defaclrole) = 'supabase_admin'
    ORDER BY 1,2,3
  LOOP
    RAISE NOTICE
      'default_acl: role=% schema=% objtype=% acl=%',
      r.defacl_role,
      r.schema_name,
      r.objtype,
      r.acl;
  END LOOP;
END $$;