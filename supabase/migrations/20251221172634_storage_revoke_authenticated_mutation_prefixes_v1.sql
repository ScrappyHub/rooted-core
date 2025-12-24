begin;

-- =========================================================
-- STORAGE HARDENING (v1)
-- Revoke MUTATING / DANGEROUS privileges from role "authenticated"
-- on storage-managed tables.
--
-- Canonical ROOTED law:
--   - authenticated must NOT have direct write-ish privileges in schema "storage"
--   - rely on Storage API + RLS, not direct DML into storage support tables
--
-- This migration is intentionally narrow and evidence-based:
--   We only revoke privileges we observed on storage.prefixes:
--     UPDATE, TRUNCATE, TRIGGER
--
-- If diagnostics later show additional dangerous privileges elsewhere,
-- create another migration with explicit revokes per-object.
-- =========================================================

revoke update, truncate, trigger
on table storage.prefixes
from authenticated;

commit;