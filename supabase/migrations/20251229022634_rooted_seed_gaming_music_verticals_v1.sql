begin;

-- Add verticals
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (values
  ('ROOTED_GAMING',            'Rooted Gaming',            'Gaming identity + approved games + strict privacy + safe gating.', 13000, 'ROOTED_PLATFORM_CANONICAL'),
  ('MUSIC_CREATORS_MARKET',    'Music Creators Marketplace','Portfolios, sessions, lessons, beat packs/verses, licensing + payments.', 14000, 'ROOTED_PLATFORM_CANONICAL'),
  ('MUSIC_LIBRARY_STREAMING',  'Music Library',            'Future: streaming/library lane (separate lifeform).',             14010, 'ROOTED_PLATFORM_CANONICAL')
) v(vertical_code,label,description,sort_order,default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

-- Policies
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
  v.min_state::public.engine_state,
  v.max_state::public.engine_state,
  v.allows_events,
  v.allows_payments,
  v.allows_b2b,
  v.requires_moderation,
  v.requires_age_rules,
  v.requires_refunds,
  false,
  false,
  v.allowed_roles::jsonb,
  v.is_internal_only
from (values
  -- Gaming: discovery -> registration, payments allowed later, moderation ON, age rules required
  ('ROOTED_GAMING','discovery','registration', false, true,  false, true, true, true, '["individual","admin"]', false),

  -- Music creators: discovery -> commerce, b2b allowed (institutions booking), moderation ON, age rules ON
  ('MUSIC_CREATORS_MARKET','discovery','commerce', false, true,  true,  true, true, true, '["individual","vendor","institution","admin"]', false),

  -- Music library: internal-only placeholder for now (no accidental leak)
  ('MUSIC_LIBRARY_STREAMING','discovery','commerce', false, true, false, true, true, true, '["admin"]', true)
) v(vertical_code,min_state,max_state,allows_events,allows_payments,allows_b2b,requires_moderation,requires_age_rules,requires_refunds,allowed_roles,is_internal_only)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

-- Placeholder market lane marker for music creator listings
insert into public.vertical_market_requirements (
  vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes
)
select 'MUSIC_CREATORS_MARKET', 'listings', array[]::text[], false, true,
       'Creator listings lane: portfolios/sessions/packs (rules defined later).'
where not exists (
  select 1 from public.vertical_market_requirements vmr
  where vmr.vertical_code='MUSIC_CREATORS_MARKET' and vmr.market_code='listings'
);

commit;