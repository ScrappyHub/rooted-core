-- ROOTED: AUTO-FIX-EXECUTE-CLOSER-MISMATCH-STEP-1N (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- ROOTED: AUTO-FIX-NESTED-EXECUTE-DOLLAR-TAG-STEP-1L (canonical)
-- ROOTED: AUTO-FIX-DO-OPENERS-STEP-1J2C (canonical)
begin;

-- =========================================
-- SAFETY ASSERTS (auditable fail-fast)
-- =========================================

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $pol$
begin
  -- ROOTED: AUTO-RLS-BEFORE-ASSERTS
  -- Determinism + zero-leak posture: enable RLS before safety asserts check it.
  -- Safe/idempotent: enabling RLS repeatedly is OK.
  execute 'alter table public.providers enable row level security';
  execute 'alter table public.events enable row level security';
  if to_regclass('public.providers') is null then
    raise exception 'policy_normalization: public.providers missing';
  end if;

  if to_regclass('public.events') is null then
    raise exception 'policy_normalization: public.events missing';
  end if;

  -- Ensure RLS is ON (if someone disabled it, stop immediately)
  if not (select relrowsecurity from pg_class where oid = 'public.providers'::regclass) then
    raise exception 'policy_normalization: RLS is OFF on public.providers';
  end if;

  if not (select relrowsecurity from pg_class where oid = 'public.events'::regclass) then
    raise exception 'policy_normalization: RLS is OFF on public.events';
  end if;
end;
$pol$;

-- =========================================
-- PROVIDERS: REMOVE OPEN/CONFLICTING POLICIES
-- =========================================
drop policy if exists "Enable read access for all users" on public.providers;
drop policy if exists "providers_read_all_v1" on public.providers;
drop policy if exists "Public can view discoverable providers" on public.providers;
drop policy if exists "Public can view active, discoverable providers" on public.providers;
drop policy if exists "Provider owner can view own provider" on public.providers;
drop policy if exists "Provider owner can read own billing status" on public.providers;
drop policy if exists "Provider owner can update own provider" on public.providers;
drop policy if exists "Admin can read all billing data" on public.providers;
drop policy if exists "providers_owner_manage_v1" on public.providers;
drop policy if exists "Enable insert for authenticated users only" on public.providers;

-- Keep: providers_service_role_manage_v1 (service_role ALL true)

-- =========================================
-- PROVIDERS: RECREATE MINIMAL + AUDITABLE POLICIES
-- =========================================

-- 1) Public/Anon discovery read: ONLY discoverable + active owner account

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $pol$
begin
  -- ROOTED: AUTO-RLS-BEFORE-ASSERTS
  -- Determinism + zero-leak posture: enable RLS before safety asserts check it.
  -- Safe/idempotent: enabling RLS repeatedly is OK.
  execute 'alter table public.providers enable row level security';
  execute 'alter table public.events enable row level security';
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'providers'
      AND column_name  = 'is_discoverable'
  ) THEN
    execute $q$
      create policy providers_public_read_discoverable_v2
      on public.providers
      for select
      to anon, authenticated
      using (
        is_discoverable = true
        and exists (
          select 1
          from public.user_tiers ut
          where ut.user_id = providers.owner_user_id
            and ut.account_status = 'active'
        )
      );
    $q$;
  ELSE
    RAISE NOTICE 'remote_schema: skipped providers_public_read_discoverable_v2 (missing providers.is_discoverable)';
  END IF;
END
$$;

-- 2) Owner can read their own row (authenticated only)
create policy providers_owner_read_v2
on public.providers
for select
to authenticated
using (owner_user_id = auth.uid());

-- 3) Admin can read all rows (authenticated only)
create policy providers_admin_read_v2
on public.providers
for select
to authenticated
using (is_admin());

-- 4) Owner insert (forces owner_user_id to auth.uid())
create policy providers_owner_insert_v2
on public.providers
for insert
to authenticated
with check (owner_user_id = auth.uid());

-- 5) Owner update (forces owner_user_id to remain auth.uid())
create policy providers_owner_update_v2
on public.providers
for update
to authenticated
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

-- NOTE: We intentionally DO NOT create a DELETE policy here.
-- That means hard deletes are blocked by default (recommended).

-- =========================================
-- EVENTS: DROP DUPLICATE/WEAK POLICIES (KEEP V7)
-- =========================================
drop policy if exists events_host_vendor_insert_v6 on public.events;
drop policy if exists events_host_vendor_update_v6 on public.events;
drop policy if exists events_host_vendor_delete_v6 on public.events;

-- Drop the extra public read (you already have anon+authenticated version)
drop policy if exists events_public_read_published_approved_v1 on public.events;

-- Drop the risky sanctuary policy (USING true on UPDATE = not auditable-safe)
drop policy if exists sanctuary_vendors_update_volunteer_only on public.events;

commit;