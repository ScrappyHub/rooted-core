-- 20251217190000_seed_vertical_policy_all_verticals_v1.sql
-- Seed vertical_policy rows for every canonical vertical (engine ceilings + commerce/event allowances)
-- This is "presentation-before-user" enforcement.

begin;

select set_config('rooted.migration_bypass', 'on', true);

-- Insert any missing vertical_policy rows with conservative defaults.
-- Then override known vertical-specific rules below.
insert into public.vertical_policy (
  vertical_code,
  max_engine_state,
  allows_events,
  allows_payments,
  allows_b2b,
  requires_moderation_for_discovery,
  requires_age_rules_for_registration,
  requires_refund_policy_for_registration,
  requires_waiver_for_registration,
  requires_insurance_for_registration
)
select
  v.vertical_code,
  'discovery'::engine_state as max_engine_state,     -- conservative baseline
  false as allows_events,
  false as allows_payments,
  false as allows_b2b,
  true  as requires_moderation_for_discovery,
  false as requires_age_rules_for_registration,
  false as requires_refund_policy_for_registration,
  false as requires_waiver_for_registration,
  false as requires_insurance_for_registration
from public.canonical_verticals v
where not exists (
  select 1 from public.vertical_policy p where p.vertical_code = v.vertical_code
);

-- ------------------------------------------------------------
-- Overrides (only where we are confident + aligned with your model)
-- ------------------------------------------------------------

-- Interests already set correctly; keep it authoritative (no-op if already correct)
update public.vertical_policy
set
  max_engine_state = 'registration',
  allows_events = true,
  allows_payments = true,
  allows_b2b = false,
  requires_moderation_for_discovery = true,
  requires_age_rules_for_registration = true,
  requires_refund_policy_for_registration = true,
  requires_waiver_for_registration = false,
  requires_insurance_for_registration = false
where vertical_code = 'INTERESTS_HOBBIES';

-- Meta infrastructure: NOT an entity commerce vertical (hard stop)
update public.vertical_policy
set
  max_engine_state = 'discovery',
  allows_events = false,
  allows_payments = false,
  allows_b2b = false,
  requires_moderation_for_discovery = false,
  requires_age_rules_for_registration = false,
  requires_refund_policy_for_registration = false,
  requires_waiver_for_registration = false,
  requires_insurance_for_registration = false
where vertical_code = 'META_INFRASTRUCTURE';

-- Regional intelligence: policy/intel layer (hard stop)
update public.vertical_policy
set
  max_engine_state = 'discovery',
  allows_events = false,
  allows_payments = false,
  allows_b2b = false,
  requires_moderation_for_discovery = false,
  requires_age_rules_for_registration = false,
  requires_refund_policy_for_registration = false,
  requires_waiver_for_registration = false,
  requires_insurance_for_registration = false
where vertical_code = 'REGIONAL_INTELLIGENCE';

commit;
