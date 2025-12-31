-- ROOTED: AUTO-FIX-DO-OPENERS-STEP-1J2C (canonical)
BEGIN;

-- ============================================================
-- BILLING CATALOG CORE (v1)
-- Goal: pluggable Stripe catalog + entitlements mapping
-- - supports: vendor/institution tiers, institution-type pricing,
--   market-specific products (Zillow competitor, waste, jobs, tickets)
-- - service_role/admin write only
-- - safe reads for authenticated where appropriate
-- ============================================================

-- ---------- tables ----------

CREATE TABLE IF NOT EXISTS public.billing_products (
  product_key text PRIMARY KEY,            -- stable internal key (e.g. 'vendor_premium', 'inst_premium_hospital')
  display_name text NOT NULL,
  description text NULL,
  product_type text NOT NULL CHECK (product_type IN ('subscription','one_time','donation','ticket','registration','credit_pack')),
  is_active boolean NOT NULL DEFAULT true,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.billing_prices (
  price_key text PRIMARY KEY,              -- stable internal key (e.g. 'vendor_premium_monthly')
  product_key text NOT NULL REFERENCES public.billing_products(product_key) ON DELETE CASCADE,
  stripe_price_id text UNIQUE,             -- nullable until wired
  currency text NOT NULL DEFAULT 'usd',
  unit_amount_cents integer NULL CHECK (unit_amount_cents IS NULL OR unit_amount_cents >= 0),
  interval text NULL CHECK (interval IS NULL OR interval IN ('day','week','month','year')),
  interval_count integer NULL CHECK (interval_count IS NULL OR interval_count >= 1),
  is_active boolean NOT NULL DEFAULT true,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- What does a product grant?
-- Keep this flexible: role/tier are optional; features/capabilities can expand later without schema churn.
CREATE TABLE IF NOT EXISTS public.billing_entitlements (
  entitlement_key text PRIMARY KEY,        -- stable internal key
  product_key text NOT NULL REFERENCES public.billing_products(product_key) ON DELETE CASCADE,
  role text NULL CHECK (role IS NULL OR role IN ('vendor','institution')),
  tier text NULL CHECK (tier IS NULL OR tier IN ('free','premium','premium_plus')),
  feature_flags jsonb NOT NULL DEFAULT '{}'::jsonb,
  capabilities jsonb NOT NULL DEFAULT '[]'::jsonb,   -- array JSON
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Optional scoping: lets a product apply only to certain vertical/market contexts
-- so "zillow competitor" / waste / jobs can remain modular.
CREATE TABLE IF NOT EXISTS public.billing_product_scopes (
  scope_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_key text NOT NULL REFERENCES public.billing_products(product_key) ON DELETE CASCADE,
  vertical_code text NULL,
  market_code text NULL,
  institution_type text NULL,              -- maps to your Stripe segmentation
  role text NULL CHECK (role IS NULL OR role IN ('vendor','institution')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (product_key, vertical_code, market_code, institution_type, role)
);

-- ---------- updated_at triggers (only if you already use _touch_updated_at) ----------

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $do$
BEGIN
  -- if _touch_updated_at exists, attach triggers; otherwise do nothing
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname='_touch_updated_at'
  ) THEN
    BEGIN
      CREATE TRIGGER trg_billing_products_updated_at
      BEFORE UPDATE ON public.billing_products
      FOR EACH ROW EXECUTE FUNCTION public._touch_updated_at();
    EXCEPTION WHEN duplicate_object THEN NULL; END;

    BEGIN
      CREATE TRIGGER trg_billing_prices_updated_at
      BEFORE UPDATE ON public.billing_prices
      FOR EACH ROW EXECUTE FUNCTION public._touch_updated_at();
    EXCEPTION WHEN duplicate_object THEN NULL; END;

    BEGIN
      CREATE TRIGGER trg_billing_entitlements_updated_at
      BEFORE UPDATE ON public.billing_entitlements
      FOR EACH ROW EXECUTE FUNCTION public._touch_updated_at();
    EXCEPTION WHEN duplicate_object THEN NULL; END;
  END IF;
END;
$do$;

-- ---------- RLS ----------
ALTER TABLE public.billing_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_entitlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_product_scopes ENABLE ROW LEVEL SECURITY;

-- readable catalog (authenticated), write only service/admin

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $do$
BEGIN
  -- PRODUCTS
  BEGIN
    CREATE POLICY billing_products_read_auth_v1
    ON public.billing_products
    FOR SELECT TO authenticated
    USING (is_active = true);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY billing_products_write_service_v1
    ON public.billing_products
    FOR ALL TO authenticated
    USING (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin())
    WITH CHECK (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- PRICES
  BEGIN
    CREATE POLICY billing_prices_read_auth_v1
    ON public.billing_prices
    FOR SELECT TO authenticated
    USING (is_active = true);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY billing_prices_write_service_v1
    ON public.billing_prices
    FOR ALL TO authenticated
    USING (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin())
    WITH CHECK (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- ENTITLEMENTS (keep read restricted; only service/admin typically needs full view)
  BEGIN
    CREATE POLICY billing_entitlements_read_service_v1
    ON public.billing_entitlements
    FOR SELECT TO authenticated
    USING (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY billing_entitlements_write_service_v1
    ON public.billing_entitlements
    FOR ALL TO authenticated
    USING (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin())
    WITH CHECK (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- SCOPES (service/admin only)
  BEGIN
    CREATE POLICY billing_scopes_read_service_v1
    ON public.billing_product_scopes
    FOR SELECT TO authenticated
    USING (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY billing_scopes_write_service_v1
    ON public.billing_product_scopes
    FOR ALL TO authenticated
    USING (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin())
    WITH CHECK (current_setting('request.jwt.claim.role', true) = 'service_role' OR public.is_admin());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

END;
$do$;

COMMIT;