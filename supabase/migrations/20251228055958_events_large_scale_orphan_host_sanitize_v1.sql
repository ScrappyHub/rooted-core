-- ============================================================
-- 20251228055958_events_large_scale_orphan_host_sanitize_v1.sql
-- ROOTED • Canonical Pre-Migration (Audit-first)
--
-- Purpose:
--   Satisfy CHECK events_large_scale_requires_host_institution
--   BEFORE we NULL orphan host_institution_id values.
--
-- Remote CHECK:
--   NOT( event_type='volunteer'
--        AND is_large_scale_volunteer=true
--        AND requires_institutional_partner=true
--        AND host_institution_id IS NULL )
--
-- Strategy:
--   For rows where host_institution_id is ORPHAN (missing in providers) AND the CHECK-condition flags are true,
--   set requires_institutional_partner=false (audit first). Then later migration can NULL orphan host ids safely.
--
-- Idempotent. Safe to re-run.
-- ============================================================

begin;

create table if not exists public.migration_audit_events_large_scale_orphan_host_v1 (
  id bigserial primary key,
  event_id uuid not null,
  bad_host_institution_id uuid null,
  prior_is_large_scale_volunteer boolean null,
  prior_requires_institutional_partner boolean null,
  noted_at timestamptz not null default now(),
  note text not null default 'Orphan host_institution_id + flags sanitized to satisfy events_large_scale_requires_host_institution'
);

do \$\$
declare
  has_large boolean;
  has_req   boolean;
begin
  select exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='events' and column_name='is_large_scale_volunteer'
  ) into has_large;

  select exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='events' and column_name='requires_institutional_partner'
  ) into has_req;

  if not has_large or not has_req then
    return;
  end if;

  insert into public.migration_audit_events_large_scale_orphan_host_v1
    (event_id, bad_host_institution_id, prior_is_large_scale_volunteer, prior_requires_institutional_partner)
  select
    e.id,
    e.host_institution_id,
    e.is_large_scale_volunteer,
    e.requires_institutional_partner
  from public.events e
  where e.event_type = 'volunteer'
    and coalesce(e.is_large_scale_volunteer,false) = true
    and coalesce(e.requires_institutional_partner,false) = true
    and e.host_institution_id is not null
    and not exists (select 1 from public.providers p where p.id = e.host_institution_id)
    and not exists (
      select 1
      from public.migration_audit_events_large_scale_orphan_host_v1 a
      where a.event_id = e.id
        and a.bad_host_institution_id = e.host_institution_id
    );

  update public.events e
  set requires_institutional_partner = false
  where e.event_type = 'volunteer'
    and coalesce(e.is_large_scale_volunteer,false) = true
    and coalesce(e.requires_institutional_partner,false) = true
    and e.host_institution_id is not null
    and not exists (select 1 from public.providers p where p.id = e.host_institution_id);

end
\$\$;

commit;