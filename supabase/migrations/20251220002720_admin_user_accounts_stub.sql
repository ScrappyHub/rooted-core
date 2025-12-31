-- ROOTED: AUTO-FIX-NESTED-EXECUTE-DOLLAR-TAG-STEP-1L (canonical)
-- ROOTED: AUTO-FIX-DO-TAG-MISMATCH-STEP-1K (canonical)
-- 20251220002720_admin_user_accounts_stub.sql
-- SAFETY PATCH (REMOTE-SAFE):
-- Ensure public.admin_user_accounts rowtype exists BEFORE 20251220002724_remote_schema.sql
-- CRITICAL FIX: cannot DROP VIEW if a function depends on its rowtype. Drop dependent function(s) first.

begin;

-- 1) is_admin() stub (only meaningful once user_tiers exists; otherwise false)
do $body$
begin
  if not exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'is_admin'
      and pg_get_function_identity_arguments(p.oid) = ''
  ) then
    execute $fn$
      create or replace function public.is_admin()
      returns boolean
      language plpgsql
      stable
      security definer
      set search_path = public
      as $body$
      begin
        if to_regclass('public.user_tiers') is null then
          return false;
        end if;

        return exists (
          select 1
          from public.user_tiers ut
          where ut.user_id = auth.uid()
            and ut.role = 'admin'
        );
      end;
      $body$;
      $fn$;
  end if;
end $$;

-- 2) admin_user_accounts stub view (creates the rowtype with FINAL column names/order)
do $v$
declare
  r record;
begin
  -- Drop any dependent function overloads that reference the view rowtype.
  for r in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and p.proname='admin_get_user_accounts'
  loop
    raise notice 'Dropping dependent function: %', r.sig;
    execute format('drop function if exists %s', r.sig);
  end loop;

  -- Now it is safe to drop/recreate the view (rowtype).
  if to_regclass('public.admin_user_accounts') is not null then
    execute 'drop view public.admin_user_accounts';
  end if;

  execute $q$
    create view public.admin_user_accounts as
    select
      u.id                    as user_id,
      u.email                 as email,
      null::text              as role,
      null::text              as tier,
      null::text              as account_status,
      '{}'::jsonb             as feature_flags,
      null::text              as deletion_status,
      null::timestamptz       as deletion_requested_at
    from auth.users u;
  $q$;

  -- Recreate a minimal stub so anything expecting it doesn't break.
  execute $fn$
    create or replace function public.admin_get_user_accounts()
    returns setof public.admin_user_accounts
    language sql
    stable
    security definer
    set search_path = public
    as $body$
      select * from public.admin_user_accounts;
    $body$;
    $fn$;

  revoke all on function public.admin_get_user_accounts() from anon;
  grant execute on function public.admin_get_user_accounts() to authenticated;
  grant execute on function public.admin_get_user_accounts() to service_role;

end $$;

commit;