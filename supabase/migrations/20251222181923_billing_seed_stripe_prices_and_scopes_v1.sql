begin;

-- ============================================================
-- BILLING: seed Stripe prices into billing_prices
-- + seed institution-type scopes into billing_product_scopes
--
-- Canonical goals:
-- 1) Every known Stripe price_id exists in billing_prices with is_active=true
-- 2) Each price maps to an internal product_key
-- 3) Institution-type variants are represented via billing_product_scopes
-- 4) No engine-wide tags, no vertical requirements, no market coupling
-- ============================================================

-- ------------------------------------------------------------
-- 0) Ensure base products exist (idempotent)
-- ------------------------------------------------------------
insert into public.billing_products (product_key, display_name, description, product_type, is_active, metadata)
values
('institution_premium',      'Institution Premium',      'Premium subscription for institutions',      'subscription', true, jsonb_build_object('role','institution','tier','premium')),
('institution_premium_plus', 'Institution Premium Plus', 'Premium Plus subscription for institutions', 'subscription', true, jsonb_build_object('role','institution','tier','premium_plus')),
('vendor_premium',           'Vendor Premium',           'Premium subscription for vendors',           'subscription', true, jsonb_build_object('role','vendor','tier','premium')),
('vendor_premium_plus',      'Vendor Premium Plus',      'Premium Plus subscription for vendors',      'subscription', true, jsonb_build_object('role','vendor','tier','premium_plus'))
on conflict (product_key) do update
set
  display_name = excluded.display_name,
  description  = excluded.description,
  product_type = excluded.product_type,
  is_active    = excluded.is_active,
  metadata     = excluded.metadata,
  updated_at   = now();

-- ------------------------------------------------------------
-- 1) Seed billing_prices (idempotent via stripe_price_id)
--
-- NOTE: unit_amount_cents intentionally left NULL because you
-- didn't paste amounts here (we can backfill later).
-- ------------------------------------------------------------

-- helper: upsert by stripe_price_id
-- we store classification data in metadata so we can stay flexible.

-- ========== Institution Premium Plus ==========
insert into public.billing_prices
(price_key, product_key, stripe_price_id, currency, unit_amount_cents, interval, interval_count, is_active, metadata)
values
-- annual
('ins_pplus_nonprofit_annual',  'institution_premium_plus', 'price_1SarHIBjwUNKgph6DUZf3QLu', 'usd', null, 'year',  1, true, jsonb_build_object('role','institution','tier','premium_plus','institution_type','nonprofit','cadence','annual')),
('ins_pplus_hospital_annual',   'institution_premium_plus', 'price_1SarGKBjwUNKgph6qJhslOYv', 'usd', null, 'year',  1, true, jsonb_build_object('role','institution','tier','premium_plus','institution_type','hospital','cadence','annual')),
('ins_pplus_university_annual', 'institution_premium_plus', 'price_1SarFhBjwUNKgph6UrlvYiTN', 'usd', null, 'year',  1, true, jsonb_build_object('role','institution','tier','premium_plus','institution_type','university','cadence','annual')),
('ins_pplus_jail_annual',       'institution_premium_plus', 'price_1SarEPBjwUNKgph68a6vkEBD', 'usd', null, 'year',  1, true, jsonb_build_object('role','institution','tier','premium_plus','institution_type','jail','cadence','annual')),
('ins_pplus_generic_annual',    'institution_premium_plus', 'price_1SarD9BjwUNKgph6syPfspKc', 'usd', null, 'year',  1, true, jsonb_build_object('role','institution','tier','premium_plus','institution_type','generic','cadence','annual')),

