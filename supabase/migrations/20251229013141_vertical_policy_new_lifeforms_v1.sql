begin;

-- vertical_policy columns you showed earlier include:
-- vertical_code, min_engine_state, max_engine_state,
-- allows_events, allows_payments, allows_b2b,
-- requires_moderation_for_discovery,
-- requires_age_rules_for_registration,
-- requires_refund_policy_for_registration,
-- requires_waiver_for_registration,
-- requires_insurance_for_registration,
-- allowed_roles, is_internal_only

-- Rooted Gaming (public, but isolated identity; enforced in its own tables + RLS below)
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
  'ROOTED_GAMING',
  'discovery'::public.engine_state,
  'registration'::public.engine_state, -- gaming has discovery->registration flows (accounts, approvals, sessions)
  false,
  true,   -- payments allowed later (cosmetics/subs), but not forced here
  false,
  true,   -- moderation for game catalog + listings
  true,   -- age rules required (kids/teens/adults)
  true,   -- if paid flows exist later, refunds must exist
  false,
  false,
  '["individual","admin"]'::jsonb,
  false
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = 'ROOTED_GAMING'
);

-- Future marketplaces: internal-only placeholders so nothing leaks early
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
  '["admin"]'::jsonb,
  true
from (values
  ('DELIVERY_LOGISTICS_MARKET'),
  ('ETHICAL_FOOD_MARKET')
) v(vertical_code)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

commit;