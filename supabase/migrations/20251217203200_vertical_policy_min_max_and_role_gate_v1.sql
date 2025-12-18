-- 20251217203200_vertical_policy_min_max_and_role_gate_v1.sql
-- Vertical policy: add min_engine_state + allowed_roles, backfill safely, lock META + REGIONAL.
-- Safe / idempotent.

begin;

select set_config('rooted.migration_bypass', 'on', true);

-- ------------------------------------------------------------
-- 1) Add minimum engine state + allowed roles
-- IMPORTANT: do NOT default to a value that might not exist in the enum.
-- Use 'discovery' which already exists in your current policy rows.
-- ------------------------------------------------------------
alter table public.vertical_policy
  add column if not exists min_engine_state engine_state not null default 'discovery';

alter table public.vertical_policy
  add column if not exists allowed_roles text[] not null
    default array['individual','vendor','institution','admin'];

-- ------------------------------------------------------------
-- 2) Backfill sane defaults (only where NULL)
-- ------------------------------------------------------------
update public.vertical_policy
set min_engine_state = 'discovery'
where min_engine_state is null;

update public.vertical_policy
set allowed_roles = array['individual','vendor','institution','admin']
where allowed_roles is null;

-- ------------------------------------------------------------
-- 3) Hard lock META + REGIONAL to institution/admin only
-- ------------------------------------------------------------

-- META_INFRASTRUCTURE: institution/admin only, discovery-only
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

-- REGIONAL_INTELLIGENCE: institution/admin only
-- If you want it discovery-only NOW, keep discovery.
-- If you want it to *optionally* expand later, change max in a FUTURE migration.
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
where vertical_code = 'REGIONAL_INTELLIGENCE';

commit;
