begin;

-- =========================================================
-- DEFAULT ACL GUARD (public schema) (v3)
-- Canonical: hard-fail ONLY for roles we control (creator roles for app objects).
-- supabase_admin is Supabase-managed; warn but do not block deploy.
-- =========================================================

do $$
declare
  bad_controlled int := 0;
  bad_supabase_admin int := 0;
  r record;
begin
  -- Controlled roles: migrations normally execute as postgres.
  -- If you discover additional controlled creator roles, add them here.
  select count(*) into bad_controlled
  from pg_default_acl d
  where d.defaclnamespace = 'public'::regnamespace
    and d.defaclrole::regrole::text in ('postgres')
    and exists (
      select 1
      from unnest(d.defaclacl) a
      where a::text like 'anon=%'
         or a::text like 'authenticated=%'
    );

  if bad_controlled > 0 then
    raise exception
      'Hardening violation: CONTROLLED default ACLs in public still grant to anon/authenticated (role=postgres).';
  end if;

  -- Managed role: supabase_admin (Supabase-owned). We warn if present.
  select count(*) into bad_supabase_admin
  from pg_default_acl d
  where d.defaclnamespace = 'public'::regnamespace
    and d.defaclrole = 'supabase_admin'::regrole
    and exists (
      select 1
      from unnest(d.defaclacl) a
      where a::text like 'anon=%'
         or a::text like 'authenticated=%'
    );

  if bad_supabase_admin > 0 then
    raise notice
      'NOTICE: supabase_admin default ACLs in public grant to anon/authenticated (Supabase-managed). Guard is not hard-failing this.';
    -- Optional: print what it found (kept as NOTICE only)
    for r in
      select
        d.defaclobjtype as objtype,
        a::text as acl_item
      from pg_default_acl d
      cross join lateral unnest(d.defaclacl) a
      where d.defaclnamespace = 'public'::regnamespace
        and d.defaclrole = 'supabase_admin'::regrole
        and (a::text like 'anon=%' or a::text like 'authenticated=%')
      order by 1,2
    loop
      raise notice 'supabase_admin default ACL: objtype=% acl=%', r.objtype, r.acl_item;
    end loop;
  end if;

end $$;

commit;