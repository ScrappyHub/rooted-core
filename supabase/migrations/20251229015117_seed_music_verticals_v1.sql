begin;

-- 1) canonical_verticals (uses columns you showed)
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (
  values
    ('MUSIC_CREATORS_MARKET', 'Music Creators Marketplace',
      'Producers/artists portfolio, sessions, lessons, beat packs, verses, licensing, payments.', 14000, 'ROOTED_PLATFORM_CANONICAL'),
    ('MUSIC_LIBRARY_STREAMING', 'Music Library',
      'Future: music library / streaming competitor lane (separate lifeform).', 14010, 'ROOTED_PLATFORM_CANONICAL')
) as v(vertical_code,label,description,sort_order,default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

-- 2) vertical_policy
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
  v.requires_moderation_for_discovery,
  v.requires_age_rules_for_registration,
  v.requires_refund_policy_for_registration,
  v.requires_waiver_for_registration,
  v.requires_insurance_for_registration,
  v.allowed_roles::jsonb,
  v.is_internal_only
from (
  values
    ('MUSIC_CREATORS_MARKET','discovery','commerce', false, true, true,  true, true, true, false, false, '["individual","vendor","institution","admin"]', false),
    ('MUSIC_LIBRARY_STREAMING','discovery','commerce', false, true, false, true, true, true, false, false, '["individual","admin"]', true)
) as v(vertical_code,min_state,max_state,allows_events,allows_payments,allows_b2b,requires_moderation_for_discovery,requires_age_rules_for_registration,requires_refund_policy_for_registration,requires_waiver_for_registration,requires_insurance_for_registration,allowed_roles,is_internal_only)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

-- 3) market requirements placeholders for music creator commerce
insert into public.vertical_market_requirements (
  vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes
)
select v.vertical_code, v.market_code, v.required_badge_codes, v.require_verified_provider, v.enabled, v.notes
from (
  values
    ('MUSIC_CREATORS_MARKET','listings', array[]::text[], false, true, 'Creator listings lane: portfolios/sessions/packs (badge rules defined later).')
) as v(vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes)
where not exists (
  select 1 from public.vertical_market_requirements vmr
  where vmr.vertical_code = v.vertical_code
    and vmr.market_code = v.market_code
);

commit;