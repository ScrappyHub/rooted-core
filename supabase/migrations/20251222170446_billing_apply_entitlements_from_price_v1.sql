BEGIN;

-- ============================================================
-- Billing â†’ Entitlements application (service/admin only)
-- Inputs:
--   - stripe_price_id  OR  price_key
-- Behavior:
--   - Finds billing_prices row
--   - Applies billing_entitlements for that product_key
--   - If entitlement has role+tier, calls apply_subscription_features(user, role, tier)
--   - Preserves existing feature_flags; ensures is_kids_mode is not overwritten
--   - Merges entitlement.feature_flags on top
-- ============================================================

-- Helper: assert caller is service_role OR admin
CREATE OR REPLACE FUNCTION public._assert_service_or_admin()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_role text;
BEGIN
  v_role := current_setting('request.jwt.claim.role', true);

  IF NOT (v_role = 'service_role' OR public.is_admin()) THEN
    RAISE EXCEPTION 'not authorized';
  END IF;
END;
$fn$;

COMMENT ON FUNCTION public._assert_service_or_admin()
IS 'Internal guard: only service_role JWTs or admins may call service billing mutation functions.';

-- Core worker: apply entitlements given a product_key
CREATE OR REPLACE FUNCTION public.service_apply_entitlements_from_product_key(
  p_user_id uuid,
  p_product_key text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_existing_flags jsonb;
  v_base_flags jsonb;
  v_final_flags jsonb;
  v_existing_is_kids jsonb;

  v_any_entitlement boolean := false;

  r_ent record;
BEGIN
  PERFORM public._assert_service_or_admin();

  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'p_user_id is required';
  END IF;

  IF p_product_key IS NULL OR length(trim(p_product_key)) = 0 THEN
    RAISE EXCEPTION 'p_product_key is required';
  END IF;

  -- Load current flags (before we call apply_subscription_features which overwrites)
  SELECT ut.feature_flags
  INTO v_existing_flags
  FROM public.user_tiers ut
  WHERE ut.user_id = p_user_id;

  v_existing_flags := COALESCE(v_existing_flags, '{}'::jsonb);

  -- preserve is_kids_mode explicitly (apply_subscription_features sets it false)
  IF (v_existing_flags ? 'is_kids_mode') THEN
    v_existing_is_kids := v_existing_flags->'is_kids_mode';
  ELSE
    v_existing_is_kids := NULL;
  END IF;

  -- Apply each active entitlement for this product_key
  FOR r_ent IN
    SELECT
      e.entitlement_key,
      e.role,
      e.tier,
      COALESCE(e.feature_flags, '{}'::jsonb) AS feature_flags
    FROM public.billing_entitlements e
    WHERE e.product_key = p_product_key
      AND COALESCE(e.is_active, true) = true
  LOOP
    v_any_entitlement := true;

    -- If role+tier provided, apply canonical subscription features (overwrites flags)
    IF r_ent.role IS NOT NULL AND r_ent.tier IS NOT NULL THEN
      PERFORM public.apply_subscription_features(p_user_id, r_ent.role, r_ent.tier);
    END IF;

    -- Pull the "base" flags after apply_subscription_features (or current if not called)
    SELECT ut.feature_flags
    INTO v_base_flags
    FROM public.user_tiers ut
    WHERE ut.user_id = p_user_id;

    v_base_flags := COALESCE(v_base_flags, '{}'::jsonb);

    -- Merge strategy (canonical):
    --   1) start with existing user flags
    --   2) overlay base subscription flags (tier keys win over existing for those keys)
    --   3) restore is_kids_mode from existing (never clobber kids mode)
    --   4) overlay entitlement.feature_flags (entitlements can add/override)
    v_final_flags := v_existing_flags || v_base_flags;

    IF v_existing_is_kids IS NOT NULL THEN
      v_final_flags := (v_final_flags - 'is_kids_mode') || jsonb_build_object('is_kids_mode', v_existing_is_kids);
    END IF;

    v_final_flags := v_final_flags || COALESCE(r_ent.feature_flags, '{}'::jsonb);

    -- Write merged flags back (DO NOT touch tier/role here; apply_subscription_features already did if needed)
    UPDATE public.user_tiers ut
    SET
      feature_flags = v_final_flags,
      updated_at    = now()
    WHERE ut.user_id = p_user_id;
  END LOOP;

  IF NOT v_any_entitlement THEN
    RAISE EXCEPTION 'No active entitlements for product_key=%', p_product_key;
  END IF;
END;
$fn$;

COMMENT ON FUNCTION public.service_apply_entitlements_from_product_key(uuid, text)
IS 'Service/admin-only. Applies billing_entitlements for a product_key. Preserves existing flags (especially is_kids_mode), overlays tier flags + entitlement flags.';

-- Apply by stripe_price_id
CREATE OR REPLACE FUNCTION public.service_apply_entitlements_from_stripe_price(
  p_user_id uuid,
  p_stripe_price_id text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_product_key text;
BEGIN
  PERFORM public._assert_service_or_admin();

  IF p_stripe_price_id IS NULL OR length(trim(p_stripe_price_id)) = 0 THEN
    RAISE EXCEPTION 'p_stripe_price_id is required';
  END IF;

  SELECT bp.product_key
  INTO v_product_key
  FROM public.billing_prices bp
  WHERE bp.stripe_price_id = p_stripe_price_id
    AND COALESCE(bp.is_active, true) = true
  LIMIT 1;

  IF v_product_key IS NULL THEN
    RAISE EXCEPTION 'Active price not found for stripe_price_id=%', p_stripe_price_id;
  END IF;

  PERFORM public.service_apply_entitlements_from_product_key(p_user_id, v_product_key);
END;
$fn$;

COMMENT ON FUNCTION public.service_apply_entitlements_from_stripe_price(uuid, text)
IS 'Service/admin-only. Maps stripe_price_id â†’ billing_prices.product_key â†’ applies entitlements.';

-- Apply by price_key
CREATE OR REPLACE FUNCTION public.service_apply_entitlements_from_price_key(
  p_user_id uuid,
  p_price_key text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_product_key text;
BEGIN
  PERFORM public._assert_service_or_admin();

  IF p_price_key IS NULL OR length(trim(p_price_key)) = 0 THEN
    RAISE EXCEPTION 'p_price_key is required';
  END IF;

  SELECT bp.product_key
  INTO v_product_key
  FROM public.billing_prices bp
  WHERE bp.price_key = p_price_key
    AND COALESCE(bp.is_active, true) = true
  LIMIT 1;

  IF v_product_key IS NULL THEN
    RAISE EXCEPTION 'Active price not found for price_key=%', p_price_key;
  END IF;

  PERFORM public.service_apply_entitlements_from_product_key(p_user_id, v_product_key);
END;
$fn$;

COMMENT ON FUNCTION public.service_apply_entitlements_from_price_key(uuid, text)
IS 'Service/admin-only. Maps price_key â†’ billing_prices.product_key â†’ applies entitlements.';

COMMIT;