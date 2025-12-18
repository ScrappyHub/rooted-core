-- 20251217203200_vertical_policy_min_max_and_role_gate_v1.sql
-- Adds min_engine_state + allowed_roles defaults, and locks META/REGIONAL correctly.
-- Safe + idempotent.

begin;

select set_config('rooted.migration_bypass', 'on', true);

-- ------------------------------------------------------------
-- 1) Add missing columns (engine_state enum + role list)
-- ------------------------------------------------------------
alter table public.vertical_policy
  add column if not exists min_engine_state engine_state not null default 'discovery';

alter table public.vertical_policy
  add column if not exists allowed_roles text[] not null
    default array['individual','vendor','institution','admin'];

-- ------------------------------------------------------------
-- 2) Default: most verticals start at discovery (and keep existing max_engine_state)
-- ------------------------------------------------------------
update public.vertical_policy
set min_engine_state = 'discovery'
where min_engine_state is null;

-- ------------------------------------------------------------
-- 3) HARD LOCK: META_INFRASTRUCTURE (internal-only, no events)
-- ------------------------------------------------------------
update public.vertical_policy
set
  allowed_roles = array['institution','admin'],
  min_engine_state = 'discovery',
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

-- ------------------------------------------------------------
-- 4) HARD LOCK: REGIONAL_INTELLIGENCE (internal-only, events allowed, no payments)
-- ------------------------------------------------------------
update public.vertical_policy
set
  allowed_roles = array['institution','admin'],
  min_engine_state = 'discovery',
  max_engine_state = 'discovery_events',
  allows_events = true,
  allows_payments = false,
  allows_b2b = false,
  requires_moderation_for_discovery = false,
  requires_age_rules_for_registration = false,
  requires_refund_policy_for_registration = false,
  requires_waiver_for_registration = false,
  requires_insurance_for_registration = false
where vertical_code = 'REGIONAL_INTELLIGENCE';

commit;
