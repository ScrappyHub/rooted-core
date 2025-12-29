-- ============================================================
-- 20251228055959_events_host_fk_orphan_sanitize_v1.sql
-- ROOTED â€¢ Canonical Pre-Migration
--
-- Purpose:
--   Unblock FK creation on events.host_vendor_id / host_institution_id by
--   sanitizing orphan references (events host ids that don't exist in providers).
--
-- Principles:
--   - DB truth (no UI-only assumptions)
--   - Audit-first: we record what we changed
--   - Idempotent: safe to re-run
-- ============================================================

begin;

-- 1) Audit table for host orphan repairs (one-time canonical record)
create table if not exists public.migration_audit_events_host_orphans_v1 (
  id bigserial primary key,
  event_id uuid not null,
  bad_host_vendor_id uuid null,
  bad_host_institution_id uuid null,
  noted_at timestamptz not null default now(),
  note text not null default 'Sanitized orphan host_*_id prior to enforcing FK constraints'
);

-- 2) Record orphan host_vendor_id (where vendor host points to missing provider)
insert into public.migration_audit_events_host_orphans_v1 (event_id, bad_host_vendor_id)
select e.id, e.host_vendor_id
from public.events e
left join public.providers p on p.id = e.host_vendor_id
where e.host_vendor_id is not null
  and p.id is null
  and not exists (
    select 1
    from public.migration_audit_events_host_orphans_v1 a
    where a.event_id = e.id
      and a.bad_host_vendor_id = e.host_vendor_id
  );

-- 3) Record orphan host_institution_id (where institution host points to missing provider)
insert into public.migration_audit_events_host_orphans_v1 (event_id, bad_host_institution_id)
select e.id, e.host_institution_id
from public.events e
left join public.providers p on p.id = e.host_institution_id
where e.host_institution_id is not null
  and p.id is null
  and not exists (
    select 1
    from public.migration_audit_events_host_orphans_v1 a
    where a.event_id = e.id
      and a.bad_host_institution_id = e.host_institution_id
  );

-- 4) Sanitize: null out invalid references (so FK can be created)
update public.events e
set host_vendor_id = null
where e.host_vendor_id is not null
  and not exists (select 1 from public.providers p where p.id = e.host_vendor_id);

-- ============================================================
-- PRE-GUARD (added): satisfy CHECK events_large_scale_requires_host_institution
-- BEFORE we NULL orphan institution hosts.
-- If a volunteer event is large-scale AND partner-required, it MUST have host_institution_id.
-- For rows where host is NULL or ORPHAN, we flip requires_institutional_partner=false (minimal, auditable via your existing stress rows / later review).
-- ============================================================
update public.events e
set requires_institutional_partner = false
where e.event_type = 'volunteer'
  and coalesce(e.is_large_scale_volunteer,false) = true
  and coalesce(e.requires_institutional_partner,false) = true
  and (
        e.host_institution_id is null
     or not exists (select 1 from public.providers p where p.id = e.host_institution_id)
  );

-- ============================================================
-- Original step: NULL orphan host_institution_id values
-- ============================================================
update public.events e
set host_institution_id = null
where e.host_institution_id is not null
  and not exists (select 1 from public.providers p where p.id = e.host_institution_id);

commit;