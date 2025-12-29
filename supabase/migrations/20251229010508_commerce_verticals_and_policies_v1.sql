begin;

insert into public.canonical_verticals (
  vertical_code, label, description, sort_order, default_specialty
)
select * from (
  values
    ('REAL_ESTATE_PROPERTY','Real Estate & Property',
     'Property listings, rentals, inventory.',12000,'ROOTED_PLATFORM_CANONICAL'),
    ('RETAIL_CATALOG','Retail Catalog',
     'Product catalogs and storefront discovery.',12010,'ROOTED_PLATFORM_CANONICAL'),
    ('P2P_MARKETPLACE','P2P Marketplace',
     'Peer-to-peer listings and exchanges.',12020,'ROOTED_PLATFORM_CANONICAL')
) v
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.column1
);

insert into public.vertical_policy (
  vertical_code,
  min_engine_state,
  max_engine_state,
  allows_events,
  allows_payments,
  allows_b2b,
  requires_moderation_for_discovery,
  requires_age_rules_for_registration,
  requires_refund_policy_for_registration,
  requires_waiver_for_registration,
  requires_insurance_for_registration,
  allowed_roles,
  is_internal_only
)
select * from (
  values
    ('REAL_ESTATE_PROPERTY','discovery','commerce',
     false,true,false,true,true,true,false,false,
     '["individual","vendor","institution","admin"]',false),
    ('RETAIL_CATALOG','discovery','commerce',
     false,true,false,true,true,true,false,false,
     '["vendor","institution","admin"]',false),
    ('P2P_MARKETPLACE','discovery','commerce',
     false,true,false,true,true,true,false,false,
     '["individual","vendor","institution","admin"]',false)
) v
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.column1
);

insert into public.vertical_market_requirements (
  vertical_code, market_code, required_badge_codes,
  require_verified_provider, enabled, notes
)
select * from (
  values
    ('REAL_ESTATE_PROPERTY','listings',array[]::text[],false,true,'Commerce listings lane'),
    ('RETAIL_CATALOG','listings',array[]::text[],false,true,'Commerce listings lane'),
    ('P2P_MARKETPLACE','listings',array[]::text[],false,true,'Commerce listings lane')
) v
where not exists (
  select 1 from public.vertical_market_requirements vmr
  where vmr.vertical_code = v.column1
    and vmr.market_code  = v.column2
);

commit;