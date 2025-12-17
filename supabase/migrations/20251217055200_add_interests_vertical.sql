-- 20251217055200_add_interests_vertical.sql
-- Add Interests & Hobbies vertical + default specialty + vertical policy (engine-aware)
-- Safe, idempotent, migration-context compatible.

begin;

-- Canonical tables are guarded by triggers
select set_config('rooted.migration_bypass', 'on', true);

-- ------------------------------------------------------------
-- 1) Ensure the default specialty exists in the FK target table
--    canonical_verticals.default_specialty -> specialty_types(code)
-- ------------------------------------------------------------
insert into public.specialty_types (
  code,
  label,
  vertical_group,
  requires_compliance,
  kids_allowed,
  default_visibility,
  vertical_code
)
values (
  'INTERESTS_GENERAL',
  'Interests (General)',
  'INTERESTS',
  false,
  true,
  true,
  'INTERESTS_HOBBIES'
)
on conflict (code) do update
set
  label = excluded.label,
  vertical_group = excluded.vertical_group,
  requires_compliance = excluded.requires_compliance,
  kids_allowed = excluded.kids_allowed,
  default_visibility = excluded.default_visibility,
  vertical_code = excluded.vertical_code;

-- (Optional) Keep this too if other logic references canonical_specialties
insert into public.canonical_specialties (specialty_code)
values ('INTERESTS_GENERAL')
on conflict (specialty_code) do nothing;

-- ------------------------------------------------------------
-- 2) Add / upsert the new vertical in canonical_verticals
-- ------------------------------------------------------------
insert into public.canonical_verticals (
  vertical_code,
  label,
  description,
  sort_order,
  default_specialty
)
values (
  'INTERESTS_HOBBIES',
  'Interests & Hobbies',
  'Skill-based, hobby-based, and lifestyle activities (discovery -> events -> registrations).',
  999,
  'INTERESTS_GENERAL'
)
on conflict (vertical_code) do update
set
  label = excluded.label,
  description = excluded.description,
  sort_order = excluded.sort_order,
  default_specialty = excluded.default_specialty;

-- ------------------------------------------------------------
-- 3) Ensure default mapping exists (vertical_canonical_specialties)
-- ------------------------------------------------------------
insert into public.vertical_canonical_specialties (vertical_code, specialty_code, is_default)
values ('INTERESTS_HOBBIES', 'INTERESTS_GENERAL', true)
on conflict (vertical_code, specialty_code) do update
set is_default = excluded.is_default;

update public.vertical_canonical_specialties
set is_default = false
where vertical_code = 'INTERESTS_HOBBIES'
  and specialty_code <> 'INTERESTS_GENERAL'
  and is_default = true;

-- ------------------------------------------------------------
-- 4) Vertical policy (engine ceiling + discovery/event/ticketing allowances)
-- ------------------------------------------------------------
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
values (
  'INTERESTS_HOBBIES',
  'registration',
  true,
  true,
  false,
  true,
  true,
  true,
  false,
  false
)
on conflict (vertical_code) do update
set
  max_engine_state = excluded.max_engine_state,
  allows_events = excluded.allows_events,
  allows_payments = excluded.allows_payments,
  allows_b2b = excluded.allows_b2b,
  requires_moderation_for_discovery = excluded.requires_moderation_for_discovery,
  requires_age_rules_for_registration = excluded.requires_age_rules_for_registration,
  requires_refund_policy_for_registration = excluded.requires_refund_policy_for_registration,
  requires_waiver_for_registration = excluded.requires_waiver_for_registration,
  requires_insurance_for_registration = excluded.requires_insurance_for_registration;

commit;
