-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- AUTHENTICATED WRITE SURFACE: ALLOWLIST ONLY (v1)
-- Revoke INSERT/UPDATE/DELETE from authenticated everywhere in public,
-- then re-grant ONLY to the allowlisted write tables.
-- RLS remains the authority.
-- =========================================================

do $$
declare
  r record;
begin
  -- Revoke ALL write privileges from authenticated on all relations in public
  for r in
    select c.oid::regclass as obj
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname='public'
      and c.relkind in ('r','p','f') -- tables, partitioned tables, foreign tables
  loop
    execute format('revoke insert, update, delete on %s from authenticated', r.obj);
  end loop;
end;
$$;

-- Re-grant authenticated writes ONLY on the allowlist
grant insert, update, delete on public.account_deletion_requests   to authenticated;
grant insert, update, delete on public.event_registrations         to authenticated;
grant insert, update, delete on public.institution_applications    to authenticated;
grant insert, update, delete on public.vendor_applications         to authenticated;

grant insert, update              on public.experience_requests     to authenticated;

grant insert, update, delete      on public.user_consents           to authenticated;
grant insert, update, delete      on public.user_devices            to authenticated;

grant insert                      on public.conversations           to authenticated;
grant insert                      on public.conversation_participants to authenticated;
grant insert                      on public.messages                to authenticated;

commit;