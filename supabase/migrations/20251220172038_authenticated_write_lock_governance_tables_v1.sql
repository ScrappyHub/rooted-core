begin;

-- =========================================================
-- AUTHENTICATED WRITE LOCK: GOVERNANCE / ADMIN TABLES (v1)
-- Goal:
-- - Remove INSERT/UPDATE/DELETE from authenticated on tables that
--   should be managed only by service_role/admin pipelines.
-- - Keep SELECT untouched (RLS still governs reads).
-- - Keep product-flow write tables untouched in this step.
-- =========================================================

-- Canonical / taxonomy (MUST NOT be client-writable)
revoke insert, update, delete on public.canonical_verticals from authenticated;
revoke insert, update, delete on public.canonical_specialties from authenticated;
revoke insert, update, delete on public.vertical_canonical_specialties from authenticated;

-- Governance engines / capability registries
revoke insert, update, delete on public.engine_registry from authenticated;
revoke insert, update, delete on public.capabilities from authenticated;

-- Policy maps / overlays / vertical constraints (should be admin/service managed)
revoke insert, update, delete on public.specialty_policy_map from authenticated;
revoke insert, update, delete on public.specialty_vertical_overlays from authenticated;
revoke insert, update, delete on public.vertical_conditions from authenticated;

-- Billing + analytics should not be client-writable (writes come from backend jobs/webhooks)
revoke insert, update, delete on public.billing_customers from authenticated;
revoke insert, update, delete on public.vendor_analytics_daily from authenticated;

-- Admin actions + moderation queue should not be client-writable directly
revoke insert, update, delete on public.user_admin_actions from authenticated;
revoke insert, update, delete on public.moderation_queue from authenticated;

-- User tiers are governance-controlled (avoid client elevation paths)
revoke insert, update, delete on public.user_tiers from authenticated;

commit;