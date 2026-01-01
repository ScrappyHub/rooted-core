-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
begin;

-- =========================================================
-- LIVE FEED POSTS (v1)
-- - Posts are moderation-gated (pending -> approved/rejected)
-- - Scope: either provider_id OR community_spot_id (exactly one)
-- - Retention: keep ONLY the 5 most-recent APPROVED posts per scope
-- - No UI-only enforcement; DB enforces.
-- =========================================================

-- 1) Table
create table if not exists public.live_feed_posts (
  id uuid primary key default gen_random_uuid(),

  created_by uuid not null,

  -- exactly one of these must be set
  provider_id uuid null,
  community_spot_id uuid null,

  caption text null,

  -- optional media reference (storage bucket/object path)
  media_bucket_id text null,
  media_object_path text null,

  status text not null default 'pending',
  reviewed_by uuid null,
  reviewed_at timestamptz null,
  approved_at timestamptz null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint live_feed_posts_status_check_v1
    check (status in ('pending','approved','rejected')),

  constraint live_feed_posts_scope_check_v1
    check (
      (provider_id is not null and community_spot_id is null)
      or
      (provider_id is null and community_spot_id is not null)
    )
);

alter table public.live_feed_posts enable row level security;
alter table public.live_feed_posts force row level security;

-- 2) updated_at trigger (reuse your _touch_updated_at if it exists; otherwise create)
do $$
begin
  if to_regprocedure('public._touch_updated_at()') is null then
    create or replace function public._touch_updated_at()
    returns trigger
    language plpgsql
    security definer
    set search_path = public, pg_temp
    as $f$
    begin
      new.updated_at := now();
      return new;
    end;
$$;

    revoke all on function public._touch_updated_at() from anon;
    revoke all on function public._touch_updated_at() from authenticated;
    grant execute on function public._touch_updated_at() to service_role;
  end if;
end $$;

drop trigger if exists trg_touch_live_feed_posts_updated_at_v1 on public.live_feed_posts;
create trigger trg_touch_live_feed_posts_updated_at_v1
before update on public.live_feed_posts
for each row execute function public._touch_updated_at();

-- 3) Gate: can create a post (kept strict + auditable)
-- NOTE: We keep this conservative:
-- - provider feed: allow vendor/institution/admin by role (owner enforcement can be tightened later)
-- - community spot feed: allow individual role
create or replace function public.can_create_live_feed_post_v1(
  p_provider_id uuid,
  p_community_spot_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  u uuid := auth.uid();
  r text;
begin
  if u is null then
    return false;
  end if;

  -- must choose exactly one scope
  if (p_provider_id is null and p_community_spot_id is null)
     or (p_provider_id is not null and p_community_spot_id is not null) then
    return false;
  end if;

  select ut.role into r
  from public.user_tiers ut
  where ut.user_id = u;

  if r is null then
    return false;
  end if;

  -- provider feed: vendor/institution/admin (tighten to provider ownership when you want)
  if p_provider_id is not null then
    if r in ('vendor','institution','admin') then
      return true;
    end if;
    return false;
  end if;

  -- community spot feed: vetted individuals conceptually (we enforce role now; vetted status can be added later)
  if p_community_spot_id is not null then
    if r = 'individual' then
      return true;
    end if;
    return false;
  end if;

  return false;
end $$;

revoke all on function public.can_create_live_feed_post_v1(uuid,uuid) from anon;
grant execute on function public.can_create_live_feed_post_v1(uuid,uuid) to authenticated;
grant execute on function public.can_create_live_feed_post_v1(uuid,uuid) to service_role;

-- 4) Retention enforcement: keep only 5 approved posts per scope.
-- Fires when status becomes approved.
create or replace function public._live_feed_enforce_retention_max5_v1()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- only act when becoming approved
  if (tg_op = 'INSERT' and new.status = 'approved')
     or (tg_op = 'UPDATE' and old.status is distinct from new.status and new.status = 'approved') then

    -- provider scope
    if new.provider_id is not null then
      delete from public.live_feed_posts p
      where p.id in (
        select id
        from public.live_feed_posts
        where provider_id = new.provider_id
          and status = 'approved'
        order by coalesce(approved_at, reviewed_at, updated_at, created_at) desc
        offset 5
      );
    end if;

    -- community spot scope
    if new.community_spot_id is not null then
      delete from public.live_feed_posts p
      where p.id in (
        select id
        from public.live_feed_posts
        where community_spot_id = new.community_spot_id
          and status = 'approved'
        order by coalesce(approved_at, reviewed_at, updated_at, created_at) desc
        offset 5
      );
    end if;
  end if;

  return new;
end $$;

revoke all on function public._live_feed_enforce_retention_max5_v1() from anon;
revoke all on function public._live_feed_enforce_retention_max5_v1() from authenticated;
grant execute on function public._live_feed_enforce_retention_max5_v1() to service_role;

drop trigger if exists trg_live_feed_retention_max5_v1 on public.live_feed_posts;
create trigger trg_live_feed_retention_max5_v1
after insert or update of status on public.live_feed_posts
for each row execute function public._live_feed_enforce_retention_max5_v1();

-- 5) RLS Policies
-- Read: authenticated can read approved posts
drop policy if exists live_feed_posts_read_approved_v1 on public.live_feed_posts;
create policy live_feed_posts_read_approved_v1
on public.live_feed_posts
for select
to authenticated
using (status = 'approved');

-- Insert: creator can insert only pending + must pass gate
drop policy if exists live_feed_posts_insert_pending_v1 on public.live_feed_posts;
create policy live_feed_posts_insert_pending_v1
on public.live_feed_posts
for insert
to authenticated
with check (
  created_by = auth.uid()
  and status = 'pending'
  and public.can_create_live_feed_post_v1(provider_id, community_spot_id) = true
);

-- Update: creator can update only while pending (caption/media edits pre-moderation)
drop policy if exists live_feed_posts_update_own_pending_v1 on public.live_feed_posts;
create policy live_feed_posts_update_own_pending_v1
on public.live_feed_posts
for update
to authenticated
using (created_by = auth.uid() and status = 'pending')
with check (created_by = auth.uid() and status = 'pending');

-- Service: moderation/approval/rejection + ability to set approved_at/review fields
drop policy if exists live_feed_posts_service_manage_v1 on public.live_feed_posts;
create policy live_feed_posts_service_manage_v1
on public.live_feed_posts
for all
to service_role
using (true)
with check (true);

-- Hard revoke baseline table grants (RLS still primary)
revoke all on table public.live_feed_posts from anon;
revoke all on table public.live_feed_posts from authenticated;
grant select, insert, update on table public.live_feed_posts to authenticated;

commit;