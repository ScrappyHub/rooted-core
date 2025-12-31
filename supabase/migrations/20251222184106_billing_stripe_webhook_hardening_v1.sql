-- ROOTED: AUTO-FIX-DO-OPENERS-STEP-1J2C (canonical)
BEGIN;

-- ============================================================
-- 1) Idempotency ledger: processed Stripe webhook events
-- ============================================================
CREATE TABLE IF NOT EXISTS public.stripe_webhook_events (
  stripe_event_id text PRIMARY KEY,
  event_type text NOT NULL,
  received_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  status text NOT NULL DEFAULT 'received', -- received|processed|ignored|failed
  error text
);

ALTER TABLE public.stripe_webhook_events ENABLE ROW LEVEL SECURITY;

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $do$
BEGIN
  -- Service role can manage
  BEGIN
    CREATE POLICY stripe_webhook_events_service_manage_v1
    ON public.stripe_webhook_events
    FOR ALL
    TO authenticated
    USING (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin())
    WITH CHECK (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin());
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
END;
$do$;

COMMENT ON TABLE public.stripe_webhook_events
IS 'Idempotency ledger for Stripe webhooks. Primary key stripe_event_id prevents double-processing.';

-- ============================================================
-- 2) Helper: resolve (product_key, tier) from stripe_price_id
--    We DO NOT trust caller-provided tier strings.
-- ============================================================
CREATE OR REPLACE FUNCTION public._resolve_product_from_stripe_price(
  p_stripe_price_id text
)
RETURNS TABLE(product_key text, tier text, role text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
  select
    bp.product_key,
    (bp.metadata->>'tier')::text as tier,
    (bp.metadata->>'role')::text as role
  from public.billing_prices pr
  join public.billing_products bp on bp.product_key = pr.product_key
  where pr.stripe_price_id = p_stripe_price_id
    and pr.is_active = true
    and bp.is_active = true
  limit 1;
$fn$;

COMMENT ON FUNCTION public._resolve_product_from_stripe_price(text)
IS 'Maps an active stripe_price_id to billing_products.product_key and tier/role via billing_products.metadata.';

-- ============================================================
-- 3) Canonical service entrypoint for webhooks:
--    - sets subscription fields consistently
--    - then applies entitlements by stripe_price_id
-- ============================================================
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

  -- Ensure billing_customers row exists (optional but recommended)
  INSERT INTO public.billing_customers (user_id, stripe_customer_id, created_at)
  VALUES (p_user_id, p_stripe_customer_id, now())
  ON CONFLICT (user_id) DO UPDATE
  SET stripe_customer_id = EXCLUDED.stripe_customer_id;

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
IS 'Service/admin-only. Canonical webhook entrypoint: sets subscription fields from stripe price ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ applies entitlements ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ prevents tier/subscription_tier drift.';

COMMIT;