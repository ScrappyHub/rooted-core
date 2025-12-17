-- 20251216235000_events_host_vendor_specialty_not_blank_patch_v1.sql
-- Patch: require provider.specialty to be non-null/non-blank for vendor-hosted event write policies.

begin;

-- Drop the v7 policies (safe if they exist / re-run)
drop policy if exists events_host_vendor_insert_v7 on public.events;
drop policy if exists events_host_vendor_update_v7 on public.events;
drop policy if exists events_host_vendor_delete_v7 on public.events;

-- Recreate v7 INSERT with specialty not blank guard
create policy events_host_vendor_insert_v7
on public.events
for insert
to authenticated
with check (
  created_by = auth.uid()
  and host_vendor_id is not null
  and exists (
    select 1
    from public.providers p
    where p.id = host_vendor_id
      and p.owner_user_id = auth.uid()
      and event_vertical = coalesce(p.primary_vertical, p.vertical)
      and nullif(btrim(p.specialty), '') is not null
      -- Sanctuary hard lock: volunteer only
      and (
        not public._is_sanctuary_specialty(p.specialty)
        or coalesce(is_volunteer,false) = true
      )
      -- Capability lock: sanctuary explicitly denies non-volunteer
      and (
        (coalesce(is_volunteer,false) = true  and public._specialty_capability_allowed(p.specialty,'EVENT_VOLUNTEER'))
        or
        (coalesce(is_volunteer,false) = false and public._specialty_capability_allowed(p.specialty,'EVENT_NON_VOLUNTEER'))
      )
  )
  and (
    coalesce(status,'') <> 'published'
    or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
  )
);

-- Recreate v7 UPDATE with specialty not blank guard
create policy events_host_vendor_update_v7
on public.events
for update
to authenticated
using (
  created_by = auth.uid()
  and host_vendor_id is not null
  and exists (
    select 1
    from public.providers p
    where p.id = host_vendor_id
      and p.owner_user_id = auth.uid()
  )
)
with check (
  created_by = auth.uid()
  and host_vendor_id is not null
  and exists (
    select 1
    from public.providers p
    where p.id = host_vendor_id
      and p.owner_user_id = auth.uid()
      and event_vertical = coalesce(p.primary_vertical, p.vertical)
      and nullif(btrim(p.specialty), '') is not null
      and (
        not public._is_sanctuary_specialty(p.specialty)
        or coalesce(is_volunteer,false) = true
      )
      and (
        (coalesce(is_volunteer,false) = true  and public._specialty_capability_allowed(p.specialty,'EVENT_VOLUNTEER'))
        or
        (coalesce(is_volunteer,false) = false and public._specialty_capability_allowed(p.specialty,'EVENT_NON_VOLUNTEER'))
      )
  )
  and (
    coalesce(status,'') <> 'published'
    or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
  )
);

-- Recreate v7 DELETE (ownership-only; keep tight)
create policy events_host_vendor_delete_v7
on public.events
for delete
to authenticated
using (
  created_by = auth.uid()
  and host_vendor_id is not null
  and exists (
    select 1
    from public.providers p
    where p.id = host_vendor_id
      and p.owner_user_id = auth.uid()
      and nullif(btrim(p.specialty), '') is not null
  )
);

commit;
