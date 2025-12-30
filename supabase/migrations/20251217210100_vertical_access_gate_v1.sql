-- 20251217210100_vertical_access_gate_v1.sql
-- Central â€œengine-firstâ€ access gate: checks vertical_policy.allowed_roles + is_internal_only
-- Safe: does not assume exact user_tiers schema; fails closed if it can't prove role.

begin;

select set_config('rooted.migration_bypass', 'on', true);

-- 1) Resolve current user role safely (falls back to 'individual')
create or replace function public.current_user_role_text()
returns text
language plpgsql
stable
as $$
declare
  v_role text := 'individual';
  v_has_user_tiers boolean := (to_regclass('public.user_tiers') is not null);
begin
  if auth.uid() is null then
    return 'guest';
  end if;

  if v_has_user_tiers then
    -- Prefer user_id
    if exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name='user_tiers' and column_name='user_id'
    ) and exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name='user_tiers' and column_name='role'
    ) then
      select ut.role
      into v_role
      from public.user_tiers ut
      where ut.user_id = auth.uid()
      limit 1;

      return coalesce(v_role, 'individual');
    end if;

    -- Fallback to id
    if exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name='user_tiers' and column_name='id'
    ) and exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name='user_tiers' and column_name='role'
    ) then
      select ut.role
      into v_role
      from public.user_tiers ut
      where ut.id = auth.uid()
      limit 1;

      return coalesce(v_role, 'individual');
    end if;
  end if;

  return 'individual';
end;
$$;

-- 2) Vertical access gate
create or replace function public.vertical_access_allowed(p_vertical_code text)
returns boolean
language plpgsql
stable
as $$
declare
  v_allowed_roles text[];
  v_internal_only boolean;
  v_role text;
begin
  if auth.uid() is null then
    return false;
  end if;

  select vp.allowed_roles, vp.is_internal_only
    into v_allowed_roles, v_internal_only
  from public.vertical_policy vp
  where vp.vertical_code = p_vertical_code;

  if v_allowed_roles is null then
    return false;
  end if;

  v_role := public.current_user_role_text();

  -- Admin always passes
  if v_role = 'admin' then
    return true;
  end if;

  -- Internal-only must be institution/admin (admin already handled)
  if coalesce(v_internal_only,false) and v_role <> 'institution' then
    return false;
  end if;

  return (v_role = any(v_allowed_roles));
end;
$$;

revoke all on function public.vertical_access_allowed(text) from public;
grant execute on function public.vertical_access_allowed(text) to authenticated;

commit;
