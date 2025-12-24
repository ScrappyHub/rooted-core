begin;

-- PUBLIC SCHEMA DDL GUARD (v1)
-- Goal: prevent accidental schema changes in public from tools/UI that might use supabase_admin defaults.
-- Strategy: REVOKE CREATE on schema public from authenticated roles; leave postgres/service_role.
-- Note: this does NOT affect SELECT/INSERT/UPDATE/DELETE privileges on tables.

revoke create on schema public from anon;
revoke create on schema public from authenticated;

-- Keep typical backend roles able to create (migrations / service)
grant usage on schema public to anon;
grant usage on schema public to authenticated;

commit;