begin;

-- =========================================================
-- SAFETY ASSERTS
-- =========================================================
do $$
begin
  if to_regclass('public.events') is null then
    raise exception 'events_policy_normalization_v7_only_plus_institutions_v1: public.events missing';
  end if;

  if to_regclass('public.user_tiers') is null then
    raise exception 'events_policy_normalization_v7_only_plus_institutions_v1: public.user_tiers missing';
  end if;

  if not (select relrowsecurity from pg_class where oid = 'public.events'::regclass) then
    raise exception 'events_policy_normalization_v7_only_plus_institutions_v1: RLS is OFF on public.events';
  end if;
end $$;

-- =========================================================
-- DROP BYPASS / ALT PATH POLICIES
-- =========================================================
drop policy if exists events_host_insert_v4 on public.events;

-- These bypass V7 checks (permissive OR): remove them
drop policy if exists events_update_owner_v1 on public.events;
drop policy if exists events_delete_owner_v1 on public.events;

-- Keep: events_admin_all_access, events_service_role_manage_v1
-- Keep: events_read_published_approved_v1
-- Keep: events_host_vendor_*_v7

-- =========================================================
-- INSTITUTIONS: STRICT HOST POLICIES
--   - allows institutions to create/manage events they host
--   - does NOT bypass moderation rules
-- =========================================================

create policy events_host_institution_insert_v1
on public.events
for insert
to authenticated
with check (
  created_by = auth.uid()
  and host_institution_id is not null
  and exists (
    select 1
    from public.user_tiers ut
    where ut.user_id = auth.uid()
      and ut.role = 'institution'
      and ut.account_status = 'active'
  )
  -- published requires approval (same pattern as elsewhere)
  and (
    coalesce(status,'') <> 'published'
    or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
  )
);

create policy events_host_institution_update_v1
on public.events
for update
to authenticated
using (
  created_by = auth.uid()
  and host_institution_id is not null
  and exists (
    select 1
    from public.user_tiers ut
    where ut.user_id = auth.uid()
      and ut.role = 'institution'
      and ut.account_status = 'active'
  )
)
with check (
  created_by = auth.uid()
  and host_institution_id is not null
  and exists (
    select 1
    from public.user_tiers ut
    where ut.user_id = auth.uid()
      and ut.role = 'institution'
      and ut.account_status = 'active'
  )
  and (
    coalesce(status,'') <> 'published'
    or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
  )
);

create policy events_host_institution_delete_v1
on public.events
for delete
to authenticated
using (
  created_by = auth.uid()
  and host_institution_id is not null
  and exists (
    select 1
    from public.user_tiers ut
    where ut.user_id = auth.uid()
      and ut.role = 'institution'
      and ut.account_status = 'active'
  )
);

commit;