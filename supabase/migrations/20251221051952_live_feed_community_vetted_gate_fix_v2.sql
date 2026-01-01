-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
begin;

-- =========================================================
-- USER TIERS AUTO-PROVISION PIPELINE (v2)
-- Fix: Trigger must call a trigger function (no args).
-- =========================================================

-- Helper stays (callable by service_role for backfill / admin jobs)
create or replace function public._ensure_user_tiers_row_v1(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if p_user_id is null then
    return;
  end if;

  if not exists (
    select 1 from public.user_tiers ut where ut.user_id = p_user_id
  ) then
    insert into public.user_tiers (
      user_id,
      role,
      tier,
      feature_flags,
      account_status
    )
    values (
      p_user_id,
      'community',
      'free',
      '{}'::jsonb,
      'active'
    );
  end if;
end;
$$;

revoke all on function public._ensure_user_tiers_row_v1(uuid) from anon;
revoke all on function public._ensure_user_tiers_row_v1(uuid) from authenticated;
grant execute on function public._ensure_user_tiers_row_v1(uuid) to service_role;

-- Trigger wrapper (required)
create or replace function public._trg_auth_users_ensure_user_tiers_v1()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public._ensure_user_tiers_row_v1(new.id);
  return new;
end;
$$;

revoke all on function public._trg_auth_users_ensure_user_tiers_v1() from anon;
revoke all on function public._trg_auth_users_ensure_user_tiers_v1() from authenticated;
grant execute on function public._trg_auth_users_ensure_user_tiers_v1() to service_role;

-- Create trigger
drop trigger if exists trg_auth_users_ensure_user_tiers_v1 on auth.users;

create trigger trg_auth_users_ensure_user_tiers_v1
after insert on auth.users
for each row
execute function public._trg_auth_users_ensure_user_tiers_v1();

-- Backfill (still safe even if auth.users is empty)
do $$
declare r record;
begin
  for r in select id from auth.users
  loop
    perform public._ensure_user_tiers_row_v1(r.id);
  end loop;
end;
$$;

commit;