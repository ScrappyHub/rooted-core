-- 20251216221500_events_host_vendor_gates_v1.sql
-- Purpose:
--   Harden vendor-hosted event INSERT/UPDATE/DELETE when events has host_vendor_id.
--   No INSERT USING (Postgres restriction). Use WITH CHECK for INSERT.
--   Enforce: ownership, created_by, vertical match, verified gating, publish requires approved.

begin;

alter table public.events enable row level security;

-- Safety: do not collide with existing policy names
-- We will create *new* policies with _v5 suffix.

-- Helper: is this user the owner of the host vendor?
create or replace function public._owns_host_vendor(p_vendor_id uuid)
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1
    from public.providers p
    where p.id = p_vendor_id
      and p.owner_user_id = auth.uid()
  );
$$;

create or replace function public._owns_verified_host_vendor(p_vendor_id uuid)
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1
    from public.providers p
    where p.id = p_vendor_id
      and p.owner_user_id = auth.uid()
      and coalesce(p.is_verified,false) = true
  );
$$;

-- Helper: does event_vertical match provider vertical?
create or replace function public._event_vertical_matches_vendor(p_vendor_id uuid, p_event_vertical text)
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1
    from public.providers p
    where p.id = p_vendor_id
      and p_event_vertical = coalesce(p.primary_vertical, p.vertical)
  );
$$;

-- ---------------------------------------------------------------------
-- INSERT (vendor-hosted only)
-- ---------------------------------------------------------------------
drop policy if exists events_host_vendor_insert_v5 on public.events;

create policy events_host_vendor_insert_v5
on public.events
for insert
with check (
  -- must be vendor-hosted (we are not allowing institution-hosted via user auth yet)
  host_vendor_id is not null
  and host_institution_id is null

  -- anti-spoof
  and created_by = auth.uid()

  -- ownership + vertical match
  and public._owns_host_vendor(host_vendor_id)
  and public._event_vertical_matches_vendor(host_vendor_id, event_vertical)

  -- gating:
  and (
    -- unverified vendors: draft only
    (not public._owns_verified_host_vendor(host_vendor_id) and coalesce(status,'') = 'draft')
    or
    -- verified vendors: can create non-published, or published only if approved
    (public._owns_verified_host_vendor(host_vendor_id)
      and (
        coalesce(status,'') <> 'published'
        or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
      )
    )
  )
);

-- ---------------------------------------------------------------------
-- UPDATE (vendor-hosted only)
-- ---------------------------------------------------------------------
drop policy if exists events_host_vendor_update_v5 on public.events;

create policy events_host_vendor_update_v5
on public.events
for update
using (
  -- you can only touch your own vendor-hosted events
  created_by = auth.uid()
  and host_vendor_id is not null
  and host_institution_id is null
  and public._owns_host_vendor(host_vendor_id)
)
with check (
  created_by = auth.uid()
  and host_vendor_id is not null
  and host_institution_id is null

  and public._owns_host_vendor(host_vendor_id)
  and public._event_vertical_matches_vendor(host_vendor_id, event_vertical)

  and (
    (not public._owns_verified_host_vendor(host_vendor_id) and coalesce(status,'') = 'draft')
    or
    (public._owns_verified_host_vendor(host_vendor_id)
      and (
        coalesce(status,'') <> 'published'
        or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
      )
    )
  )
);

-- ---------------------------------------------------------------------
-- DELETE (vendor-hosted only)
-- ---------------------------------------------------------------------
drop policy if exists events_host_vendor_delete_v5 on public.events;

create policy events_host_vendor_delete_v5
on public.events
for delete
using (
  created_by = auth.uid()
  and host_vendor_id is not null
  and host_institution_id is null
  and public._owns_host_vendor(host_vendor_id)
);

commit;
