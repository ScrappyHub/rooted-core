-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: ENFORCE-DO-CLOSE-DELIMITER-STEP-1S (canonical)
-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
-- ============================================================
-- 20251228060000_events_host_and_collaborators_v1.sql
-- ROOTED ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ Canonical Migration
-- Purpose:
--   1) Enforce exactly-one host per event (DB truth, not UI)
--   2) Enforce host role correctness (vendor vs institution)
--   3) Add event_collaborators for partners/sponsors/cohosts/etc
--   4) Add audit-first RLS policies (no UI-only checks)
-- ============================================================

begin;

-- ============================================================
-- 0) Canonical normalization: keep codes consistent with provider normalization
-- ============================================================
do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema='public'
      and table_name='vertical_canonical_specialties'
  ) then
    update public.vertical_canonical_specialties
      set vertical_code  = upper(vertical_code),
          specialty_code = upper(specialty_code)
    where vertical_code  <> upper(vertical_code)
       or specialty_code <> upper(specialty_code);
  end if;
end;
$$;

create or replace function public.vertical_canonical_specialties_normalize_v1()
returns trigger
language plpgsql
as $$
begin
  if new.vertical_code is not null then new.vertical_code := upper(new.vertical_code); end if;
  if new.specialty_code is not null then new.specialty_code := upper(new.specialty_code); end if;
  return new;
end;

drop trigger if exists trg_vertical_canonical_specialties_normalize_v1 on public.vertical_canonical_specialties;

create trigger trg_vertical_canonical_specialties_normalize_v1
before insert or update of vertical_code, specialty_code
on public.vertical_canonical_specialties
for each row
execute function public.vertical_canonical_specialties_normalize_v1();

-- ============================================================
-- 1) Ensure BOTH event host FKs exist
-- ============================================================
do $$
begin
  if not exists (select 1 from pg_constraint where conname='events_host_vendor_fkey') then
    alter table public.events
      add constraint events_host_vendor_fkey
      foreign key (host_vendor_id)
      references public.providers(id)
      on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname='events_host_institution_fkey') then
    alter table public.events
      add constraint events_host_institution_fkey
      foreign key (host_institution_id)
      references public.providers(id)
      on delete set null;
  end if;
end;
$$;

-- ============================================================
-- 2) Host correctness CHECK (NOT VALID first to avoid legacy rows blocking deploy)
-- ============================================================
do $$
begin
  if not exists (select 1 from pg_constraint where conname='events_exactly_one_host_chk') then
    alter table public.events
      add constraint events_exactly_one_host_chk
      check (
        (host_vendor_id is not null)::int +
        (host_institution_id is not null)::int = 1
      )
      not valid;
  end if;
end;
$$;

-- ============================================================
-- 3) Core correctness trigger: host required + role correctness
-- ============================================================
create or replace function public.enforce_event_host_roles_v1()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  vendor_owner uuid;
  institution_owner uuid;
  vendor_role text;
  institution_role text;
begin
  -- Must have exactly one host on any write
  if new.host_vendor_id is null and new.host_institution_id is null then
    raise exception 'Event must have a host: set host_vendor_id OR host_institution_id';
  end if;

  if new.host_vendor_id is not null and new.host_institution_id is not null then
    raise exception 'Only one host type allowed: host_vendor_id OR host_institution_id';
  end if;

  -- vendor host must be provider owned by role='vendor'
  if new.host_vendor_id is not null then
    select p.owner_user_id into vendor_owner
    from public.providers p
    where p.id = new.host_vendor_id;

    if vendor_owner is null then
      raise exception 'Invalid host_vendor_id (provider missing)';
    end if;

    select ut.role into vendor_role
    from public.user_tiers ut
    where ut.user_id = vendor_owner;

    if vendor_role is distinct from 'vendor' then
      raise exception 'host_vendor_id must reference a provider owned by a vendor account';
    end if;
  end if;

  -- institution host must be provider owned by role='institution'
  if new.host_institution_id is not null then
    select p.owner_user_id into institution_owner
    from public.providers p
    where p.id = new.host_institution_id;

    if institution_owner is null then
      raise exception 'Invalid host_institution_id (provider missing)';
    end if;

    select ut.role into institution_role
    from public.user_tiers ut
    where ut.user_id = institution_owner;

    if institution_role is distinct from 'institution' then
      raise exception 'host_institution_id must reference a provider owned by an institution account';
    end if;
  end if;

  return new;
end;

drop trigger if exists trg_enforce_event_host_roles_v1 on public.events;

create trigger trg_enforce_event_host_roles_v1
before insert or update of host_vendor_id, host_institution_id
on public.events
for each row
execute function public.enforce_event_host_roles_v1();

