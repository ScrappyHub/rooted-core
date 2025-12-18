-- ============================================================================
-- EVENTS HOST / VENDOR GATES v1 (SAFE / GUARDED)
-- This file may run before base tables exist in some repos.
-- ============================================================================
DO $do$
BEGIN
  IF to_regclass('public.events') IS NULL THEN
    RAISE NOTICE 'Skipping events host/vendor gates: public.events does not exist.';
    RETURN;
  END IF;

  -- Enable RLS safely
  EXECUTE 'ALTER TABLE public.events ENABLE ROW LEVEL SECURITY';

  -- If this migration adds policies, they MUST be inside this same guard.
  -- Example safe pattern:
  -- IF NOT EXISTS (
  --   SELECT 1 FROM pg_policies
  --   WHERE schemaname = ''public''
  --     AND tablename  = ''events''
  --     AND policyname = ''events_select_policy_v1''
  -- ) THEN
  --   EXECUTE 'CREATE POLICY events_select_policy_v1 ON public.events FOR SELECT USING (true)';
  -- END IF;

END
$do$;
