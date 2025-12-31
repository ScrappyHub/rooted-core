-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- GRANTS SYNC v2
-- - policy TO public no longer implies anon grants
-- - anon requires explicit policy role 'anon'
-- - authenticated allowed if role is 'authenticated' OR 'public'
-- =========================================================

do $$
declare
  t record;
  has_anon_select boolean;
  has_auth_select boolean;
  has_auth_insert boolean;
  has_auth_update boolean;
  has_auth_delete boolean;
  has_auth_all boolean;
begin
  -- revoke everything first (clean slate)
  for t in
    select c.oid::regclass as fqtn
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public'
      and c.relkind='r'
  loop
    execute format('revoke all on table %s from anon', t.fqtn);
    execute format('revoke all on table %s from authenticated', t.fqtn);
  end loop;

  -- regrant per table based on policies
  for t in
    select n.nspname as schemaname, c.relname as tablename, c.oid::regclass as fqtn
    from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relkind='r'
  loop
    -- anon: ONLY explicit anon policies
    select exists (
      select 1 from pg_policies p
      where p.schemaname=t.schemaname and p.tablename=t.tablename and p.cmd='SELECT'
        and ('anon' = any(p.roles))
    )
    into has_anon_select;

    -- authenticated: authenticated OR public
    select
      exists (
        select 1 from pg_policies p
        where p.schemaname=t.schemaname and p.tablename=t.tablename and p.cmd='SELECT'
          and ('authenticated' = any(p.roles) or 'public' = any(p.roles))
      ),
      exists (
        select 1 from pg_policies p
        where p.schemaname=t.schemaname and p.tablename=t.tablename and p.cmd='INSERT'
          and ('authenticated' = any(p.roles) or 'public' = any(p.roles))
      ),
      exists (
        select 1 from pg_policies p
        where p.schemaname=t.schemaname and p.tablename=t.tablename and p.cmd='UPDATE'
          and ('authenticated' = any(p.roles) or 'public' = any(p.roles))
      ),
      exists (
        select 1 from pg_policies p
        where p.schemaname=t.schemaname and p.tablename=t.tablename and p.cmd='DELETE'
          and ('authenticated' = any(p.roles) or 'public' = any(p.roles))
      ),
      exists (
        select 1 from pg_policies p
        where p.schemaname=t.schemaname and p.tablename=t.tablename and p.cmd='ALL'
          and ('authenticated' = any(p.roles) or 'public' = any(p.roles))
      )
    into
      has_auth_select,
      has_auth_insert,
      has_auth_update,
      has_auth_delete,
      has_auth_all;

    if has_anon_select then
      execute format('grant select on table %s to anon', t.fqtn);
    end if;

    if has_auth_all then
      execute format('grant select, insert, update, delete on table %s to authenticated', t.fqtn);
    else
      if has_auth_select then execute format('grant select on table %s to authenticated', t.fqtn); end if;
      if has_auth_insert then execute format('grant insert on table %s to authenticated', t.fqtn); end if;
      if has_auth_update then execute format('grant update on table %s to authenticated', t.fqtn); end if;
      if has_auth_delete then execute format('grant delete on table %s to authenticated', t.fqtn); end if;
    end if;
  end loop;
end;
$$;

commit;