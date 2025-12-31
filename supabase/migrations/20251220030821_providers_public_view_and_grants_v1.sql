-- ROOTED: AUTO-FIX-NESTED-EXECUTE-DOLLAR-TAG-STEP-1L (canonical)
-- ROOTED: AUTO-FIX-DO-TAG-MISMATCH-STEP-1K (canonical)
begin;

-- =========================================================
-- SAFETY ASSERTS (fail-fast + auditable)
-- =========================================================
do $v$
begin
  if to_regclass('public.providers') is null then
    raise exception 'providers_public_view_and_grants_v1: public.providers missing';
  end if;

  if to_regclass('public.user_tiers') is null then
    raise exception 'providers_public_view_and_grants_v1: public.user_tiers missing';
  end if;

  if not (select relrowsecurity from pg_class where oid = 'public.providers'::regclass) then
    raise exception 'providers_public_view_and_grants_v1: RLS is OFF on public.providers';
  end if;
end $$;

-- =========================================================
-- 1) SAFE PUBLIC VIEW (no billing columns)
--    NOTE: list columns explicitly (no SELECT *)
-- =========================================================
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='public'
      AND table_name='providers'
      AND column_name='name'
  ) THEN
    execute $q$
      create or replace view public.providers_public_v1 as
      select
        p.id,
        p.owner_user_id,
        p.name
      from public.providers p;
    $q$;
  ELSE
    execute $q$
      create or replace view public.providers_public_v1 as
      select
        p.id,
        p.owner_user_id,
        NULL::text as name
      from public.providers p;
    $q$;

    RAISE NOTICE 'remote_schema: providers_public_v1 fallback (missing providers.name)';
  END IF;
END
$$;

comment on view public.providers_public_v1 is
'Public-safe provider projection for discovery. Excludes billing/sensitive columns.';

-- =========================================================
-- 2) GRANTS HARDENING
--    Goal: anon/authenticated read via VIEW, not table.
--    (Service role/admin still query table.)
-- =========================================================

-- Revoke broad table reads (prevents column leakage via REST if someone selects billing fields)
revoke all on table public.providers from anon;
revoke all on table public.providers from authenticated;

-- Allow inserts/updates still handled by RLS policies (grants required for DML)
grant insert, update on table public.providers to authenticated;

-- Allow public discovery reads via the safe view
grant select on public.providers_public_v1 to anon, authenticated;

commit;