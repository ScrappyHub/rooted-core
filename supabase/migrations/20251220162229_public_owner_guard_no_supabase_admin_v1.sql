begin;

-- PUBLIC OWNER GUARD (v1)
-- Fail hard if ANY objects in public are owned by supabase_admin.
-- This prevents "surprise exposure" from UI-created schema objects.

do $$
declare
  cnt int;
begin
  select count(*) into cnt
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public'
    and c.relkind in ('r','v','m','S','p','f')  -- table, view, matview, sequence, partitioned, foreign
    and pg_get_userbyid(c.relowner)='supabase_admin';

  if cnt > 0 then
    raise exception
      'Hardening violation: % objects in public are owned by supabase_admin. All public objects must be owned by postgres.',
      cnt;
  end if;
end $$;

commit;