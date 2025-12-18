-- ============================================================================
-- PROVIDER TAXONOMY + EVENT GATES (SAFE / GUARDED)
-- This file may run before base tables exist in some repos.
-- ============================================================================

DO $$
DECLARE
  events_exists boolean := (to_regclass('public.events') IS NOT NULL);
BEGIN
  IF NOT events_exists THEN
    RAISE NOTICE 'Skipping event gates: public.events does not exist.';
    RETURN;
  END IF;

  -- Enable RLS safely
  EXECUTE 'ALTER TABLE public.events ENABLE ROW LEVEL SECURITY';

  -- If you add policies / indexes here later, keep them inside this same block.
  -- Example pattern:
  -- IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='events' AND policyname='...') THEN
  --   EXECUTE $$CREATE POLICY ...$$;
  -- END IF;
END
$$;
