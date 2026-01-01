-- ROOTED: STRIP-EXECUTE-DOLLAR-QUOTES-STEP-1P (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
-- ROOTED: AUTO-FIX-EXECUTE-CLOSER-MISMATCH-STEP-1N (canonical)
-- ROOTED: AUTO-FIX-NESTED-EXECUTE-DOLLAR-TAG-STEP-1L (canonical)
-- ROOTED: AUTO-FIX-DO-TAG-MISMATCH-STEP-1K (canonical)
begin;

-- =========================================================
-- PATCH: admin_user_accounts view is depended on by admin_get_user_accounts()
-- Goal:
--   - Safely replace the admin_user_accounts view signature
--   - By dropping dependent function(s) first (introspected)
--   - Then recreating view with FINAL column order
--   - Then recreating function stub (or you can paste final body if you have it)
-- =========================================================

do $v$
declare
  v_view_exists boolean := (to_regclass('public.admin_user_accounts') is not null);
  r record;
begin
  if not v_view_exists then
    raise notice 'patch_admin_user_accounts: view does not exist; creating.';
  else
    raise notice 'patch_admin_user_accounts: view exists; will replace safely.';
  end if;

  -- 1) Drop any public.admin_get_user_accounts(...) overloads (they depend on the view rowtype)
  for r in
    select
      p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and p.proname='admin_get_user_accounts'
  loop
    raise notice 'Dropping dependent function: %', r.sig;
    execute format('drop function if exists %s cascade', r.sig);
  end loop;

  -- 2) Now it is safe to drop/recreate the view (to establish FINAL signature)
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
  $v$;

  -- 3) Recreate the function (STUB)
  -- NOTE: If you already have the real function body elsewhere later in migrations,
  -- this stub just makes the schema consistent for now.
    create or replace function public.admin_get_user_accounts()
    returns setof public.admin_user_accounts
    language sql
    stable
    security definer
    set search_path = public
    as $body$
      select * from public.admin_user_accounts;
  $fn$;

  -- 4) Permissions (tighten later if needed; keep minimal sane defaults)
  revoke all on function public.admin_get_user_accounts() from anon;
  grant execute on function public.admin_get_user_accounts() to authenticated;
  grant execute on function public.admin_get_user_accounts() to service_role;

end $$;

commit;