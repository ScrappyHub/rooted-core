begin;

-- ------------------------------------------------------------
-- 0) Preconditions
-- ------------------------------------------------------------
do $$
begin
  if to_regclass('public.billing_entitlements') is null then
    raise exception 'Missing required table: public.billing_entitlements';
  end if;
  if to_regclass('public.canonical_verticals') is null then
    raise exception 'Missing required table: public.canonical_verticals';
  end if;
  if to_regclass('public.vertical_lane_policy') is null then
    raise exception 'Missing required table: public.vertical_lane_policy';
  end if;
  if to_regclass('public.lane_codes') is null then
    raise exception 'Missing required table: public.lane_codes';
  end if;
end $$;

-- ------------------------------------------------------------
-- 1) Ensure lane vocabulary (Phase 2)
-- ------------------------------------------------------------
insert into public.lane_codes (lane_code, label, description)
select x.lane_code, x.label, x.description
from (values
  ('discovery','Discovery','Discovery surfaces, search/browse/listing visibility rules.'),
  ('events','Events','Event listings + publishing + host gating.'),
  ('registration','Registration','Registration flows and compliance gates.'),
  ('ticketing','Ticketing','Tickets issuance/transfer/refund policy enforcement.'),
  ('commerce_listings','Commerce Listings','Listings/catalog/marketplace publishing lane.'),
  ('payments','Payments','Payment processing lane.'),
  ('digital_goods','Digital Goods','Digital purchase + ownership lane.'),
  ('games_library','Games Library','Game library access + downloads.'),
  ('streaming_music','Streaming Music','Music streaming/library lane.'),
  ('streaming_video','Streaming Video','Video streaming/library lane.'),
  ('b2b_bulk','B2B Bulk','Bulk procurement lane.'),
  ('b2b_bid','B2B Bid','RFQs/bidding lane.'),
  ('b2g_procurement','B2G Procurement','Government procurement lane.'),
  ('retail','Retail','Retail purchase/fulfillment lane (future specialization).'),
  ('p2p','P2P','Peer-to-peer transaction lane (future specialization).'),
  ('real_estate','Real Estate','Real estate transaction lane (future specialization).')
) x(lane_code,label,description)
where not exists (select 1 from public.lane_codes lc where lc.lane_code=x.lane_code);

-- ------------------------------------------------------------
-- 2) Normalize lane entitlement requirements (stop hardcoding premium)
--    - commerce_listings should require 'commerce' (not premium)
--    - payments should require 'payments' (not premium)
-- ------------------------------------------------------------
update public.vertical_lane_policy
set requires_entitlement_code = 'commerce'
where lane_code = 'commerce_listings'
  and (requires_entitlement_code is null or requires_entitlement_code in ('premium','premium_plus'));

update public.vertical_lane_policy
set requires_entitlement_code = 'payments'
where lane_code = 'payments'
  and (requires_entitlement_code is null or requires_entitlement_code in ('premium','premium_plus'));

-- Optional: streaming lanes can require streaming_* entitlements if you want them gated.
-- Keeping them NULL for "free experiment" unless explicitly required by your policy.

-- ------------------------------------------------------------
-- 3) Ensure baseline lane rows exist for EVERY canonical vertical
--    Canonical defaults:
--      - discovery: ON (moderated)
--      - events: OFF unless vertical_policy.allows_events
--      - registration: OFF unless vertical_policy requires_age_rules_for_registration (or max_engine_state>=registration)
--      - ticketing: OFF by default
--      - commerce_listings/payments: OFF unless vertical_policy.allows_payments
--      - b2b/b2g/games/streaming: OFF by default (explicit enable later)
-- ------------------------------------------------------------
insert into public.vertical_lane_policy (
  vertical_code, lane_code, enabled, requires_entitlement_code, requires_moderation, requires_age_gate, notes
)
select
  cv.vertical_code,
  lane.lane_code,
  case
    when lane.lane_code = 'discovery' then true
    when lane.lane_code = 'events' then coalesce(vp.allows_events,false)
    when lane.lane_code = 'commerce_listings' then coalesce(vp.allows_payments,false)  -- commerce verticals
    when lane.lane_code = 'payments' then coalesce(vp.allows_payments,false)
    else false
  end as enabled,
  case
    when lane.lane_code = 'commerce_listings' and coalesce(vp.allows_payments,false) then 'commerce'
    when lane.lane_code = 'payments' and coalesce(vp.allows_payments,false) then 'payments'
    when lane.lane_code = 'ticketing' then 'ticketing'
    when lane.lane_code = 'registration' then 'registration'
    when lane.lane_code = 'b2b_bulk' then 'b2b_bulk'
    when lane.lane_code = 'b2b_bid' then 'b2b_bid'
    when lane.lane_code = 'b2g_procurement' then 'b2g_procurement'
    when lane.lane_code = 'streaming_music' then 'streaming_music'
    when lane.lane_code = 'streaming_video' then 'streaming_video'
    when lane.lane_code = 'games_library' then 'games_library'
    else null
  end as requires_entitlement_code,
  true as requires_moderation,
  case
    when lane.lane_code in ('registration','ticketing') then true
    else false
  end as requires_age_gate,
  'Phase2 baseline lane row (seeded)' as notes
