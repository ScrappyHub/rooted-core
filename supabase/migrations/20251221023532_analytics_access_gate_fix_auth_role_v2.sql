begin;

-- =========================================================
-- ANALYTICS ACCESS GATE FIX (v2)
-- - service_role bypass must use JWT role (auth.role())
-- - NOT current_role inside SECURITY DEFINER
-- =========================================================

create or replace function public.can_access_analytics_v1(p_context text default null)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $function$
declare
  u uuid := auth.uid();
  r text;
  t text;
begin
  -- ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ service_role bypass (server-side JWT)
  if auth.role() = 'service_role' then
    return true;
  end if;

  if u is null then
    return false;
  end if;

  select ut.role, ut.tier
    into r, t
  from public.user_tiers ut
  where ut.user_id = u;

  if r is null then
    return false;
  end if;

  if r = 'admin' then
    return true;
  end if;

  if r in ('vendor','institution') and t in ('premium','premium_plus') then
    return true;
  end if;

  return false;
end
$function$;

commit;