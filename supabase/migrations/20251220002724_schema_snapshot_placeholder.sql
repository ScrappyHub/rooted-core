-- ============================================================
-- ROOTED: Placeholder migration (history purge reconciliation)
-- Version: 20251220002724
-- Why:
--   - A prior migration at this version was an oversized schema snapshot and has been
--     removed from git history for GitHub safety.
--   - Supabase CLI expects this version to exist locally because it is recorded in the
--     remote schema_migrations table.
-- What:
--   - No-op. Keeps migration timeline consistent without reintroducing large files.
-- ============================================================

DO $$
BEGIN
  -- no-op
END
$$;