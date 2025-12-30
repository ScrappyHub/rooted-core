-- ============================================================
-- ROOTED FIX: vertical_policy engine_state enum casting
-- Reason: earlier seed migrations used SELECT * FROM (VALUES)
--         causing text → enum failure during shadow replay
-- ============================================================

begin;

-- 1. Capture affected rows safely
with bad_rows as (
  select
    vertical_code,
    min_engine_state::text as min_engine_state,
    max_engine_state::text as max_engine_state,
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
  from public.vertical_policy
)

-- 2. Clear table (policies are deterministic + reseeded)
delete from public.vertical_policy;

-- 3. Reinsert with explicit enum casts
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
  vertical_code,
  min_engine_state::public.engine_state,
  max_engine_state::public.engine_state,
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
from bad_rows;

commit;