from public.canonical_verticals cv
join public.vertical_policy vp on vp.vertical_code = cv.vertical_code
cross join (values
  ('discovery'),
  ('events'),
  ('registration'),
  ('ticketing'),
  ('commerce_listings'),
  ('payments'),
  ('digital_goods'),
  ('games_library'),
  ('streaming_music'),
  ('streaming_video'),
  ('b2b_bulk'),
  ('b2b_bid'),
  ('b2g_procurement')
) lane(lane_code)
where not exists (
  select 1 from public.vertical_lane_policy vlp
  where vlp.vertical_code = cv.vertical_code
    and vlp.lane_code = lane.lane_code
);

-- ------------------------------------------------------------
-- 4) Seed billing_entitlements (policy rows) for base tiers + packs
--    This DOES NOT assign users; it defines what each role/tier gets.
--    You can expand later without schema change.
-- ------------------------------------------------------------

-- BASE: free tier baseline (kept minimal)
insert into public.billing_entitlements (entitlement_key, product_key, role, tier, feature_flags, capabilities, metadata, is_active)
select x.entitlement_key, x.product_key, x.role, x.tier, x.feature_flags::jsonb, x.capabilities::jsonb, x.metadata::jsonb, true
from (values
  ('registration', 'rooted_base', 'individual', 'free', '{}' , '{}' , '{"seed":"phase2"}'),
  ('ticketing',    'rooted_base', 'individual', 'free', '{}' , '{}' , '{"seed":"phase2"}')
) x(entitlement_key,product_key,role,tier,feature_flags,capabilities,metadata)
where not exists (
  select 1 from public.billing_entitlements be
  where be.entitlement_key=x.entitlement_key and be.role=x.role and be.tier=x.tier
);

-- PREMIUM: enables commerce + payments + media + games baseline
insert into public.billing_entitlements (entitlement_key, product_key, role, tier, feature_flags, capabilities, metadata, is_active)
select x.entitlement_key, x.product_key, x.role, x.tier, x.feature_flags::jsonb, x.capabilities::jsonb, x.metadata::jsonb, true
from (values
  ('premium',       'rooted_premium', 'individual', 'premium', '{}' , '{}' , '{"seed":"phase2"}'),
  ('commerce',      'rooted_premium', 'individual', 'premium', '{}' , '{}' , '{"seed":"phase2"}'),
  ('payments',      'rooted_premium', 'individual', 'premium', '{}' , '{}' , '{"seed":"phase2"}'),
  ('streaming_music','rooted_premium','individual', 'premium', '{}' , '{}' , '{"seed":"phase2"}'),
  ('streaming_video','rooted_premium','individual', 'premium', '{}' , '{}' , '{"seed":"phase2"}'),
  ('games_library', 'rooted_premium', 'individual', 'premium', '{}' , '{}' , '{"seed":"phase2"}')
) x(entitlement_key,product_key,role,tier,feature_flags,capabilities,metadata)
where not exists (
  select 1 from public.billing_entitlements be
  where be.entitlement_key=x.entitlement_key and be.role=x.role and be.tier=x.tier
);

-- PREMIUM_PLUS: everything in premium + b2b_bulk by default
insert into public.billing_entitlements (entitlement_key, product_key, role, tier, feature_flags, capabilities, metadata, is_active)
select x.entitlement_key, x.product_key, x.role, x.tier, x.feature_flags::jsonb, x.capabilities::jsonb, x.metadata::jsonb, true
from (values
  ('premium_plus',  'rooted_premium_plus', 'individual', 'premium_plus', '{}' , '{}' , '{"seed":"phase2"}'),
  ('commerce',      'rooted_premium_plus', 'individual', 'premium_plus', '{}' , '{}' , '{"seed":"phase2"}'),
  ('payments',      'rooted_premium_plus', 'individual', 'premium_plus', '{}' , '{}' , '{"seed":"phase2"}'),
  ('streaming_music','rooted_premium_plus','individual', 'premium_plus', '{}' , '{}' , '{"seed":"phase2"}'),
  ('streaming_video','rooted_premium_plus','individual', 'premium_plus', '{}' , '{}' , '{"seed":"phase2"}'),
  ('games_library', 'rooted_premium_plus', 'individual', 'premium_plus', '{}' , '{}' , '{"seed":"phase2"}'),
  ('b2b_bulk',      'rooted_premium_plus', 'individual', 'premium_plus', '{}' , '{}' , '{"seed":"phase2"}')
) x(entitlement_key,product_key,role,tier,feature_flags,capabilities,metadata)
where not exists (
  select 1 from public.billing_entitlements be
  where be.entitlement_key=x.entitlement_key and be.role=x.role and be.tier=x.tier
);

-- PACK EXAMPLES (OFFICIAL pattern): add-on product grants entitlements independent of base tier
-- These are not required now; seed a couple canonical packs so you can test gating.
insert into public.billing_entitlements (entitlement_key, product_key, role, tier, feature_flags, capabilities, metadata, is_active)
select x.entitlement_key, x.product_key, x.role, x.tier, x.feature_flags::jsonb, x.capabilities::jsonb, x.metadata::jsonb, true
from (values
  ('b2b_bid',        'pack_b2b_bid', 'individual', 'any', '{}' , '{}' , '{"seed":"phase2","pack":true}'),
  ('b2g_procurement','pack_b2g',     'institution', 'any', '{}' , '{}' , '{"seed":"phase2","pack":true}')
) x(entitlement_key,product_key,role,tier,feature_flags,capabilities,metadata)
where not exists (
  select 1 from public.billing_entitlements be
  where be.entitlement_key=x.entitlement_key and be.role=x.role and be.tier=x.tier
);

commit;