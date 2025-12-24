BEGIN;

CREATE OR REPLACE FUNCTION public.service_sync_subscription_from_stripe_price(
  p_user_id uuid,
  p_stripe_price_id text,
  p_subscription_status text,
  p_stripe_customer_id text,
  p_subscription_source text DEFAULT 'stripe'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_role text;
  v_product_key text;
  v_tier text;
  v_role_from_product text;
BEGIN
  v_role := current_setting('request.jwt.claim.role', true);

  IF NOT (v_role = 'service_role' OR public.is_admin()) THEN
    RAISE EXCEPTION 'not authorized';
  END IF;

  -- Resolve canonical product + tier from Stripe price
  SELECT r.product_key, r.tier, r.role
    INTO v_product_key, v_tier, v_role_from_product
  FROM public._resolve_product_from_stripe_price(p_stripe_price_id) r;

  IF v_product_key IS NULL THEN
    RAISE EXCEPTION 'Active price not found for stripe_price_id=%', p_stripe_price_id;
  END IF;

  -- ============================================================
  -- billing_customers: enforce 1:1 mapping between stripe_customer_id and user_id
  -- Handle unique(stripe_customer_id) safely:
  --   1) If this customer_id exists for another user, reassign it to p_user_id
  --   2) Else upsert by user_id
  -- ============================================================
  IF p_stripe_customer_id IS NOT NULL AND length(trim(p_stripe_customer_id)) > 0 THEN

    -- Reassign if customer_id already exists (prevents unique violation)
    UPDATE public.billing_customers bc
    SET user_id = p_user_id,
        created_at = COALESCE(bc.created_at, now())
    WHERE bc.stripe_customer_id = p_stripe_customer_id;

    -- Ensure row exists for this user_id (and has the customer_id)
    INSERT INTO public.billing_customers (user_id, stripe_customer_id, created_at)
    VALUES (p_user_id, p_stripe_customer_id, now())
    ON CONFLICT (user_id) DO UPDATE
      SET stripe_customer_id = EXCLUDED.stripe_customer_id;

  END IF;

  -- Canonical: subscription_* fields must match the resolved tier/product
  UPDATE public.user_tiers ut
  SET
    subscription_tier    = v_tier,
    subscription_status  = p_subscription_status,
    subscription_source  = p_subscription_source,
    payment_provider_customer_id = p_stripe_customer_id,
    updated_at = now()
  WHERE ut.user_id = p_user_id;

  -- Canonical: apply entitlements (this sets ut.tier + feature_flags)
  PERFORM public.service_apply_entitlements_from_stripe_price(p_user_id, p_stripe_price_id);

  -- Final safety: enforce ut.tier matches subscription_tier for vendor/institution
  UPDATE public.user_tiers ut
  SET tier = ut.subscription_tier
  WHERE ut.user_id = p_user_id
    AND ut.role IN ('vendor','institution')
    AND ut.subscription_tier IS NOT NULL
    AND ut.tier IS DISTINCT FROM ut.subscription_tier;

END;
$fn$;

COMMENT ON FUNCTION public.service_sync_subscription_from_stripe_price(uuid,text,text,text,text)
IS 'Service/admin-only. v2: robust billing_customers upsert handling unique(stripe_customer_id). Sets subscription fields from stripe price → applies entitlements → prevents tier/subscription_tier drift.';

COMMIT;