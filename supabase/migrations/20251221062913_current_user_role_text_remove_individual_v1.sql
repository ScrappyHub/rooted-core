begin;

-- =========================================================
-- CURRENT USER ROLE ALIGNMENT (v1) â€” CANONICAL
-- Fixes: public.current_user_role_text()
-- - Removes forbidden role "individual"
-- - Aligns with user_tiers_role_check:
--     role IN ('vendor','institution','community','admin')
-- - Returns:
--     * 'guest' when auth.uid() is null
--     * 'community' when authenticated but no role row found
-- =========================================================

create or replace function public.current_user_role_text()
returns text
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $function$
declare
  v_role text := null;
  v_has_user_tiers boolean := (to_regclass('public.user_tiers') is not null);
begin
  -- Unauthenticated
  if auth.uid() is null then
    return 'guest';
  end if;

  -- If user_tiers exists, try to resolve role from user_id column (canonical)
  if v_has_user_tiers then
    if exists (
      select 1
      from information_schema.columns
      where table_schema='public'
        and table_name='user_tiers'
        and column_name='user_id'
    )
    and exists (
      select 1
      from information_schema.columns
      where table_schema='public'
        and table_name='user_tiers'
        and column_name='role'
    ) then
      select ut.role
        into v_role
      from public.user_tiers ut
      where ut.user_id = auth.uid()
      limit 1;

      -- Hard clamp to allowed role set
      if v_role in ('vendor','institution','community','admin') then
        return v_role;
      end if;
    end if;
  end if;

  -- Authenticated fallback (non-privileged)
  return 'community';
end;
$function$;

revoke all on function public.current_user_role_text() from anon;
revoke all on function public.current_user_role_text() from authenticated;
grant execute on function public.current_user_role_text() to authenticated;
grant execute on function public.current_user_role_text() to service_role;

comment on function public.current_user_role_text()
is 'Canonical role text: guest when unauth; else role from user_tiers.user_id; never returns individual; defaults to community.';

commit;