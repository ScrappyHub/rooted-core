-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
begin;

-- =========================================================
-- COMMUNITY SPOTS PUBLISH PIPELINE (v2)
-- - Fixes invalid "ADD CONSTRAINT IF NOT EXISTS" syntax
-- - Uses pg_constraint existence checks
-- =========================================================

-- 0) tighten submissions constraints (idempotent)
do $$
begin
  if to_regclass('public.community_spot_submissions') is not null then

    if not exists (
      select 1 from pg_constraint
      where conname = 'community_spot_submissions_lat_range_v1'
        and conrelid = 'public.community_spot_submissions'::regclass
    ) then
      alter table public.community_spot_submissions
        add constraint community_spot_submissions_lat_range_v1
        check (latitude between -90 and 90);
    end if;

    if not exists (
      select 1 from pg_constraint
      where conname = 'community_spot_submissions_lon_range_v1'
        and conrelid = 'public.community_spot_submissions'::regclass
    ) then
      alter table public.community_spot_submissions
        add constraint community_spot_submissions_lon_range_v1
        check (longitude between -180 and 180);
    end if;

    if not exists (
      select 1 from pg_constraint
      where conname = 'community_spot_submissions_status_check_v1'
        and conrelid = 'public.community_spot_submissions'::regclass
    ) then
      alter table public.community_spot_submissions
        add constraint community_spot_submissions_status_check_v1
        check (status in ('pending','approved','rejected'));
    end if;

  end if;
end;
$$;

-- 1) published table (create w/ columns first; add constraints after for idempotency)
create table if not exists public.community_spots (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid unique null,
  created_by uuid not null,

  title text not null,
  description text null,
  spot_type text not null,

  latitude double precision not null,
  longitude double precision not null,

  season_tags text[] not null default '{}',

  status text not null default 'approved',
  approved_by uuid null,
  approved_at timestamptz null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
begin
  if to_regclass('public.community_spots') is not null then

    if not exists (
      select 1 from pg_constraint
      where conname = 'community_spots_lat_range_v1'
        and conrelid = 'public.community_spots'::regclass
    ) then
      alter table public.community_spots
        add constraint community_spots_lat_range_v1
        check (latitude between -90 and 90);
    end if;

    if not exists (
      select 1 from pg_constraint
      where conname = 'community_spots_lon_range_v1'
        and conrelid = 'public.community_spots'::regclass
    ) then
      alter table public.community_spots
        add constraint community_spots_lon_range_v1
        check (longitude between -180 and 180);
    end if;

    if not exists (
      select 1 from pg_constraint
      where conname = 'community_spots_status_check_v1'
        and conrelid = 'public.community_spots'::regclass
    ) then
      alter table public.community_spots
        add constraint community_spots_status_check_v1
        check (status in ('approved','disabled'));
    end if;

  end if;
end;
$$;

alter table public.community_spots enable row level security;
alter table public.community_spots force row level security;

-- 2) updated_at triggers
create or replace function public._touch_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  new.updated_at := now();
  return new;
end $$;

revoke all on function public._touch_updated_at() from anon;
revoke all on function public._touch_updated_at() from authenticated;
grant execute on function public._touch_updated_at() to service_role;

drop trigger if exists trg_touch_community_spot_submissions_updated_at_v1 on public.community_spot_submissions;
create trigger trg_touch_community_spot_submissions_updated_at_v1
before update on public.community_spot_submissions
for each row execute function public._touch_updated_at();

drop trigger if exists trg_touch_community_spots_updated_at_v1 on public.community_spots;
create trigger trg_touch_community_spots_updated_at_v1
before update on public.community_spots
for each row execute function public._touch_updated_at();

-- 3) policies for published table
drop policy if exists community_spots_auth_read_approved_v1 on public.community_spots;
create policy community_spots_auth_read_approved_v1
on public.community_spots
for select
to authenticated
using (status = 'approved');

drop policy if exists community_spots_service_manage_v1 on public.community_spots;
create policy community_spots_service_manage_v1
on public.community_spots
for all
to service_role
using (true)
with check (true);

revoke all on table public.community_spots from anon;
revoke all on table public.community_spots from authenticated;

-- 4) nearby search function (invoker; respects RLS)
-- NOTE: requires geo_haversine_meters + geo_radius_clamp_meters to exist
create or replace function public.community_spots_nearby_v1(
  p_lat double precision,
  p_lon double precision,
  p_radius_m integer default 80467
)
returns table (
  id uuid,
  title text,
  description text,
  spot_type text,
  latitude double precision,
  longitude double precision,
  season_tags text[],
  created_by uuid,
  approved_at timestamptz
)
language sql
stable
as $$
  with params as (
    select
      p_lat as lat,
      p_lon as lon,
      public.geo_radius_clamp_meters(p_radius_m, 80467) as radius_m
  )
  select
    s.id,
    s.title,
    s.description,
    s.spot_type,
    s.latitude,
    s.longitude,
    s.season_tags,
    s.created_by,
    s.approved_at
  from public.community_spots s
  cross join params p
  where s.status = 'approved'
    and public.geo_haversine_meters(p.lat, p.lon, s.latitude, s.longitude) <= p.radius_m
  order by public.geo_haversine_meters(p.lat, p.lon, s.latitude, s.longitude) asc;
$$;

revoke all on function public.community_spots_nearby_v1(double precision,double precision,integer) from anon;
grant execute on function public.community_spots_nearby_v1(double precision,double precision,integer) to authenticated;
grant execute on function public.community_spots_nearby_v1(double precision,double precision,integer) to service_role;

commit;