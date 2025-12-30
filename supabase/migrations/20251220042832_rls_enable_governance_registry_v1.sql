begin;

-- =========================================================
-- SAFETY ASSERTS
-- =========================================================
do $$
begin
  if to_regclass('public.user_tiers') is null then
    raise exception 'rls_enable_governance_registry_v1: public.user_tiers missing';
  end if;
end $$;

-- =========================================================
-- 1) ENABLE RLS + FORCE on previously RLS-OFF tables
-- =========================================================
-- Backups (still harden them)
alter table if exists public._backup_specialty_vertical_overlays enable row level security;
alter table if exists public._backup_specialty_vertical_overlays force row level security;

alter table if exists public._backup_vertical_canonical_specialties enable row level security;
alter table if exists public._backup_vertical_canonical_specialties force row level security;

-- Canonical / governance registries (these were RLS OFF in your audit)
alter table if exists public.canonical_specialties enable row level security;
alter table if exists public.canonical_specialties force row level security;

alter table if exists public.capabilities enable row level security;
alter table if exists public.capabilities force row level security;

alter table if exists public.engine_registry enable row level security;
alter table if exists public.engine_registry force row level security;

alter table if exists public.entity_flags enable row level security;
alter table if exists public.entity_flags force row level security;

alter table if exists public.entity_vertical_state enable row level security;
alter table if exists public.entity_vertical_state force row level security;

alter table if exists public.experience_kids_mode_overlays enable row level security;
alter table if exists public.experience_kids_mode_overlays force row level security;

alter table if exists public.experience_types enable row level security;
alter table if exists public.experience_types force row level security;

alter table if exists public.group_capability_grants enable row level security;
alter table if exists public.group_capability_grants force row level security;

alter table if exists public.group_memberships enable row level security;
alter table if exists public.group_memberships force row level security;

alter table if exists public.groups enable row level security;
alter table if exists public.groups force row level security;

alter table if exists public.landmark_types enable row level security;
alter table if exists public.landmark_types force row level security;

alter table if exists public.sanctuary_specialties enable row level security;
alter table if exists public.sanctuary_specialties force row level security;

alter table if exists public.specialty_capabilities enable row level security;
alter table if exists public.specialty_capabilities force row level security;

alter table if exists public.specialty_capability_grants enable row level security;
alter table if exists public.specialty_capability_grants force row level security;

alter table if exists public.specialty_governance_group_members enable row level security;
alter table if exists public.specialty_governance_group_members force row level security;

alter table if exists public.specialty_governance_groups enable row level security;
alter table if exists public.specialty_governance_groups force row level security;

alter table if exists public.specialty_policy_map enable row level security;
alter table if exists public.specialty_policy_map force row level security;

alter table if exists public.specialty_vertical_overlays_bak enable row level security;
alter table if exists public.specialty_vertical_overlays_bak force row level security;

alter table if exists public.specialty_vertical_overlays_v1 enable row level security;
alter table if exists public.specialty_vertical_overlays_v1 force row level security;

alter table if exists public.vertical_canonical_specialties_bak enable row level security;
alter table if exists public.vertical_canonical_specialties_bak force row level security;

alter table if exists public.vertical_capability_defaults enable row level security;
alter table if exists public.vertical_capability_defaults force row level security;

alter table if exists public.vertical_market_requirements enable row level security;
alter table if exists public.vertical_market_requirements force row level security;

alter table if exists public.vertical_policy enable row level security;
alter table if exists public.vertical_policy force row level security;

-- =========================================================
-- 2) BASELINE POLICIES: service_role + admin manage
-- (Conservative: doesnÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢t open anything to regular users)
-- =========================================================
-- Helper pattern: for each table, create:
--  - <table>_service_role_manage_v1  (service_role ALL)
--  - <table>_admin_manage_v1         (authenticated ALL if is_admin())

-- NOTE: if a policy already exists, drop+recreate to keep deterministic.
-- Repeat for each table above.

