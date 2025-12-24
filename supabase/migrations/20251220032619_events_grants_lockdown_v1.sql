begin;

-- =========================================================
-- SAFETY ASSERTS
-- =========================================================
do $$
begin
  if to_regclass('public.events') is null then
    raise exception 'events_grants_lockdown_v1: public.events missing';
  end if;

  if not (select relrowsecurity from pg_class where oid = 'public.events'::regclass) then
    raise exception 'events_grants_lockdown_v1: RLS is OFF on public.events';
  end if;
end $$;

-- =========================================================
-- GRANTS LOCKDOWN (least privilege)
-- =========================================================

-- 1) Anon: read-only (RLS still controls which rows)
revoke all on table public.events from anon;
grant select on table public.events to anon;

-- 2) Authenticated: allow CRUD via RLS policies
revoke all on table public.events from authenticated;
grant select, insert, update, delete on table public.events to authenticated;

-- 3) Service role: full access (as before)
-- (Usually already present, but we make it explicit/auditable)
grant all on table public.events to service_role;

commit;