begin;

-- =========================================================
-- AUTHENTICATED SELECT: ALLOWLIST ONLY (v1)
-- Policy:
--   - authenticated gets NO SELECT on any public base table by default
--   - authenticated gets SELECT only on:
--       (A) the 12 public discovery views
--       (B) the 10 authenticated write tables (so app flows still work under RLS)
-- Notes:
--   - Does NOT change anon grants (your anon 12-view allowlist stays as-is)
--   - RLS remains authority for row-level access
-- =========================================================

do $$
declare
  r record;
begin
  -- Revoke SELECT from authenticated on ALL base relations in public (tables only)
  for r in
    select c.oid::regclass as obj
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public'
      and c.relkind in ('r','p','f')  -- tables, partitioned tables, foreign tables
  loop
    execute format('revoke select on %s from authenticated', r.obj);
  end loop;
end $$;

-- (A) Re-grant SELECT on the 12 public discovery views
grant select on public.arts_culture_events_discovery_v1      to authenticated;
grant select on public.arts_culture_providers_discovery_v1   to authenticated;
grant select on public.community_landmarks_kidsafe_v1        to authenticated;
grant select on public.community_providers_discovery_v1      to authenticated;
grant select on public.education_providers_discovery_v1      to authenticated;
grant select on public.events_discovery_v1                   to authenticated;
grant select on public.events_public_v1                      to authenticated;
grant select on public.experiences_discovery_v1              to authenticated;
grant select on public.landmarks_public_kids_v1              to authenticated;
grant select on public.landmarks_public_v1                   to authenticated;
grant select on public.providers_discovery_v1                to authenticated;
grant select on public.providers_public_v1                   to authenticated;

-- (B) Re-grant SELECT on the authenticated write surface tables (RLS governs rows)
grant select on public.account_deletion_requests             to authenticated;
grant select on public.conversation_participants             to authenticated;
grant select on public.conversations                         to authenticated;
grant select on public.event_registrations                   to authenticated;
grant select on public.experience_requests                   to authenticated;
grant select on public.institution_applications              to authenticated;
grant select on public.messages                              to authenticated;
grant select on public.user_consents                         to authenticated;
grant select on public.user_devices                          to authenticated;
grant select on public.vendor_applications                   to authenticated;

commit;