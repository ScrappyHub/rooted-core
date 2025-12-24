begin;

-- =========================================================
-- AUTHENTICATED WRITE ALLOWLIST (core flows) (v1)
-- Step A: revoke all INSERT/UPDATE/DELETE from authenticated on ALL public tables/views.
-- Step B: grant back only the minimum client-write surfaces.
-- RLS remains the true enforcement layer.
-- =========================================================

do $$
declare
  r record;
begin
  -- Revoke writes on tables/views/matviews/partitioned/foreign
  for r in
    select c.oid::regclass as obj
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public'
      and c.relkind in ('r','v','m','p','f')
  loop
    execute format('revoke insert, update, delete on %s from authenticated', r.obj);
  end loop;

  -- Revoke writes on sequences too (usually not needed client-side)
  for r in
    select c.oid::regclass as obj
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public'
      and c.relkind='S'
  loop
    execute format('revoke usage, select, update on %s from authenticated', r.obj);
  end loop;
end $$;

-- =========================================================
-- ALLOWLIST: grant back only what authenticated needs
-- =========================================================

-- Messaging core
grant insert on public.conversations to authenticated;
grant insert on public.conversation_participants to authenticated;
grant insert on public.messages to authenticated;

-- Event registrations (user-side)
grant insert, update, delete on public.event_registrations to authenticated;

-- Experience inquiry/requests (user-side)
grant insert, update on public.experience_requests to authenticated;

-- Applications (user-side)
grant insert, update, delete on public.vendor_applications to authenticated;
grant insert, update, delete on public.institution_applications to authenticated;

-- User account actions (user-side)
grant insert, update, delete on public.user_consents to authenticated;
grant insert, update, delete on public.user_devices to authenticated;
grant insert, update, delete on public.account_deletion_requests to authenticated;

commit;