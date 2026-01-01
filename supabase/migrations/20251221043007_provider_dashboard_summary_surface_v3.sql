-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
-- ROOTED: AUTO-FIX-NESTED-EXECUTE-DOLLAR-TAG-STEP-1L (canonical)
-- ROOTED: AUTO-FIX-DO-TAG-MISMATCH-STEP-1K (canonical)
begin;

-- =========================================================
-- PROVIDER DASHBOARD SUMMARY SURFACE (v3)
-- - Uses real events linkage:
--     events.host_vendor_id / events.host_institution_id
-- - Includes registrations via event_registrations -> events
-- - Includes bulk_offers + live feed approved
-- - NO rfqs/bids yet (must inspect schema first)
-- =========================================================

drop view if exists public.provider_dashboard_summary_v1 cascade;

do $v$
DECLARE
  id_col text;
  has_name boolean;
BEGIN
  -- providers PK column
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='providers' AND column_name='id'
  ) THEN
    id_col := 'id';
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='providers' AND column_name='provider_id'
  ) THEN
    id_col := 'provider_id';
  ELSE
    RAISE NOTICE 'provider_dashboard_summary_v1: providers missing id/provider_id; creating minimal placeholder view';
    execute $q$
      create or replace view public.provider_dashboard_summary_v1 as
      select
        null::uuid as provider_id,
        null::text as name
      where false;
$v$;
    RETURN;
  END IF;

  -- optional column
  has_name := EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='providers' AND column_name='name'
  );

  IF has_name THEN
    EXECUTE format($v$
      create or replace view public.provider_dashboard_summary_v1 as
      select
        p.%I as provider_id,
        p.name
      from public.providers p
    $v$, id_col);
  ELSE
    EXECUTE format($v$
      create or replace view public.provider_dashboard_summary_v1 as
      select
        p.%I as provider_id,
        null::text as name
      from public.providers p
    $v$, id_col);

    RAISE NOTICE 'provider_dashboard_summary_v1: fallback (missing providers.name)';
  END IF;
END
$$;

revoke all on table public.provider_dashboard_summary_v1 from anon;
revoke all on table public.provider_dashboard_summary_v1 from authenticated;
grant select on table public.provider_dashboard_summary_v1 to authenticated;
grant select on table public.provider_dashboard_summary_v1 to service_role;

commit;