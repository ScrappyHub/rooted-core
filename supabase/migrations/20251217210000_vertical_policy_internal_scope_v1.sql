-- 20251217210000_vertical_policy_internal_scope_v1.sql
-- Add internal-only scope for META_INFRASTRUCTURE + REGIONAL_INTELLIGENCE
-- (No new engine enums; uses is_internal_only + allowed_roles hard lock)

begin;

select set_config('rooted.migration_bypass', 'on', true);

-- 1) Add internal scope column
alter table public.vertical_policy
  add column if not exists is_internal_only boolean not null default false;

-- 2) META_INFRASTRUCTURE: internal-only, institution/admin only, discovery-only, no events/payments/b2b
update public.vertical_policy
set
  is_internal_only = true,
  allowed_roles = array['institution','admin'],
  min_engine_state = 'discovery',
  max_engine_state = 'discovery',
  allows_events = false,
  allows_payments = false,
  allows_b2b = false,
  requires_moderation_for_discovery = false
where vertical_code = 'META_INFRASTRUCTURE';

-- 3) REGIONAL_INTELLIGENCE: internal-only, institution/admin only
-- Keep event capability possible *internally* via discovery_events (still not public due to internal lock + roles)
update public.vertical_policy
set
  is_internal_only = true,
  allowed_roles = array['institution','admin'],
  min_engine_state = 'discovery',
  max_engine_state = 'discovery_events',
  allows_events = true,
  allows_payments = false,
  allows_b2b = false,
  requires_moderation_for_discovery = false
where vertical_code = 'REGIONAL_INTELLIGENCE';

commit;
