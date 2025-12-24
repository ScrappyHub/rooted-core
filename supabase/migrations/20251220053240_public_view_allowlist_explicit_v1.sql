begin;

-- =========================================================
-- PUBLIC VIEW ALLOWLIST (explicit)
-- - revoke ALL privileges for anon/authenticated on ALL views/matviews
-- - then grant SELECT ONLY on the explicit allowlist (12 views)
-- - no pattern matching: prevents naming-collision surprise exposure
-- =========================================================

do $$
declare
  v record;
begin
  -- 1) revoke everything on ALL views/matviews in public schema
  for v in
    select c.oid::regclass as fqvn
    from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relkind in ('v','m')
  loop
    execute format('revoke all on %s from anon', v.fqvn);
    execute format('revoke all on %s from authenticated', v.fqvn);
  end loop;

  -- 2) grant SELECT-only to anon/authenticated on explicit allowlist
  --    (keep this list tight + auditable)

  -- discovery
  execute 'grant select on public.providers_discovery_v1 to anon';
  execute 'grant select on public.providers_discovery_v1 to authenticated';

  execute 'grant select on public.community_providers_discovery_v1 to anon';
  execute 'grant select on public.community_providers_discovery_v1 to authenticated';

  execute 'grant select on public.education_providers_discovery_v1 to anon';
  execute 'grant select on public.education_providers_discovery_v1 to authenticated';

  execute 'grant select on public.arts_culture_providers_discovery_v1 to anon';
  execute 'grant select on public.arts_culture_providers_discovery_v1 to authenticated';

  execute 'grant select on public.arts_culture_events_discovery_v1 to anon';
  execute 'grant select on public.arts_culture_events_discovery_v1 to authenticated';

  execute 'grant select on public.events_discovery_v1 to anon';
  execute 'grant select on public.events_discovery_v1 to authenticated';

  execute 'grant select on public.experiences_discovery_v1 to anon';
  execute 'grant select on public.experiences_discovery_v1 to authenticated';

  -- public views
  execute 'grant select on public.providers_public_v1 to anon';
  execute 'grant select on public.providers_public_v1 to authenticated';

  execute 'grant select on public.events_public_v1 to anon';
  execute 'grant select on public.events_public_v1 to authenticated';

  execute 'grant select on public.landmarks_public_v1 to anon';
  execute 'grant select on public.landmarks_public_v1 to authenticated';

  execute 'grant select on public.landmarks_public_kids_v1 to anon';
  execute 'grant select on public.landmarks_public_kids_v1 to authenticated';

  execute 'grant select on public.community_landmarks_kidsafe_v1 to anon';
  execute 'grant select on public.community_landmarks_kidsafe_v1 to authenticated';

end $$;

commit;