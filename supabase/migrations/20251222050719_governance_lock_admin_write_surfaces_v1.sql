BEGIN;

-- Helper: replace a permissive policy with an admin-only version
-- Note: Postgres cannot ALTER POLICY roles; we DROP + CREATE.

-- badges
DROP POLICY IF EXISTS badges_admin_all_access ON public.badges;
CREATE POLICY badges_admin_all_access
ON public.badges
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- canonical_specialties
DROP POLICY IF EXISTS canonical_specialties_admin_manage_v1 ON public.canonical_specialties;
CREATE POLICY canonical_specialties_admin_manage_v1
ON public.canonical_specialties
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- capabilities
DROP POLICY IF EXISTS capabilities_admin_manage_v1 ON public.capabilities;
CREATE POLICY capabilities_admin_manage_v1
ON public.capabilities
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- engine_registry
DROP POLICY IF EXISTS engine_registry_admin_manage_v1 ON public.engine_registry;
CREATE POLICY engine_registry_admin_manage_v1
ON public.engine_registry
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- provider_badges
DROP POLICY IF EXISTS provider_badges_admin_all_access ON public.provider_badges;
CREATE POLICY provider_badges_admin_all_access
ON public.provider_badges
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- provider_impact_snapshots
DROP POLICY IF EXISTS admin_can_all_provider_impacts ON public.provider_impact_snapshots;
CREATE POLICY admin_can_all_provider_impacts
ON public.provider_impact_snapshots
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- specialty_policy_map
DROP POLICY IF EXISTS specialty_policy_map_admin_manage_v1 ON public.specialty_policy_map;
CREATE POLICY specialty_policy_map_admin_manage_v1
ON public.specialty_policy_map
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- specialty_vertical_overlays
DROP POLICY IF EXISTS svo_admin_write ON public.specialty_vertical_overlays;
CREATE POLICY svo_admin_write
ON public.specialty_vertical_overlays
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- vertical_canonical_specialties
DROP POLICY IF EXISTS vcs_admin_write ON public.vertical_canonical_specialties;
CREATE POLICY vcs_admin_write
ON public.vertical_canonical_specialties
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

COMMIT;