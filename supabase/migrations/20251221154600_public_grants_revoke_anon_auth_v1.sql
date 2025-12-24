-- =========================================================
-- ENFORCE: Remove explicit anon/authenticated grants from public schema objects
-- Hosted-safe: REVOKE only (no attempt to ALTER DEFAULT PRIVILEGES for supabase_admin).
-- =========================================================

DO $$
DECLARE
  r RECORD;
BEGIN
  -- Always revoke schema usage/create first
  EXECUTE 'REVOKE ALL ON SCHEMA public FROM anon, authenticated';
  EXECUTE 'REVOKE USAGE ON SCHEMA public FROM anon, authenticated';

  -- Tables / Views / Matviews / Foreign tables / Partitioned tables
  FOR r IN
    SELECT n.nspname AS schema_name, c.relname AS object_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r','p','v','m','f')  -- table, partitioned table, view, matview, foreign table
  LOOP
    EXECUTE format('REVOKE ALL PRIVILEGES ON TABLE %I.%I FROM anon, authenticated', r.schema_name, r.object_name);
  END LOOP;

  -- Sequences
  FOR r IN
    SELECT n.nspname AS schema_name, c.relname AS object_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'S'
  LOOP
    EXECUTE format('REVOKE ALL PRIVILEGES ON SEQUENCE %I.%I FROM anon, authenticated', r.schema_name, r.object_name);
  END LOOP;

  -- Functions (revoke EXECUTE)
  FOR r IN
    SELECT
      n.nspname AS schema_name,
      p.proname AS func_name,
      pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
  LOOP
    EXECUTE format(
      'REVOKE ALL PRIVILEGES ON FUNCTION %I.%I(%s) FROM anon, authenticated',
      r.schema_name, r.func_name, r.args
    );
  END LOOP;

  RAISE NOTICE 'OK: revoked explicit anon/authenticated grants in public schema (objects + functions + schema).';
END $$;