-- ============================================================
-- 4) NEW: event_collaborators (partners/sponsors/cohosts/etc)
-- ============================================================
create table if not exists public.event_collaborators (
  id uuid primary key default gen_random_uuid(),

  event_id uuid not null references public.events(id) on delete cascade,
  provider_id uuid not null references public.providers(id) on delete cascade,

  collab_type text not null,
  is_public boolean not null default true,

  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  note text null,

  constraint event_collaborators_collab_type_chk
    check (collab_type = any (array[
      'partner','sponsor','cohost','vendor_booth','speaker','hosted_by'
    ])),

  constraint event_collaborators_unique
    unique (event_id, provider_id, collab_type)
);

do $$
begin
  if exists (select 1 from pg_proc where proname='set_updated_at') then
    drop trigger if exists trg_event_collaborators_updated_at on public.event_collaborators;
    create trigger trg_event_collaborators_updated_at
    before update on public.event_collaborators
    for each row
    execute function public.set_updated_at();
  end if;
end;
$$;

-- ============================================================
-- 5) RLS helpers (audit-first)
-- ============================================================
alter table public.event_collaborators enable row level security;

create or replace function public.is_admin_v1(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.user_tiers ut
    where ut.user_id = p_user_id
      and ut.role = 'admin'
      and ut.account_status = 'active'
  );

create or replace function public.is_event_host_owner_v1(p_event_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.events e
    left join public.providers pv on pv.id = e.host_vendor_id
    left join public.providers pi on pi.id = e.host_institution_id
    where e.id = p_event_id
      and (pv.owner_user_id = p_user_id or pi.owner_user_id = p_user_id)
  );

create or replace function public.is_provider_owner_v1(p_provider_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.providers p
    where p.id = p_provider_id
      and p.owner_user_id = p_user_id
  );

-- EXECUTE hardening (do not leave SECURITY DEFINER funcs callable by PUBLIC)
revoke all on function public.is_admin_v1(uuid) from public;
grant execute on function public.is_admin_v1(uuid) to authenticated;

revoke all on function public.is_event_host_owner_v1(uuid, uuid) from public;
grant execute on function public.is_event_host_owner_v1(uuid, uuid) to authenticated;

revoke all on function public.is_provider_owner_v1(uuid, uuid) from public;
grant execute on function public.is_provider_owner_v1(uuid, uuid) to authenticated;

-- ============================================================
-- 6) RLS policies (no UI-only checks)
-- ============================================================
drop policy if exists event_collaborators_read_v1 on public.event_collaborators;
create policy event_collaborators_read_v1
on public.event_collaborators
for select
to authenticated
using (
  public.is_admin_v1(auth.uid())
  or public.is_event_host_owner_v1(event_id, auth.uid())
  or public.is_provider_owner_v1(provider_id, auth.uid())
  or (
    is_public = true
    and exists (
      select 1
      from public.events e
      where e.id = event_id
        and e.status = 'published'
        and e.moderation_status = 'approved'
    )
  )
);

drop policy if exists event_collaborators_insert_v1 on public.event_collaborators;
create policy event_collaborators_insert_v1
on public.event_collaborators
for insert
to authenticated
with check (
  (public.is_admin_v1(auth.uid()) or public.is_event_host_owner_v1(event_id, auth.uid()))
  and created_by = auth.uid()
);

drop policy if exists event_collaborators_update_v1 on public.event_collaborators;
create policy event_collaborators_update_v1
on public.event_collaborators
for update
to authenticated
using (
  public.is_admin_v1(auth.uid()) or public.is_event_host_owner_v1(event_id, auth.uid())
)
with check (
  public.is_admin_v1(auth.uid()) or public.is_event_host_owner_v1(event_id, auth.uid())
);

drop policy if exists event_collaborators_delete_v1 on public.event_collaborators;
create policy event_collaborators_delete_v1
on public.event_collaborators
for delete
to authenticated
using (
  public.is_admin_v1(auth.uid()) or public.is_event_host_owner_v1(event_id, auth.uid())
);

-- ============================================================
-- 7) Best-effort legacy cleanup + validate CHECK
--    - If there are hostless legacy rows AND a creator owns exactly one provider,
--      auto-assign host based on their role (vendor vs institution).
-- ============================================================
with candidates as (
  select
    e.id as event_id,
    e.created_by,
    ut.role,
    p.id as provider_id,
    count(*) over (partition by e.id) as owned_provider_ct
  from public.events e
  join public.user_tiers ut on ut.user_id = e.created_by
  join public.providers p on p.owner_user_id = e.created_by
  where (e.host_vendor_id is null and e.host_institution_id is null)
)
update public.events e
set
  host_vendor_id      = case when c.role='vendor'      then c.provider_id else e.host_vendor_id end,
  host_institution_id = case when c.role='institution' then c.provider_id else e.host_institution_id end
from candidates c
where e.id = c.event_id
  and c.owned_provider_ct = 1;

-- Validate once constraints are satisfiable
do $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname='events_exactly_one_host_chk'
  ) then
    -- If violations still exist, VALIDATE will throw (correct behavior).
    alter table public.events
      validate constraint events_exactly_one_host_chk;
  end if;
end;
$$;

commit;