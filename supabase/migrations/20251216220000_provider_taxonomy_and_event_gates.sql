-- 20251216220000_provider_taxonomy_and_event_gates.sql
-- NOTE:
-- This migration originally attempted dynamic event RLS creation using INSERT USING,
-- which is invalid in Postgres (INSERT policies may only use WITH CHECK).
-- The correct event gating is implemented in:
--   20251216221500_events_host_vendor_gates_v1.sql
-- Provider taxonomy enforcement is implemented via:
--   20251216213000_provider_vertical_enforcement_and_overlay_rpc.sql
-- Therefore this migration is now intentionally a no-op so remote can progress.

begin;
commit;
