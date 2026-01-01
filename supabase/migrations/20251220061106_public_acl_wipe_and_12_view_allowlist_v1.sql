-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- PUBLIC ACL WIPE + 12-VIEW ANON ALLOWLIST (v1)
-- Goals:
-- 1) anon: zero privileges on ALL base tables, sequences, functions
-- 2) anon: SELECT only on these 12 public views:
--    - arts_culture_events_discovery_v1
--    - arts_culture_providers_discovery_v1
--    - community_landmarks_kidsafe_v1
--    - community_providers_discovery_v1
--    - education_providers_discovery_v1
--    - events_discovery_v1
--    - events_public_v1
--    - experiences_discovery_v1
--    - landmarks_public_kids_v1
--    - landmarks_public_v1
--    - providers_discovery_v1
--    - providers_public_v1
--
-- 3) authenticated: unchanged in this migration (you can tighten next once you decide exact app needs)

do $$
declare
  r record;
begin
  -- Revoke everything from anon on tables/views/matviews
  for r in
    select c.oid::regclass as obj
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public'
      and c.relkind in ('r','v','m','p','f')  -- table, view, matview, partitioned table, foreign table
  loop
    execute format('revoke all on %s from anon', r.obj);
  end loop;

  -- Revoke everything from anon on sequences
  for r in
    select c.oid::regclass as obj
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public'
      and c.relkind='S'
  loop
    execute format('revoke all on %s from anon', r.obj);
  end loop;

  -- Revoke execute on all functions in public from anon
  for r in
    select p.oid::regprocedure as obj
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='public'
  loop
    execute format('revoke all on function %s from anon', r.obj);
  end loop;
end;
$$;

-- Re-grant SELECT only on the 12 views
DO $$
BEGIN
  IF to_regclass('public.arts_culture_events_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.arts_culture_events_discovery_v1 to anon';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.arts_culture_events_discovery_v1 to anon';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.arts_culture_providers_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.arts_culture_providers_discovery_v1 to anon';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.arts_culture_providers_discovery_v1 to anon';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.community_landmarks_kidsafe_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.community_landmarks_kidsafe_v1 to anon';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.community_landmarks_kidsafe_v1 to anon';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.community_providers_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.community_providers_discovery_v1 to anon';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.community_providers_discovery_v1 to anon';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.education_providers_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.education_providers_discovery_v1 to anon';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.education_providers_discovery_v1 to anon';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.events_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.events_discovery_v1 to anon';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.events_discovery_v1 to anon';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.events_public_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.events_public_v1 to anon';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.events_public_v1 to anon';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.experiences_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.experiences_discovery_v1 to anon';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.experiences_discovery_v1 to anon';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.landmarks_public_kids_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.landmarks_public_kids_v1 to anon';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.landmarks_public_kids_v1 to anon';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.landmarks_public_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.landmarks_public_v1 to anon';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.landmarks_public_v1 to anon';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.providers_discovery_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.providers_discovery_v1 to anon';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.providers_discovery_v1 to anon';
  END IF;
end;
$$;
DO $$
BEGIN
  IF to_regclass('public.providers_public_v1') IS NOT NULL THEN
    EXECUTE 'grant select on public.providers_public_v1 to anon';
  ELSE
    RAISE NOTICE 'remote_schema: skip grant missing view public.providers_public_v1 to anon';
  END IF;
end;
$$;
commit;