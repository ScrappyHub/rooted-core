begin;

-- =========================================================
-- PROVIDER GATES (v1)
-- Canonical helpers for dashboards + procurement + analytics
-- =========================================================

create or replace function public.is_admin_v1()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.user_tiers ut
    where ut.user_id = auth.uid()
      and ut.role = 'admin'
  );
$$;

revoke all on function public.is_admin_v1() from anon;
grant execute on function public.is_admin_v1() to authenticated;
grant execute on function public.is_admin_v1() to service_role;

create or replace function public.provider_tier_v1(p_provider_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v text;
  id_col text;
begin
  -- Identify provider PK column (id vs provider_id)
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='providers' and column_name='id'
  ) then
    id_col := 'id';
  elsif exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='providers' and column_name='provider_id'
  ) then
    id_col := 'provider_id';
  else
    raise notice 'provider_tier_v1: providers has no id/provider_id column; returning free';
    return 'free';
  end if;

  -- Preferred: providers.subscription_tier (if present)
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='providers' and column_name='subscription_tier'
  ) then
    execute format('select p.subscription_tier from public.providers p where p.%I = $1', id_col)
      into v
      using p_provider_id;

    return coalesce(v, 'free');
  end if;

  -- Fallback: derive from user_tiers (owner_user_id -> user_tiers.tier) if available
  if exists (
    select 1 from information_schema.tables
    where table_schema='public' and table_name='user_tiers'
  ) and exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='providers' and column_name='owner_user_id'
  ) and exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='user_tiers' and column_name='user_id'
  ) and exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='user_tiers' and column_name='tier'
  ) then
    execute format(
      'select ut.tier
         from public.providers p
         join public.user_tiers ut on ut.user_id = p.owner_user_id
        where p.%I = $1',
      id_col
    )
    into v
    using p_provider_id;

    return coalesce(v, 'free');
  end if;

  -- Last resort
  return 'free';
end;
$$;

revoke all on function public.provider_tier_v1(uuid) from anon;
grant execute on function public.provider_tier_v1(uuid) to authenticated;
grant execute on function public.provider_tier_v1(uuid) to service_role;

create or replace function public.can_manage_provider_v1(p_provider_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    auth.role() = 'service_role'
    or public.is_admin_v1()
    or exists (
      select 1
      from public.providers p
      where p.id = p_provider_id
        and p.owner_user_id = auth.uid()
    );
$$;

revoke all on function public.can_manage_provider_v1(uuid) from anon;
grant execute on function public.can_manage_provider_v1(uuid) to authenticated;
grant execute on function public.can_manage_provider_v1(uuid) to service_role;

create or replace function public.can_access_provider_analytics_v1(p_provider_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  tier text;
  sub_status text;
begin
  if auth.role() = 'service_role' then
    return true;
  end if;

  if not public.can_manage_provider_v1(p_provider_id) then
    return false;
  end if;

  select p.subscription_tier, p.subscription_status
    into tier, sub_status
  from public.providers p
  where p.id = p_provider_id;

  if tier is null then
    return false;
  end if;

  -- Optional: require active subscription for premium tiers
  if tier in ('premium','premium_plus') and sub_status <> 'active' then
    return false;
  end if;

  return tier in ('premium','premium_plus');
end $$;

revoke all on function public.can_access_provider_analytics_v1(uuid) from anon;
grant execute on function public.can_access_provider_analytics_v1(uuid) to authenticated;
grant execute on function public.can_access_provider_analytics_v1(uuid) to service_role;

create or replace function public.can_access_provider_procurement_v1(p_provider_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  tier text;
  sub_status text;
begin
  if auth.role() = 'service_role' then
    return true;
  end if;

  if not public.can_manage_provider_v1(p_provider_id) then
    return false;
  end if;

  select p.subscription_tier, p.subscription_status
    into tier, sub_status
  from public.providers p
  where p.id = p_provider_id;

  if tier is null then
    return false;
  end if;

  if tier = 'premium_plus' and sub_status = 'active' then
    return true;
  end if;

  return false;
end $$;

revoke all on function public.can_access_provider_procurement_v1(uuid) from anon;
grant execute on function public.can_access_provider_procurement_v1(uuid) to authenticated;
grant execute on function public.can_access_provider_procurement_v1(uuid) to service_role;

commit;