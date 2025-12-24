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

create view public.provider_dashboard_summary_v1 as
select
  p.id as provider_id,
  p.name,
  p.vertical,
  p.specialty,
  p.subscription_tier,
  p.subscription_status,
  p.is_verified,
  p.is_active,
  p.kids_mode_safe,

  -- Live feed count (approved)
  (
    select count(*)
    from public.live_feed_posts l
    where l.provider_id = p.id
      and l.status = 'approved'
  ) as approved_live_feed_posts,

  -- Events hosted by this provider
  (
    select count(*)
    from public.events e
    where e.host_vendor_id = p.id
       or e.host_institution_id = p.id
  ) as events_total,

  -- Events hosted and published+approved (public surface)
  (
    select count(*)
    from public.events e
    where (e.host_vendor_id = p.id or e.host_institution_id = p.id)
      and e.status = 'published'
      and e.moderation_status = 'approved'
  ) as events_published_approved_total,

  -- Volunteer events hosted
  (
    select count(*)
    from public.events e
    where (e.host_vendor_id = p.id or e.host_institution_id = p.id)
      and coalesce(e.is_volunteer,false) = true
  ) as volunteer_events_total,

  -- Registrations into this provider's hosted events
  (
    select count(*)
    from public.event_registrations er
    join public.events e on e.id = er.event_id
    where (e.host_vendor_id = p.id or e.host_institution_id = p.id)
  ) as registrations_total,

  -- Bulk offers (known FK)
  (
    select count(*)
    from public.bulk_offers bo
    where bo.provider_id = p.id
  ) as bulk_offers_total

from public.providers p
where public.can_manage_provider_v1(p.id) = true;

revoke all on table public.provider_dashboard_summary_v1 from anon;
revoke all on table public.provider_dashboard_summary_v1 from authenticated;
grant select on table public.provider_dashboard_summary_v1 to authenticated;
grant select on table public.provider_dashboard_summary_v1 to service_role;

commit;