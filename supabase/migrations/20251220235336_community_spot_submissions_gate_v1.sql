begin;

-- =========================================================
-- COMMUNITY SPOT SUBMISSIONS GATE (v1)
-- Insert allowed ONLY if:
--   - role in ('vendor','institution') OR
--   - user has >= 5 approved volunteer registrations
-- Submissions go to moderation (pending by default).
-- =========================================================

create table if not exists public.community_spot_submissions (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null,
  title text not null,
  description text null,
  spot_type text not null,
  latitude double precision not null,
  longitude double precision not null,
  season_tags text[] not null default '{}',
  status text not null default 'pending',
  reviewed_by uuid null,
  reviewed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.community_spot_submissions enable row level security;
alter table public.community_spot_submissions force row level security;

create or replace function public._approved_volunteer_count(p_user uuid)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select count(*)::int
  from public.event_registrations r
  join public.events e on e.id = r.event_id
  where r.user_id = p_user
    and coalesce(e.is_volunteer,false) = true
    and coalesce(r.status,'') in ('approved','confirmed','attended')
$$;

revoke all on function public._approved_volunteer_count(uuid) from anon;
revoke all on function public._approved_volunteer_count(uuid) from authenticated;
grant execute on function public._approved_volunteer_count(uuid) to service_role;

create or replace function public.can_submit_community_spots()
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  u uuid := auth.uid();
  c int;
  role_text text;
begin
  if u is null then
    return false;
  end if;

  select ut.role into role_text
  from public.user_tiers ut
  where ut.user_id = u;

  if role_text in ('vendor','institution') then
    return true;
  end if;

  c := public._approved_volunteer_count(u);
  if c >= 5 then
    return true;
  end if;

  return false;
end $$;

revoke all on function public.can_submit_community_spots() from anon;
grant execute on function public.can_submit_community_spots() to authenticated;

drop policy if exists community_spot_submissions_insert_v1 on public.community_spot_submissions;
create policy community_spot_submissions_insert_v1
on public.community_spot_submissions
for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.can_submit_community_spots() = true
);

drop policy if exists community_spot_submissions_select_own_v1 on public.community_spot_submissions;
create policy community_spot_submissions_select_own_v1
on public.community_spot_submissions
for select
to authenticated
using (created_by = auth.uid());

drop policy if exists community_spot_submissions_update_own_pending_v1 on public.community_spot_submissions;
create policy community_spot_submissions_update_own_pending_v1
on public.community_spot_submissions
for update
to authenticated
using (created_by = auth.uid() and status = 'pending')
with check (created_by = auth.uid() and status = 'pending');

drop policy if exists community_spot_submissions_service_manage_v1 on public.community_spot_submissions;
create policy community_spot_submissions_service_manage_v1
on public.community_spot_submissions
for all
to service_role
using (true)
with check (true);

commit;