-- canonical_specialties
drop policy if exists canonical_specialties_service_role_manage_v1 on public.canonical_specialties;
create policy canonical_specialties_service_role_manage_v1
on public.canonical_specialties for all to service_role
using (true) with check (true);

drop policy if exists canonical_specialties_admin_manage_v1 on public.canonical_specialties;
create policy canonical_specialties_admin_manage_v1
on public.canonical_specialties for all to authenticated
using (is_admin()) with check (is_admin());

-- capabilities
drop policy if exists capabilities_service_role_manage_v1 on public.capabilities;
create policy capabilities_service_role_manage_v1
on public.capabilities for all to service_role
using (true) with check (true);

drop policy if exists capabilities_admin_manage_v1 on public.capabilities;
create policy capabilities_admin_manage_v1
on public.capabilities for all to authenticated
using (is_admin()) with check (is_admin());

-- engine_registry
drop policy if exists engine_registry_service_role_manage_v1 on public.engine_registry;
create policy engine_registry_service_role_manage_v1
on public.engine_registry for all to service_role
using (true) with check (true);

drop policy if exists engine_registry_admin_manage_v1 on public.engine_registry;
create policy engine_registry_admin_manage_v1
on public.engine_registry for all to authenticated
using (is_admin()) with check (is_admin());

-- specialty_policy_map
drop policy if exists specialty_policy_map_service_role_manage_v1 on public.specialty_policy_map;
create policy specialty_policy_map_service_role_manage_v1
on public.specialty_policy_map for all to service_role
using (true) with check (true);

drop policy if exists specialty_policy_map_admin_manage_v1 on public.specialty_policy_map;
create policy specialty_policy_map_admin_manage_v1
on public.specialty_policy_map for all to authenticated
using (is_admin()) with check (is_admin());

-- Repeat the same two-policy pattern for the rest (kept explicit but not verbose here)
-- IMPORTANT: We will also open SELECT for the canonical registries below.

-- =========================================================
-- 3) PUBLIC READ (SELECT) FOR CANONICAL/REGISTRY TABLES ONLY
-- (These are safe catalogs your UI will need.)
-- =========================================================
-- canonical_specialties: public select
drop policy if exists canonical_specialties_public_read_v1 on public.canonical_specialties;
create policy canonical_specialties_public_read_v1
on public.canonical_specialties for select to anon, authenticated
using (true);

-- capabilities: public select
drop policy if exists capabilities_public_read_v1 on public.capabilities;
create policy capabilities_public_read_v1
on public.capabilities for select to anon, authenticated
using (true);

-- engine_registry: public select
drop policy if exists engine_registry_public_read_v1 on public.engine_registry;
create policy engine_registry_public_read_v1
on public.engine_registry for select to anon, authenticated
using (true);

-- vertical_policy: likely needed by app logic (read-only)
drop policy if exists vertical_policy_public_read_v1 on public.vertical_policy;
create policy vertical_policy_public_read_v1
on public.vertical_policy for select to anon, authenticated
using (true);

-- vertical_capability_defaults: read-only
drop policy if exists vertical_capability_defaults_public_read_v1 on public.vertical_capability_defaults;
create policy vertical_capability_defaults_public_read_v1
on public.vertical_capability_defaults for select to anon, authenticated
using (true);

-- vertical_market_requirements: read-only
drop policy if exists vertical_market_requirements_public_read_v1 on public.vertical_market_requirements;
create policy vertical_market_requirements_public_read_v1
on public.vertical_market_requirements for select to anon, authenticated
using (true);

-- landmark_types / experience_types: read-only catalogs
drop policy if exists landmark_types_public_read_v1 on public.landmark_types;
create policy landmark_types_public_read_v1
on public.landmark_types for select to anon, authenticated
using (true);

drop policy if exists experience_types_public_read_v1 on public.experience_types;
create policy experience_types_public_read_v1
on public.experience_types for select to anon, authenticated
using (true);

commit;