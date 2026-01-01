-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
-- =========================================================
-- STORAGE RLS GUARD (Hosted-compatible)
-- Supabase Hosted: storage tables are platform-owned.
-- FORCE RLS cannot be set by project roles (permission denied).
--
-- Canonical enforcement here:
--   - Require RLS ENABLED (relrowsecurity = true)
--   - Do NOT require FORCE RLS (relforcerowsecurity) because it's not attainable.
-- =========================================================

do $$
declare
  bad int;
begin
  select count(*) into bad
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'storage'
    and c.relname in ('buckets','objects')
    and c.relrowsecurity = false;

  if bad > 0 then
    raise exception 'Hardening violation: storage.buckets/objects do not have RLS enabled.';
  end if;

  -- informational only (do NOT fail)
  raise notice 'storage.buckets/objects FORCE RLS = %, % (hosted storage may prevent setting this)',
    (select c.relforcerowsecurity
       from pg_class c join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='storage' and c.relname='buckets'),
    (select c.relforcerowsecurity
       from pg_class c join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='storage' and c.relname='objects');
end;
$$;