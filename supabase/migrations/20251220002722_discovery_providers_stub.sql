-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
-- ROOTED: AUTO-FIX-EXECUTE-CLOSER-MISMATCH-STEP-1N (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- ROOTED: AUTO-FIX-NESTED-EXECUTE-DOLLAR-TAG-STEP-1L (canonical)
-- ROOTED: AUTO-FIX-DO-TAG-MISMATCH-STEP-1K (canonical)
-- 20251220002722_discovery_providers_stub.sql
-- SAFETY PATCH: Ensure public.discovery_providers exists (rowtype) BEFORE 20251220002724_remote_schema.sql
-- CRITICAL: Column order/signature MUST match the real view so CREATE OR REPLACE VIEW won't fail.
-- Real view expects: id, name, specialty, city, state, lat, lng, is_verified, engagement_score, last_shown_at, created_at

begin;

do $v$
declare
  v_providers regclass;
begin
  v_providers := to_regclass('public.providers');

  -- If discovery_providers already exists and is a view, drop it so we can guarantee signature.
  if to_regclass('public.discovery_providers') is not null then
    begin
      execute 'drop view public.discovery_providers';
    exception when others then
      -- If it's not a view (table/type), do not destroy data here.
      raise notice 'discovery_providers_stub: discovery_providers exists but is not a droppable view; leaving as-is.';
      return;
    end;
  end if;

  -- Create minimal stub view with the EXACT expected columns + order.
  if v_providers is not null then
    execute $q$
      create view public.discovery_providers as
      select
        null::uuid              as id,
        null::text              as name,
        null::text              as specialty,
        null::text              as city,
        null::text              as state,
        null::double precision  as lat,
        null::double precision  as lng,
        null::boolean           as is_verified,
        null::numeric           as engagement_score,
        null::timestamptz       as last_shown_at,
        now()::timestamptz      as created_at
      from public.providers p
      where false;
    $v$;
  else
    execute $q$
      create view public.discovery_providers as
      select
        null::uuid              as id,
        null::text              as name,
        null::text              as specialty,
        null::text              as city,
        null::text              as state,
        null::double precision  as lat,
        null::double precision  as lng,
        null::boolean           as is_verified,
        null::numeric           as engagement_score,
        null::timestamptz       as last_shown_at,
        now()::timestamptz      as created_at
      where false;
    $q$;
  end if;

end $$;

commit;