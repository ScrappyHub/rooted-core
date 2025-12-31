-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

-- =========================================================
-- RLS GUARD: AUTHENTICATED WRITE SURFACE (v1) [BRACKET-FREE]
-- Hard fail if allowlisted authenticated-write tables:
-- - are missing, OR
-- - have RLS disabled, OR
-- - have zero policies.
-- =========================================================

do $$
declare
  t text;
  missing int := 0;
  no_rls int := 0;
  no_policies int := 0;
begin
  for t in
    select v.t
    from (values
      ('account_deletion_requests'),
      ('conversations'),
      ('conversation_participants'),
      ('messages'),
      ('event_registrations'),
      ('experience_requests'),
      ('institution_applications'),
      ('vendor_applications'),
      ('user_consents'),
      ('user_devices')
    ) as v(t)
  loop

    -- missing table?
    if to_regclass('public.' || t) is null then
      missing := missing + 1;
      raise notice 'RLS GUARD: missing table public.%', t;
      continue;
    end if;

    -- rls enabled?
    if not exists (
      select 1
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname='public'
        and c.relname=t
        and c.relrowsecurity=true
    ) then
      no_rls := no_rls + 1;
      raise notice 'RLS GUARD: RLS NOT enabled on public.%', t;
    end if;

    -- at least one policy?
    if not exists (
      select 1
      from pg_policies p
      where p.schemaname='public'
        and p.tablename=t
    ) then
      no_policies := no_policies + 1;
      raise notice 'RLS GUARD: zero policies on public.%', t;
    end if;

  end loop;

  if missing > 0 or no_rls > 0 or no_policies > 0 then
    raise exception 'RLS GUARD FAILED: missing=% no_rls=% no_policies=%', missing, no_rls, no_policies;
  end if;
end;
$$;

commit;