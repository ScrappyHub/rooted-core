-- 20251216204500_seed_new_vertical_specialties.sql
-- Purpose:
--   Seed minimal canonical specialty mappings for newly added vertical codes.
--
-- IMPORTANT GOVERNANCE:
--   - DO NOT write to public.specialty_vertical_overlays in migrations.
--     That table is intentionally locked (service_role only) and will fail via guard triggers.
--   - This migration ONLY writes to public.vertical_canonical_specialties.
--
-- Safe + idempotent:
--   INSERT ... ON CONFLICT DO NOTHING
--   No RLS/policy changes.

BEGIN;

-- ---------------------------------------------------------------------
-- A) Guard rails: fail fast if the tables/columns aren't what we expect
-- ---------------------------------------------------------------------
DO $$
BEGIN
  -- vertical_canonical_specialties must support these columns.
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'vertical_canonical_specialties'
      AND column_name IN ('vertical_code','specialty_code','is_default')
  ) THEN
    RAISE EXCEPTION 'vertical_canonical_specialties schema mismatch (expected vertical_code, specialty_code, is_default)';
  END IF;

  -- Ensure the placeholder specialty exists.
  IF NOT EXISTS (
    SELECT 1
    FROM public.specialty_types st
    WHERE st.code = 'ROOTED_PLATFORM_CANONICAL'
  ) THEN
    RAISE EXCEPTION 'Missing specialty_types.code = ROOTED_PLATFORM_CANONICAL (required placeholder)';
  END IF;
END $$;

-- ---------------------------------------------------------------------
-- B) Minimal canonical mappings (placeholder default specialty)
--    (These are NOT overlays. Overlays are service_role-only by design.)
-- ---------------------------------------------------------------------
INSERT INTO public.vertical_canonical_specialties (vertical_code, specialty_code, is_default)
VALUES
  ('WELLNESS_FAMILY_SENIORS',  'ROOTED_PLATFORM_CANONICAL', true),
  ('FITNESS_ACTIVE_LIVING',    'ROOTED_PLATFORM_CANONICAL', true),
  ('SPORTS_COMMUNITY',         'ROOTED_PLATFORM_CANONICAL', true),
  ('LOCAL_BUSINESS_DISCOVERY', 'ROOTED_PLATFORM_CANONICAL', true),
  ('CELEBRATIONS_EVENTS',      'ROOTED_PLATFORM_CANONICAL', true)
ON CONFLICT (vertical_code, specialty_code) DO NOTHING;

COMMIT;
