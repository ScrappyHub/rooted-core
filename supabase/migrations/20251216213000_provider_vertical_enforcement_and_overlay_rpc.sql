-- 20251216213000_provider_vertical_enforcement_and_overlay_rpc.sql
-- Purpose:
--  1) Enforce that providers.vertical / providers.primary_vertical are valid canonical verticals
--  2) Enforce that providers.specialty is valid specialty_types.code (when present)
--  3) Provide a service_role-only RPC to upsert overlay rows (respects overlay lock)

BEGIN;

-- ---------------------------------------------------------------------
-- A) Provider vertical + specialty validation (idempotent)
-- ---------------------------------------------------------------------

DO $$
BEGIN
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

  -- Check constraints (avoid empty-string garbage)
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

-- ---------------------------------------------------------------------
-- B) service_role-only overlay upsert RPC
--    NOTE: This assumes these columns exist on specialty_vertical_overlays.
--          If your overlay schema differs, this will fail clearly.
-- ---------------------------------------------------------------------

DO $$
BEGIN
  -- fail-fast if overlay columns mismatch
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public'
      AND table_name='specialty_vertical_overlays'
      AND column_name IN (
        'vertical_code','specialty_code',
        'created_at','created_by',
        'is_discovery_allowed','is_events_allowed','is_market_allowed',
        'requires_licensed','requires_insured',
        'kids_mode_visibility','teens_mode_visibility',
        'ads_allowed'
      )
  ) THEN
    RAISE EXCEPTION 'specialty_vertical_overlays schema mismatch: expected overlay policy columns + created_at/created_by + vertical_code/specialty_code';
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.overlay_upsert_service_role_only(
  p_vertical_code text,
  p_specialty_code text,
  p_is_discovery_allowed boolean DEFAULT NULL,
  p_is_events_allowed boolean DEFAULT NULL,
  p_is_market_allowed boolean DEFAULT NULL,
  p_requires_licensed boolean DEFAULT NULL,
  p_requires_insured boolean DEFAULT NULL,
  p_kids_mode_visibility text DEFAULT NULL,
  p_teens_mode_visibility text DEFAULT NULL,
  p_ads_allowed boolean DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF COALESCE(auth.role(), '') <> 'service_role' THEN
    RAISE EXCEPTION 'service_role only';
  END IF;

  INSERT INTO public.specialty_vertical_overlays (
    vertical_code,
    specialty_code,
    is_discovery_allowed,
    is_events_allowed,
    is_market_allowed,
    requires_licensed,
    requires_insured,
    kids_mode_visibility,
    teens_mode_visibility,
    ads_allowed,
    created_at,
    created_by
  )
  VALUES (
    p_vertical_code,
    p_specialty_code,
    p_is_discovery_allowed,
    p_is_events_allowed,
    p_is_market_allowed,
    p_requires_licensed,
    p_requires_insured,
    p_kids_mode_visibility,
    p_teens_mode_visibility,
    p_ads_allowed,
    now(),
    NULL
  )
  ON CONFLICT (vertical_code, specialty_code) DO UPDATE SET
    is_discovery_allowed  = COALESCE(EXCLUDED.is_discovery_allowed,  specialty_vertical_overlays.is_discovery_allowed),
    is_events_allowed     = COALESCE(EXCLUDED.is_events_allowed,     specialty_vertical_overlays.is_events_allowed),
    is_market_allowed     = COALESCE(EXCLUDED.is_market_allowed,     specialty_vertical_overlays.is_market_allowed),
    requires_licensed     = COALESCE(EXCLUDED.requires_licensed,     specialty_vertical_overlays.requires_licensed),
    requires_insured      = COALESCE(EXCLUDED.requires_insured,      specialty_vertical_overlays.requires_insured),
    kids_mode_visibility  = COALESCE(EXCLUDED.kids_mode_visibility,  specialty_vertical_overlays.kids_mode_visibility),
    teens_mode_visibility = COALESCE(EXCLUDED.teens_mode_visibility, specialty_vertical_overlays.teens_mode_visibility),
    ads_allowed           = COALESCE(EXCLUDED.ads_allowed,           specialty_vertical_overlays.ads_allowed);
END;
$$;

REVOKE ALL ON FUNCTION public.overlay_upsert_service_role_only(
  text,text,boolean,boolean,boolean,boolean,boolean,text,text,boolean
) FROM PUBLIC;

COMMIT;
