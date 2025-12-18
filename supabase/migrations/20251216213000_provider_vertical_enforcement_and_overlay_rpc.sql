-- ============================================================================
-- PROVIDER VERTICAL ENFORCEMENT + OVERLAY RPC (SAFE / GUARDED)
-- Single guarded DO block so missing tables cannot break startup.
-- ============================================================================

DO $$
DECLARE
  providers_exists boolean := (to_regclass('public.providers') IS NOT NULL);
  specialty_exists boolean := (to_regclass('public.specialty_types') IS NOT NULL);
BEGIN
  IF NOT providers_exists THEN
    RAISE NOTICE 'Skipping provider enforcement: public.providers does not exist.';
    RETURN;
  END IF;

  IF NOT specialty_exists THEN
    RAISE NOTICE 'Skipping provider enforcement: public.specialty_types does not exist.';
    RETURN;
  END IF;

  -- FK: providers.vertical -> canonical_verticals.vertical_code
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'providers_vertical_fkey'
      AND conrelid = 'public.providers'::regclass
  ) THEN
    ALTER TABLE public.providers
      ADD CONSTRAINT providers_vertical_fkey
      FOREIGN KEY (vertical)
      REFERENCES public.canonical_verticals (vertical_code);
  END IF;

  -- FK: providers.primary_vertical -> canonical_verticals.vertical_code
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'providers_primary_vertical_fkey'
      AND conrelid = 'public.providers'::regclass
  ) THEN
    ALTER TABLE public.providers
      ADD CONSTRAINT providers_primary_vertical_fkey
      FOREIGN KEY (primary_vertical)
      REFERENCES public.canonical_verticals (vertical_code);
  END IF;

  -- FK: providers.specialty -> specialty_types.code
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'providers_specialty_fkey'
      AND conrelid = 'public.providers'::regclass
  ) THEN
    ALTER TABLE public.providers
      ADD CONSTRAINT providers_specialty_fkey
      FOREIGN KEY (specialty)
      REFERENCES public.specialty_types (code);
  END IF;

  -- Prevent blank garbage
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'providers_vertical_not_blank_chk'
      AND conrelid = 'public.providers'::regclass
  ) THEN
    ALTER TABLE public.providers
      ADD CONSTRAINT providers_vertical_not_blank_chk
      CHECK (vertical IS NULL OR btrim(vertical) <> '');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'providers_primary_vertical_not_blank_chk'
      AND conrelid = 'public.providers'::regclass
  ) THEN
    ALTER TABLE public.providers
      ADD CONSTRAINT providers_primary_vertical_not_blank_chk
      CHECK (primary_vertical IS NULL OR btrim(primary_vertical) <> '');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'providers_specialty_not_blank_chk'
      AND conrelid = 'public.providers'::regclass
  ) THEN
    ALTER TABLE public.providers
      ADD CONSTRAINT providers_specialty_not_blank_chk
      CHECK (specialty IS NULL OR btrim(specialty) <> '');
  END IF;
END
$$;
