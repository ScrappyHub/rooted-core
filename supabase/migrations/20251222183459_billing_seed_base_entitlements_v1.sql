BEGIN;

-- ============================================================
-- billing_entitlements: seed base entitlements
-- These must exist or service_apply_* will (correctly) refuse to apply.
--
-- Canonical feature_flags contract (booleans):
--   is_kids_mode
--   can_use_bid_marketplace
--   can_use_bulk_marketplace
--   can_view_basic_analytics
--   can_view_advanced_analytics
-- ============================================================

-- NOTE: Assumes entitlement_key is unique (typical PK/unique constraint).
-- If your constraint differs, STOP and we will introspect constraints and adapt.

INSERT INTO public.billing_entitlements
  (entitlement_key, product_key, role, tier, feature_flags, capabilities, metadata, is_active)
VALUES
  -- ----------------------------------------------------------
  -- Institution Premium (bulk + basic analytics)
  -- ----------------------------------------------------------
  (
    'institution_premium_base_v1',
    'institution_premium',
    'institution',
    'premium',
    jsonb_build_object(
      'is_kids_mode', false,
      'can_use_bid_marketplace', false,
      'can_use_bulk_marketplace', true,
      'can_view_basic_analytics', true,
      'can_view_advanced_analytics', false
    ),
    '{}'::jsonb,
    jsonb_build_object('scope','base','source','seed_migration','version','v1'),
    true
  ),

  -- ----------------------------------------------------------
  -- Vendor Premium (bulk + basic analytics)
  -- ----------------------------------------------------------
  (
    'vendor_premium_base_v1',
    'vendor_premium',
    'vendor',
    'premium',
    jsonb_build_object(
      'is_kids_mode', false,
      'can_use_bid_marketplace', false,
      'can_use_bulk_marketplace', true,
      'can_view_basic_analytics', true,
      'can_view_advanced_analytics', false
    ),
    '{}'::jsonb,
    jsonb_build_object('scope','base','source','seed_migration','version','v1'),
    true
  ),

  -- ----------------------------------------------------------
  -- Vendor Premium Plus (bids + bulk + advanced analytics)
  -- ----------------------------------------------------------
  (
    'vendor_premium_plus_base_v1',
    'vendor_premium_plus',
    'vendor',
    'premium_plus',
    jsonb_build_object(
      'is_kids_mode', false,
      'can_use_bid_marketplace', true,
      'can_use_bulk_marketplace', true,
      'can_view_basic_analytics', true,
      'can_view_advanced_analytics', true
    ),
    '{}'::jsonb,
    jsonb_build_object('scope','base','source','seed_migration','version','v1'),
    true
  )

ON CONFLICT (entitlement_key) DO UPDATE
SET
  product_key   = EXCLUDED.product_key,
  role          = EXCLUDED.role,
  tier          = EXCLUDED.tier,
  feature_flags = EXCLUDED.feature_flags,
  capabilities  = EXCLUDED.capabilities,
  metadata      = EXCLUDED.metadata,
  is_active     = EXCLUDED.is_active,
  updated_at    = now();

COMMIT;