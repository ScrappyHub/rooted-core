-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ============================================================
-- ROOTED: Placeholder migration (history purge reconciliation)
-- Version: 20251220002724
-- Why:
--   - Prior migration at this version was an oversized schema snapshot and was purged
--     from git history for GitHub safety.
--   - Supabase CLI expects this version locally because it exists in schema_migrations.
-- What:
--   - No-op placeholder. Keeps timeline consistent without large files.
-- ============================================================

DO $$
BEGIN
  -- no-op
END;
$$;