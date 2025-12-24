-- NOTE:
-- This migration cannot run under the local Supabase migration runner because it lacks
-- permission to ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin.
-- The equivalent commands must be executed as postgres inside the container.
-- See hardening runbook.

select 1;