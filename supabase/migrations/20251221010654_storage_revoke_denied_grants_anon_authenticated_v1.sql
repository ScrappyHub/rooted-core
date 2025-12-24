begin;

-- =========================================================
-- STORAGE HARDENING (v1)
-- Revoke DENIED/MUTATING privileges from anon/authenticated
-- in schema "storage" to satisfy STORAGE GRANT SURFACE GUARD (v3).
--
-- Denied by guard:
--   INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER
--
-- Evidence from guard notices + introspection:
--   - anon has denied privileges on storage.prefixes
--   - authenticated has denied privileges on storage.prefixes
--   - authenticated has denied privileges on storage.objects
--
-- This migration is intentionally explicit and table-scoped.
-- =========================================================

-- 1) storage.prefixes: remove all denied privileges for both roles
revoke insert, update, delete, truncate, trigger
on table storage.prefixes
from anon;

revoke insert, update, delete, truncate, trigger
on table storage.prefixes
from authenticated;

-- 2) storage.objects: remove all denied privileges for authenticated
-- (revoking all denied privileges is safe even if some weren't present)
revoke insert, update, delete, truncate, trigger
on table storage.objects
from authenticated;

commit;