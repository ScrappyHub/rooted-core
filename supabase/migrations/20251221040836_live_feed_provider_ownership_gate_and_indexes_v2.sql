-- ROOTED: AUTO-FIX-EXECUTE-CLOSER-MISMATCH-STEP-1N (canonical)
begin;

-- =========================================================
-- LIVE FEED PROVIDER OWNERSHIP ENFORCEMENT (v2)
-- - Adds supporting indexes
-- - Tightens provider posting to provider ownership IF providers.owner_user_id exists
-- - Does not break if providers schema differs (schema-adaptive)
-- =========================================================

-- 1) Indexes for performance
create index if not exists idx_live_feed_posts_provider_scope_v1
  on public.live_feed_posts (provider_id, status, approved_at desc, created_at desc)
  where provider_id is not null;

create index if not exists idx_live_feed_posts_spot_scope_v1
  on public.live_feed_posts (community_spot_id, status, approved_at desc, created_at desc)
  where community_spot_id is not null;

create index if not exists idx_live_feed_posts_created_by_v1
  on public.live_feed_posts (created_by, status, created_at desc);

-- 2) Tighten gate function (replace)
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
  has_providers boolean := (to_regclass('public.providers') is not null);
  has_owner_col boolean := false;
  is_owner boolean := false;
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

  -- Provider scope
  if p_provider_id is not null then
    -- Admin always allowed
    if r = 'admin' then
      return true;
    end if;

    -- Only vendors/institutions otherwise
    if r not in ('vendor','institution') then
      return false;
    end if;

    -- If providers.owner_user_id exists, enforce ownership
    if has_providers then
      select exists (
        select 1
        from information_schema.columns
        where table_schema='public'
          and table_name='providers'
          and column_name='owner_user_id'
      ) into has_owner_col;

      if has_owner_col then
        execute $q$
          select exists (
            select 1
            from public.providers p
            where p.provider_id = $1
              and p.owner_user_id = $2
          )
        $q$ into is_owner using p_provider_id, u;

        return is_owner;
      end if;
    end if;

    -- Fallback (schema doesn't support ownership column): allow role-based
    return true;
  end if;

  -- Community spot scope: only individuals
  if p_community_spot_id is not null then
    if r = 'individual' then
      return true;
    end if;
    return false;
  end if;

  return false;
$q$;

revoke all on function public.can_create_live_feed_post_v1(uuid,uuid) from anon;
grant execute on function public.can_create_live_feed_post_v1(uuid,uuid) to authenticated;
grant execute on function public.can_create_live_feed_post_v1(uuid,uuid) to service_role;

commit;