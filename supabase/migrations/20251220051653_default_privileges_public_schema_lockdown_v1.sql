begin;

-- Set default privileges so anon/authenticated do not automatically get anything
-- You can still explicitly GRANT later where intended.

alter default privileges in schema public revoke all on tables    from anon;
alter default privileges in schema public revoke all on tables    from authenticated;

alter default privileges in schema public revoke all on sequences from anon;
alter default privileges in schema public revoke all on sequences from authenticated;

alter default privileges in schema public revoke all on functions from anon;
alter default privileges in schema public revoke all on functions from authenticated;

commit;