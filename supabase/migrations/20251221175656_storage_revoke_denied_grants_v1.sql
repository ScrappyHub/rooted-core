begin;

-- =========================================================
-- STORAGE HARDENING: REVOKE MUTATING GRANTS (anon/authenticated)
-- Purpose:
--   Satisfy STORAGE GRANT SURFACE GUARD (v3)
--   Deny these privilege types in schema "storage":
--     INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER
--
-- Observed offenders (from information_schema.role_table_grants):
--   storage.buckets           : anon + authenticated (mutating)
--   storage.buckets_analytics : anon + authenticated (mutating)
--   storage.objects           : anon + authenticated (mutating)
--   storage.prefixes          : anon + authenticated (mutating)
--
-- This migration is explicit + table-scoped (no blanket REVOKE ALL).
-- =========================================================

-- storage.buckets
revoke insert, update, delete, truncate, trigger on table storage.buckets from anon;
revoke insert, update, delete, truncate, trigger on table storage.buckets from authenticated;

-- storage.buckets_analytics
revoke insert, update, delete, truncate, trigger on table storage.buckets_analytics from anon;
revoke insert, update, delete, truncate, trigger on table storage.buckets_analytics from authenticated;

-- storage.objects
revoke insert, update, delete, truncate, trigger on table storage.objects from anon;
revoke insert, update, delete, truncate, trigger on table storage.objects from authenticated;

-- storage.prefixes
revoke insert, update, delete, truncate, trigger on table storage.prefixes from anon;
revoke insert, update, delete, truncate, trigger on table storage.prefixes from authenticated;

commit;