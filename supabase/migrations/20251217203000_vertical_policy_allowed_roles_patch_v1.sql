-- 20251217060000_vertical_policy_bounds_and_roles_v1.sql
-- Adds min_engine_state + allowed_roles to vertical_policy
-- Locks META_INFRASTRUCTURE and REGIONAL_INTELLIGENCE correctly
-- Safe, idempotent

begin;

select set_config('rooted.migration_bypass', 'on', true);

-- ------------------------------------------------------------
-- 1) Add missing columns
-- ------------------------------------------------------------

alter table public.vertical_policy
  add column if not exists min_engine_state USER-DEFINED;

alter table public.vertical_policy
  add column if not exists allowed_roles text[]
  not null
  default array['individual','vendor','institution','admin'];

-- ------------------------------------------------------------
-- 2) Backfill min_engine_state safely
--    (default baseline = discovery)
-- ------------------------------------------------------------

update public.vertical_policy
set min_engine_state = 'discovery'
where min_engine_state is null;

-- ------------------------------------------------------------
-- 3) META_INFRASTRUCTURE (admin + institution only)
-- ------------------------------------------------------------

update public.vertical_policy
set
  min_engine_state = 'discovery',
  max_engine_state = 'discovery',
  allowed_roles = array['institution','admin'],
  allows_events = false,
  allows_payments = false,
  allows_b2b = false,
  requires_moderation_for_discovery = false
where vertical_code = 'META_INFRASTRUCTURE';

-- ------------------------------------------------------------
-- 4) REGIONAL_INTELLIGENCE (future-expandable but locked today)
-- ------------------------------------------------------------

update public.vertical_policy
set
  min_engine_state = 'discovery',
  max_engine_state = 'discovery_events',
  allowed_roles = array['institution','admin'],
  allows_events = false,        -- hard stop until enabled
  allows_payments = false,
  allows_b2b = false,
  requires_moderation_for_discovery = false
where vertical_code = 'REGIONAL_INTELLIGENCE';

commit;
