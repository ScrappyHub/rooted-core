begin;

-- =========================================================
-- LIVE FEED MODERATION HELPERS (v1)
-- - Service-role-only helpers to approve/reject posts
-- - Sets reviewed_by/reviewed_at/approved_at consistently
-- =========================================================

create or replace function public.service_approve_live_feed_post_v1(
  p_post_id uuid,
  p_reviewer uuid default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.role() <> 'service_role' then
    raise exception 'service_approve_live_feed_post_v1: service_role only';
  end if;

  update public.live_feed_posts
  set
    status      = 'approved',
    reviewed_by = coalesce(p_reviewer, reviewed_by),
    reviewed_at = now(),
    approved_at = now()
  where id = p_post_id;
end $$;

revoke all on function public.service_approve_live_feed_post_v1(uuid,uuid) from anon;
revoke all on function public.service_approve_live_feed_post_v1(uuid,uuid) from authenticated;
grant execute on function public.service_approve_live_feed_post_v1(uuid,uuid) to service_role;

create or replace function public.service_reject_live_feed_post_v1(
  p_post_id uuid,
  p_reviewer uuid default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.role() <> 'service_role' then
    raise exception 'service_reject_live_feed_post_v1: service_role only';
  end if;

  update public.live_feed_posts
  set
    status      = 'rejected',
    reviewed_by = coalesce(p_reviewer, reviewed_by),
    reviewed_at = now()
  where id = p_post_id;
end $$;

revoke all on function public.service_reject_live_feed_post_v1(uuid,uuid) from anon;
revoke all on function public.service_reject_live_feed_post_v1(uuid,uuid) from authenticated;
grant execute on function public.service_reject_live_feed_post_v1(uuid,uuid) to service_role;

commit;