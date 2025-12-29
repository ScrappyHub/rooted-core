begin;

-- ============================================================
-- ROOTED: Phase 2 Seed (PK-SAFE, DB-truth safe)
-- billing_entitlements primary key is (entitlement_key)
-- => Exactly ONE row per entitlement_key. No per-tier duplicates.
-- role/tier kept NULL (global) to satisfy check constraints and PK.
-- ============================================================

-- 0) Preconditions
do $$
begin
  if to_regclass('public.billing_entitlements') is null then
    raise exception 'Missing required table: public.billing_entitlements';
  end if;
  if to_regclass('public.canonical_verticals') is null then
    raise exception 'Missing required table: public.canonical_verticals';
  end if;
  if to_regclass('public.vertical_policy') is null then
    raise exception 'Missing required table: public.vertical_policy';
  end if;
  if to_regclass('public.vertical_lane_policy') is null then
    raise exception 'Missing required table: public.vertical_lane_policy';
  end if;
  if to_regclass('public.lane_codes') is null then
    raise exception 'Missing required table: public.lane_codes';
  end if;
end $$;

-- 1) Ensure lane vocabulary (Phase 2)
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

-- 2) Ensure entitlement_codes registry exists + includes lane keys
create table if not exists public.entitlement_codes (
  entitlement_code text primary key,
  label text not null,
  description text not null,
  created_at timestamptz not null default now()
);

insert into public.entitlement_codes (entitlement_code, label, description)
select x.code, x.label, x.description
from (values
  ('free',           'Free',            'Free tier marker entitlement (optional).'),
  ('premium',        'Premium',         'Premium subscription entitlement.'),
  ('premium_plus',   'Premium Plus',    'Premium Plus subscription entitlement.'),

  ('registration',   'Registration',    'Registration capability entitlement.'),
  ('ticketing',      'Ticketing',       'Ticketing capability entitlement.'),
  ('commerce',       'Commerce',        'Commerce capability entitlement (listings).'),
  ('payments',       'Payments',        'Payments capability entitlement.'),

  ('streaming_music','Streaming Music', 'Music streaming lane entitlement.'),
  ('streaming_video','Streaming Video', 'Video streaming lane entitlement.'),
  ('games_library',  'Games Library',   'Games library entitlement.'),

  ('b2b_bulk',       'B2B Bulk',        'Bulk procurement capability entitlement.'),
  ('b2b_bid',        'B2B Bid',         'RFQ/bidding capability entitlement.'),
  ('b2g_procurement','B2G Procurement', 'Government procurement capability entitlement.'),

  ('ad_free_media',  'Ad-Free Media',   'Remove ads in media experiences.')
) x(code,label,description)
where not exists (select 1 from public.entitlement_codes ec where ec.entitlement_code=x.code);

-- 3) Normalize lane entitlement requirements (remove premium hardcoding)
update public.vertical_lane_policy
set requires_entitlement_code = 'commerce'
where lane_code = 'commerce_listings'
  and (requires_entitlement_code is null or requires_entitlement_code in ('premium','premium_plus'));

update public.vertical_lane_policy
set requires_entitlement_code = 'payments'
where lane_code = 'payments'
  and (requires_entitlement_code is null or requires_entitlement_code in ('premium','premium_plus'));

-- 4) Ensure baseline lane rows exist for EVERY canonical vertical (no missing rows)
insert into public.vertical_lane_policy (
  vertical_code, lane_code, enabled, requires_entitlement_code, requires_moderation, requires_age_gate, notes
)
select
  cv.vertical_code,
  lane.lane_code,
  case
    when lane.lane_code = 'discovery' then true
    when lane.lane_code = 'events' then coalesce(vp.allows_events,false)
    when lane.lane_code = 'commerce_listings' then coalesce(vp.allows_payments,false)
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
  (lane.lane_code in ('registration','ticketing')) as requires_age_gate,
  'Phase2 baseline lane row (seeded, PK-safe)' as notes
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

-- 5) Seed billing_entitlements (ONE ROW PER KEY, PK-safe)
-- role/tier NULL => passes your role/tier check constraints and avoids duplicates.
-- capabilities encodes default tier availability (informational, and for future resolver upgrades).
insert into public.billing_entitlements
  (entitlement_key, product_key, role, tier, feature_flags, capabilities, metadata, is_active)
select x.entitlement_key, x.product_key, x.role, x.tier, x.feature_flags::jsonb, x.capabilities::jsonb, x.metadata::jsonb, true
from (values
  ('registration',   'rooted_base',         null, null, '{}' , '{"default_tiers":["free","premium","premium_plus"]}', '{"seed":"phase2","pk_model":"one_row_per_key"}'),
  ('ticketing',      'rooted_base',         null, null, '{}' , '{"default_tiers":["free","premium","premium_plus"]}', '{"seed":"phase2","pk_model":"one_row_per_key"}'),

  ('premium',        'rooted_premium',      null, null, '{}' , '{"default_tiers":["premium"]}',                     '{"seed":"phase2","pk_model":"one_row_per_key"}'),
  ('premium_plus',   'rooted_premium_plus', null, null, '{}' , '{"default_tiers":["premium_plus"]}',                '{"seed":"phase2","pk_model":"one_row_per_key"}'),

  ('commerce',       'rooted_commerce',     null, null, '{}' , '{"default_tiers":["premium","premium_plus"]}',       '{"seed":"phase2","pk_model":"one_row_per_key"}'),
  ('payments',       'rooted_payments',     null, null, '{}' , '{"default_tiers":["premium","premium_plus"]}',       '{"seed":"phase2","pk_model":"one_row_per_key"}'),

  ('streaming_music','rooted_streaming',    null, null, '{}' , '{"default_tiers":["premium","premium_plus"]}',       '{"seed":"phase2","pk_model":"one_row_per_key"}'),
  ('streaming_video','rooted_streaming',    null, null, '{}' , '{"default_tiers":["premium","premium_plus"]}',       '{"seed":"phase2","pk_model":"one_row_per_key"}'),

  ('games_library',  'rooted_games',        null, null, '{}' , '{"default_tiers":["premium","premium_plus"]}',       '{"seed":"phase2","pk_model":"one_row_per_key"}'),

  ('b2b_bulk',       'pack_b2b_bulk',       null, null, '{}' , '{"default_tiers":["premium_plus"]}',                '{"seed":"phase2","pack":true,"pk_model":"one_row_per_key"}'),
  ('b2b_bid',        'pack_b2b_bid',        null, null, '{}' , '{"default_tiers":["premium_plus"]}',                '{"seed":"phase2","pack":true,"pk_model":"one_row_per_key"}'),
  ('b2g_procurement','pack_b2g',            null, null, '{}' , '{"default_roles":["institution"]}',                 '{"seed":"phase2","pack":true,"pk_model":"one_row_per_key"}'),

  ('ad_free_media',  'pack_ad_free',        null, null, '{}' , '{"default_tiers":["premium_plus"]}',                '{"seed":"phase2","pack":true,"pk_model":"one_row_per_key"}')
) x(entitlement_key,product_key,role,tier,feature_flags,capabilities,metadata)
where not exists (
  select 1 from public.billing_entitlements be
  where be.entitlement_key = x.entitlement_key
);

commit;