-- monthly
('ins_pplus_nonprofit_monthly', 'institution_premium_plus', 'price_1SarGxBjwUNKgph6BQYpJq9v', 'usd', null, 'month', 1, true, jsonb_build_object('role','institution','tier','premium_plus','institution_type','nonprofit','cadence','monthly')),
('ins_pplus_school_monthly',    'institution_premium_plus', 'price_1SarFyBjwUNKgph6kF5bbOtJ', 'usd', null, 'month', 1, true, jsonb_build_object('role','institution','tier','premium_plus','institution_type','school','cadence','monthly')),
('ins_pplus_hospital_monthly',  'institution_premium_plus', 'price_1SarFKBjwUNKgph6bZGyjywV', 'usd', null, 'month', 1, true, jsonb_build_object('role','institution','tier','premium_plus','institution_type','hospital','cadence','monthly')),
('ins_pplus_univ_monthly',      'institution_premium_plus', 'price_1SarF3BjwUNKgph68LRPjGK9', 'usd', null, 'month', 1, true, jsonb_build_object('role','institution','tier','premium_plus','institution_type','university','cadence','monthly')),
('ins_pplus_jail_monthly',      'institution_premium_plus', 'price_1SarDuBjwUNKgph6O2EBuDsa', 'usd', null, 'month', 1, true, jsonb_build_object('role','institution','tier','premium_plus','institution_type','jail','cadence','monthly'))

on conflict (stripe_price_id) do update
set
  product_key       = excluded.product_key,
  price_key         = excluded.price_key,
  currency          = excluded.currency,
  interval          = excluded.interval,
  interval_count    = excluded.interval_count,
  is_active         = excluded.is_active,
  metadata          = excluded.metadata,
  updated_at        = now();

-- ========== Institution Premium ==========
insert into public.billing_prices
(price_key, product_key, stripe_price_id, currency, unit_amount_cents, interval, interval_count, is_active, metadata)
values
-- annual
('ins_p_nonprofit_annual',   'institution_premium', 'price_1SarB2BjwUNKgph6I4sUKz80', 'usd', null, 'year',  1, true, jsonb_build_object('role','institution','tier','premium','institution_type','nonprofit','cadence','annual')),
('ins_p_university_annual',  'institution_premium', 'price_1Sar9UBjwUNKgph6TXILR2FQ', 'usd', null, 'year',  1, true, jsonb_build_object('role','institution','tier','premium','institution_type','university','cadence','annual')),
('ins_p_jail_annual',        'institution_premium', 'price_1SarA9BjwUNKgph6qIcTg8r5', 'usd', null, 'year',  1, true, jsonb_build_object('role','institution','tier','premium','institution_type','jail','cadence','annual')),
('ins_p_school_annual',      'institution_premium', 'price_1Sar99BjwUNKgph6eYbPvfFN', 'usd', null, 'year',  1, true, jsonb_build_object('role','institution','tier','premium','institution_type','school','cadence','annual')),
('ins_p_hospital_annual',    'institution_premium', 'price_1Sar86BjwUNKgph6BLR6UYnn', 'usd', null, 'year',  1, true, jsonb_build_object('role','institution','tier','premium','institution_type','hospital','cadence','annual')),

-- monthly
('ins_p_jail_monthly',       'institution_premium', 'price_1Sar8rBjwUNKgph6k3WHvIhz', 'usd', null, 'month', 1, true, jsonb_build_object('role','institution','tier','premium','institution_type','jail','cadence','monthly')),
('ins_p_hospital_monthly',   'institution_premium', 'price_1Sar9mBjwUNKgph6fXTAw9UZ', 'usd', null, 'month', 1, true, jsonb_build_object('role','institution','tier','premium','institution_type','hospital','cadence','monthly')),
('ins_p_university_monthly', 'institution_premium', 'price_1SarBVBjwUNKgph6LNkrqef1', 'usd', null, 'month', 1, true, jsonb_build_object('role','institution','tier','premium','institution_type','university','cadence','monthly')),
('ins_p_nonprofit_monthly',  'institution_premium', 'price_1SarC1BjwUNKgph6UZH5PXv8', 'usd', null, 'month', 1, true, jsonb_build_object('role','institution','tier','premium','institution_type','nonprofit','cadence','monthly')),
('ins_p_school_monthly',     'institution_premium', 'price_1SarCLBjwUNKgph6EcloiRvm', 'usd', null, 'month', 1, true, jsonb_build_object('role','institution','tier','premium','institution_type','school','cadence','monthly'))

