@"
-- 20251217210000_vertical_policy_internal_scope_v1.sql
-- Add internal scope flag and hard-lock META/REGIONAL as institution/admin-only.
-- Engine states remain capability-based; scope prevents public/guest leakage.

begin;

select set_config('rooted.migration_bypass', 'on', true);

-- 1) Add internal-only scope flag (safe additive)
alter table public.vertical_policy
  add column if not exists is_internal_only boolean not null default false;

-- 2) META_INFRASTRUCTURE: internal-only, discovery-only, institution/admin only
update public.vertical_policy
set
  is_internal_only = true,
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

-- 3) REGIONAL_INTELLIGENCE: internal-only, allow events capability, institution/admin only
update public.vertical_policy
set
  is_internal_only = true,
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
"@ | Set-Content -Encoding UTF8 .\supabase\migrations\20251217210000_vertical_policy_internal_scope_v1.sql
