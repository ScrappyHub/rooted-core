-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: AUTO-FIX-DO-OPENERS-STEP-1J2C (canonical)
BEGIN;

-- ============================================================
-- 1) Event ledger: one row per Stripe event.id (idempotency)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.billing_stripe_events (
  event_id            text PRIMARY KEY,
  event_type          text NOT NULL,
  stripe_customer_id  text NULL,
  stripe_subscription_id text NULL,
  stripe_price_id     text NULL,
  status              text NOT NULL DEFAULT 'received', -- received | processed | ignored | failed
  error               text NULL,
  received_at         timestamptz NOT NULL DEFAULT now(),
  processed_at        timestamptz NULL,
  payload             jsonb NULL
);

COMMENT ON TABLE public.billing_stripe_events
IS 'Stripe webhook event ledger (idempotency). Exactly 1 row per Stripe event.id. Service/admin write only.';

-- RLS
ALTER TABLE public.billing_stripe_events ENABLE ROW LEVEL SECURITY;

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $do$
BEGIN
  -- Service/admin can read/write
  BEGIN
    CREATE POLICY billing_stripe_events_service_all_v1
    ON public.billing_stripe_events
    FOR ALL
    TO authenticated
    USING (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin())
    WITH CHECK (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin());
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;

  -- Authenticated users: no access (default deny via no policies)
END;
$do$;

-- Helpful indexes
CREATE INDEX IF NOT EXISTS billing_stripe_events_customer_idx
  ON public.billing_stripe_events (stripe_customer_id);

CREATE INDEX IF NOT EXISTS billing_stripe_events_received_at_idx
  ON public.billing_stripe_events (received_at);

-- ============================================================
-- 2) Internal assertion helper exists already: _assert_service_or_admin()
-- We rely on it for canonical service-only ingress.
-- ============================================================

-- ============================================================
-- 3) Idempotent ingest function:
--    - Inserts event row if not exists
--    - If already processed -> no-op
--    - If exists but failed -> can retry by calling again
--    - On success, marks processed
-- ============================================================
CREATE OR REPLACE FUNCTION public.service_stripe_ingest_event_v1(
  p_event_id text,
  p_event_type text,
  p_stripe_customer_id text,
  p_subscription_status text,
  p_stripe_price_id text,
  p_user_id uuid,
  p_stripe_subscription_id text DEFAULT NULL,
  p_payload jsonb DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_role text;
  v_existing_status text;
BEGIN
  v_role := current_setting('request.jwt.claim.role', true);
  IF NOT (v_role = 'service_role' OR public.is_admin()) THEN
    RAISE EXCEPTION 'not authorized';
  END IF;

  -- Upsert event row (idempotency key = event_id)
  INSERT INTO public.billing_stripe_events (
    event_id, event_type, stripe_customer_id, stripe_subscription_id, stripe_price_id, status, payload
  )
  VALUES (
    p_event_id, p_event_type, p_stripe_customer_id, p_stripe_subscription_id, p_stripe_price_id, 'received', p_payload
  )
  ON CONFLICT (event_id) DO UPDATE
    SET
      -- keep first payload by default unless NULL previously
      payload = COALESCE(public.billing_stripe_events.payload, EXCLUDED.payload);

  SELECT status INTO v_existing_status
  FROM public.billing_stripe_events
  WHERE event_id = p_event_id;

  -- If already processed/ignored, do nothing (idempotent)
  IF v_existing_status IN ('processed','ignored') THEN
    RETURN;
  END IF;

  -- Core action:
  -- Canonical: sync subscription ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ applies entitlements ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ fixes drift
  PERFORM public.service_sync_subscription_from_stripe_price(
    p_user_id,
    p_stripe_price_id,
    p_subscription_status,
    p_stripe_customer_id,
    'stripe'
  );

  UPDATE public.billing_stripe_events
  SET status = 'processed',
      processed_at = now(),
      error = NULL,
      stripe_customer_id = p_stripe_customer_id,
      stripe_subscription_id = p_stripe_subscription_id,
      stripe_price_id = p_stripe_price_id
  WHERE event_id = p_event_id;

EXCEPTION WHEN OTHERS THEN
  UPDATE public.billing_stripe_events
  SET status = 'failed',
      processed_at = now(),
      error = SQLERRM,
      stripe_customer_id = p_stripe_customer_id,
      stripe_subscription_id = p_stripe_subscription_id,
      stripe_price_id = p_stripe_price_id
  WHERE event_id = p_event_id;

  RAISE;
END;
$fn$;

COMMENT ON FUNCTION public.service_stripe_ingest_event_v1(text,text,text,text,text,uuid,text,jsonb)
IS 'Service/admin-only. Stripe webhook idempotency: ledger row keyed by event_id. Calls canonical service_sync_subscription_from_stripe_price, marks event processed/failed. Safe to retry.';

COMMIT;