on conflict (stripe_price_id) do update
set
  product_key       = excluded.product_key,
  price_key         = excluded.price_key,
  currency          = excluded.currency,
  interval          = excluded.interval,
  interval_count    = excluded.interval_count,
  is_active         = excluded.is_active,
  metadata          = excluded.metadata,
  updated_at        = now();

-- ========== Vendor Premium Plus ==========
insert into public.billing_prices
(price_key, product_key, stripe_price_id, currency, unit_amount_cents, interval, interval_count, is_active, metadata)
values
('vendor_pplus_annual',  'vendor_premium_plus', 'price_1Sar5lBjwUNKgph6OMGZvwnv', 'usd', null, 'year',  1, true, jsonb_build_object('role','vendor','tier','premium_plus','cadence','annual')),
('vendor_pplus_monthly', 'vendor_premium_plus', 'price_1Sar5EBjwUNKgph6X1eLfLIw', 'usd', null, 'month', 1, true, jsonb_build_object('role','vendor','tier','premium_plus','cadence','monthly'))
on conflict (stripe_price_id) do update
set
  product_key    = excluded.product_key,
  price_key      = excluded.price_key,
  currency       = excluded.currency,
  interval       = excluded.interval,
  interval_count = excluded.interval_count,
  is_active      = excluded.is_active,
  metadata       = excluded.metadata,
  updated_at     = now();

-- ========== Vendor Premium ==========
insert into public.billing_prices
(price_key, product_key, stripe_price_id, currency, unit_amount_cents, interval, interval_count, is_active, metadata)
values
('vendor_p_annual',  'vendor_premium', 'price_1Sar4bBjwUNKgph6KkFNMRcr', 'usd', null, 'year',  1, true, jsonb_build_object('role','vendor','tier','premium','cadence','annual')),
('vendor_p_monthly', 'vendor_premium', 'price_1SakiIBjwUNKgph6mH7lRUnR', 'usd', null, 'month', 1, true, jsonb_build_object('role','vendor','tier','premium','cadence','monthly'))
on conflict (stripe_price_id) do update
set
  product_key    = excluded.product_key,
  price_key      = excluded.price_key,
  currency       = excluded.currency,
  interval       = excluded.interval,
  interval_count = excluded.interval_count,
  is_active      = excluded.is_active,
  metadata       = excluded.metadata,
  updated_at     = now();

-- ------------------------------------------------------------
-- 2) Seed billing_product_scopes (institution-type differentiation)
--    We do NOT set vertical_code or market_code yet.
-- ------------------------------------------------------------
insert into public.billing_product_scopes
(scope_id, product_key, vertical_code, market_code, institution_type, role, metadata)
select
  gen_random_uuid(),
  bp.product_key,
  null::text as vertical_code,
  null::text as market_code,
  inst_type.institution_type,
  'institution'::text as role,
  jsonb_build_object('source','seed_v1')
from (values
  ('institution_premium','nonprofit'),
  ('institution_premium','hospital'),
  ('institution_premium','university'),
  ('institution_premium','school'),
  ('institution_premium','jail'),
  ('institution_premium_plus','nonprofit'),
  ('institution_premium_plus','hospital'),
  ('institution_premium_plus','university'),
  ('institution_premium_plus','school'),
  ('institution_premium_plus','jail'),
  ('institution_premium_plus','generic')
) as inst_type(product_key, institution_type)
join public.billing_products bp on bp.product_key = inst_type.product_key
where not exists (
  select 1
  from public.billing_product_scopes s
  where s.product_key = inst_type.product_key
    and coalesce(s.institution_type,'') = inst_type.institution_type
    and coalesce(s.vertical_code,'') = ''
    and coalesce(s.market_code,'') = ''
    and coalesce(s.role,'') = 'institution'
);

commit;