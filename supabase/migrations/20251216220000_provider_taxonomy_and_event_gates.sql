-- ============================================================================
-- PROVIDER TAXONOMY + EVENT GATES (SAFE / GUARDED)
-- This file may run before base tables exist in some repos.
-- ============================================================================
DO $do$
BEGIN
  IF to_regclass('public.events') IS NULL THEN
    RAISE NOTICE 'Skipping event gates: public.events does not exist.';
    RETURN;
  END IF;

  -- Enable RLS safely (must be EXECUTE so it doesn't hard-fail at parse time)
  EXECUTE 'ALTER TABLE public.events ENABLE ROW LEVEL SECURITY';

  -- Add future policies/indexes here, inside this same guarded block.
  -- Example:
  -- IF NOT EXISTS (
  --   SELECT 1 FROM pg_policies
  --   WHERE schemaname = ''public''
  --     AND tablename  = ''events''
  --     AND policyname = ''my_policy_name''
  -- ) THEN
  --   EXECUTE 'CREATE POLICY my_policy_name ON public.events FOR SELECT USING (true)';
  -- END IF;

END
$do$;
