begin;

-- =========================================================
-- STORAGE DENIED GRANTS SWEEP (v2)
-- Goal: make denied privileges = 0 for anon/authenticated in storage schema.
--
-- Removes: INSERT/UPDATE/DELETE/TRUNCATE/TRIGGER/REFERENCES/MAINTAIN
-- Also hardens DEFAULT PRIVILEGES so they don't come back.
-- =========================================================

do $$
declare
  r record;
begin
  -- Revoke denied privileges table-by-table (explicit + auditable)
  for r in
    select c.relname as table_name
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'storage'
      and c.relkind = 'r'
      and c.relname in ('buckets','buckets_analytics','objects','prefixes')
  loop
    execute format('revoke insert, update, delete, truncate, trigger, references, maintain on table storage.%I from anon;', r.table_name);
    execute format('revoke insert, update, delete, truncate, trigger, references, maintain on table storage.%I from authenticated;', r.table_name);
  end loop;

  -- Prevent re-grants via default ACLs (best-effort)
  begin
    alter default privileges in schema storage revoke insert, update, delete, truncate, references, trigger on tables from anon;
    alter default privileges in schema storage revoke insert, update, delete, truncate, references, trigger on tables from authenticated;
  exception when others then
    raise notice 'default privileges revoke skipped (non-fatal): %', sqlerrm;
  end;

end $$;

commit;
