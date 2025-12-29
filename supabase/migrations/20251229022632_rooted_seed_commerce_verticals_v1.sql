begin;

-- canonical_verticals columns (you showed):
-- vertical_code, label, description, sort_order, default_specialty
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (values
  ('REAL_ESTATE_PROPERTY', 'Real Estate & Property', 'Property listings, rentals, sales, inventory (commerce lifeform).', 12000, 'ROOTED_PLATFORM_CANONICAL'),
  ('RETAIL_CATALOG',       'Retail Catalog',        'Product catalogs / storefront discovery (commerce lifeform).',          12010, 'ROOTED_PLATFORM_CANONICAL'),
  ('P2P_MARKETPLACE',      'P2P Marketplace',       'Peer-to-peer listings / exchanges (commerce lifeform).',               12020, 'ROOTED_PLATFORM_CANONICAL')
) v(vertical_code,label,description,sort_order,default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

-- vertical_policy: commerce lane, heavy moderation, payments allowed only here
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
select
  v.vertical_code,
  'discovery'::public.engine_state,
  'commerce'::public.engine_state,
  false,
  true,
  false,
  true,
  true,
  true,
  false,
  false,
  v.allowed_roles::jsonb,
  false
from (values
  ('REAL_ESTATE_PROPERTY','["individual","vendor","institution","admin"]'),
  ('RETAIL_CATALOG',      '["vendor","institution","admin"]'),
  ('P2P_MARKETPLACE',     '["individual","vendor","institution","admin"]')
) v(vertical_code,allowed_roles)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

-- Placeholder market lane marker (listings). NO “licensed/insured is end state” nonsense.
insert into public.vertical_market_requirements (
  vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes
)
select v.vertical_code, 'listings', array[]::text[], false, true,
       'Commerce lane marker: listings (rules will evolve beyond licensed/insured).'
from (values
  ('REAL_ESTATE_PROPERTY'),
  ('RETAIL_CATALOG'),
  ('P2P_MARKETPLACE')
) v(vertical_code)
where not exists (
  select 1 from public.vertical_market_requirements vmr
  where vmr.vertical_code = v.vertical_code and vmr.market_code = 'listings'
);

commit;