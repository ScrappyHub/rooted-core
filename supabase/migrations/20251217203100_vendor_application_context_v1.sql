-- 20251217203100_vendor_application_context_v1.sql
-- Canonical: One auth user can operate multiple provider entities.
-- Adds: provider_memberships + hard-lock submit/approve functions (no UI trust).
-- Safe: additive, idempotent, avoids guessing existing columns.

begin;

-- Canonical tables are guarded by triggers
select set_config('rooted.migration_bypass', 'on', true);

-- ------------------------------------------------------------
-- 0) Helper: detect ROOTED admin safely
-- ------------------------------------------------------------
create or replace function public.is_rooted_admin()
returns boolean
language plpgsql
stable
as $$
declare
  v_is_admin boolean := false;
begin
  if auth.uid() is null then
    return false;
  end if;

  if to_regclass('public.user_tiers') is null then
    return false;
  end if;

  -- Prefer user_id column if present
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='user_tiers' and column_name='user_id'
  ) then
    select exists(
      select 1 from public.user_tiers ut
      where ut.user_id = auth.uid()
        and ut.role = 'admin'
    ) into v_is_admin;
    return coalesce(v_is_admin,false);
  end if;

  -- Fallback to id column if present
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='user_tiers' and column_name='id'
  ) then
    select exists(
      select 1 from public.user_tiers ut
      where ut.id = auth.uid()
        and ut.role = 'admin'
    ) into v_is_admin;
    return coalesce(v_is_admin,false);
  end if;

  return false;
end;
$$;

-- ------------------------------------------------------------
-- 1) provider_memberships (context switching authority)
-- ------------------------------------------------------------
create table if not exists public.provider_memberships (
  provider_id uuid not null,
  user_id uuid not null,
  membership_role text not null check (membership_role in ('owner','admin','manager','staff','viewer')),
  created_at timestamptz not null default now(),
  primary key (provider_id, user_id)
);

-- ------------------------------------------------------------
-- 2) vendor_applications
-- NOTE: your live schema ALREADY exists and uses user_id.
-- We only add missing pieces and indexes safely.
-- ------------------------------------------------------------

-- Index applicant user (your real column is user_id)
create index if not exists vendor_applications_user_idx
  on public.vendor_applications(user_id);

-- Keep updated_at current (only if updated_at exists)
create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='vendor_applications' and column_name='updated_at'
  )
  and not exists (
    select 1 from pg_trigger
    where tgname = 'trg_vendor_applications_set_updated_at'
  ) then
    create trigger trg_vendor_applications_set_updated_at
    before update on public.vendor_applications
    for each row execute function public.tg_set_updated_at();
  end if;
end $$;

-- ------------------------------------------------------------
-- 3) RLS for provider_memberships + vendor_applications
-- ------------------------------------------------------------
alter table public.provider_memberships enable row level security;
alter table public.vendor_applications enable row level security;

-- provider_memberships: users can read their own memberships; admins can read all
drop policy if exists provider_memberships_select_self on public.provider_memberships;
create policy provider_memberships_select_self
on public.provider_memberships
for select
using (
  user_id = auth.uid()
  or public.is_rooted_admin()
);

-- vendor_applications:
-- Applicants can SELECT their own; admins can SELECT all.
drop policy if exists vendor_applications_select_self on public.vendor_applications;
create policy vendor_applications_select_self
on public.vendor_applications
for select
using (
  user_id = auth.uid()
  or public.is_rooted_admin()
);

-- Applicants can INSERT only if user_id = auth.uid()
drop policy if exists vendor_applications_insert_self on public.vendor_applications;
create policy vendor_applications_insert_self
on public.vendor_applications
for insert
with check (user_id = auth.uid());

-- Applicants can UPDATE their own applications while in draft-ish states IF status column exists.
-- If status column is absent (unlikely), we fail open to "own row only".
drop policy if exists vendor_applications_update_self on public.vendor_applications;
create policy vendor_applications_update_self
on public.vendor_applications
for update
using (
  user_id = auth.uid()
  and (
    not exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name='vendor_applications' and column_name='status'
    )
    or status in ('draft','submitted','needs_info')
  )
)
with check (user_id = auth.uid());

-- Admin review updates allowed
drop policy if exists vendor_applications_admin_review on public.vendor_applications;
create policy vendor_applications_admin_review
on public.vendor_applications
for update
using (public.is_rooted_admin())
with check (public.is_rooted_admin());

-- ------------------------------------------------------------
-- 4) Age gate hook: submit must go through a function.
--    Hard fail closed unless the engine can prove eligibility.
-- ------------------------------------------------------------
create or replace function public.can_submit_vendor_application(p_user uuid)
returns boolean
language plpgsql
stable
as $$
declare
  v_ok boolean := false;
begin
  if p_user is null then
    return false;
  end if;

  if to_regclass('public.entity_flags') is not null then
    select exists (
      select 1
      from public.entity_flags ef
      where ef.entity_id = p_user
        and ef.flag_key in ('age_band_vendor_allowed','age_band_18_5_plus','is_18_5_plus')
        and ef.flag_value = true
        and (ef.expires_at is null or ef.expires_at > now())
    ) into v_ok;

    if v_ok then
      return true;
    end if;
  end if;

  return false;
end;
$$;

-- Submit function:
-- Uses your real vendor_applications.user_id column.
-- Status updates only if status column exists; otherwise it only stamps submitted time if available.
create or replace function public.submit_vendor_application(p_application_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_user_id_col text := 'user_id';
  v_has_status boolean;
  v_has_submitted_at boolean;
  v_status text;
  v_user uuid;
begin
  -- ensure the row exists & belongs to caller
  execute 'select user_id from public.vendor_applications where id = $1'
    into v_user
    using p_application_id;

  if v_user is null then
    raise exception 'Application not found';
  end if;

  if v_user <> auth.uid() then
    raise exception 'Not your application';
  end if;

  if not public.can_submit_vendor_application(v_user) then
    raise exception 'Vendor submission blocked: age-band gate not satisfied (requires engine flag).';
  end if;

  select exists(
    select 1 from information_schema.columns
    where table_schema='public' and table_name='vendor_applications' and column_name='status'
  ) into v_has_status;

  select exists(
    select 1 from information_schema.columns
    where table_schema='public' and table_name='vendor_applications' and column_name='submitted_at'
  ) into v_has_submitted_at;

  if v_has_status then
    execute 'select status from public.vendor_applications where id = $1'
      into v_status
      using p_application_id;

    if v_status not in ('draft','needs_info') then
      raise exception 'Only draft/needs_info applications can be submitted';
    end if;

    if v_has_submitted_at then
      execute 'update public.vendor_applications set status = ''submitted'', submitted_at = now() where id = $1'
        using p_application_id;
    else
      execute 'update public.vendor_applications set status = ''submitted'' where id = $1'
        using p_application_id;
    end if;
  else
    -- no status column: only stamp submitted_at if available
    if v_has_submitted_at then
      execute 'update public.vendor_applications set submitted_at = now() where id = $1'
        using p_application_id;
    else
      raise exception 'vendor_applications missing status/submitted_at; cannot submit safely';
    end if;
  end if;
end;
$$;

revoke all on function public.submit_vendor_application(uuid) from public;
grant execute on function public.submit_vendor_application(uuid) to authenticated;

-- ------------------------------------------------------------
-- 5) Approve flow: create/attach provider membership (owner) safely.
-- ------------------------------------------------------------
create or replace function public.approve_vendor_application(p_application_id uuid, p_provider_id uuid default null)
returns uuid
language plpgsql
security definer
as $$
declare
  v_user uuid;
  v_provider_id uuid;
begin
  if not public.is_rooted_admin() then
    raise exception 'Admin required';
  end if;

  execute 'select user_id from public.vendor_applications where id = $1'
    into v_user
    using p_application_id;

  if v_user is null then
    raise exception 'Application not found';
  end if;

  -- Determine provider id
  if p_provider_id is not null then
    v_provider_id := p_provider_id;
  else
    if to_regclass('public.providers') is null then
      raise exception 'providers table not found; pass p_provider_id to approve_vendor_application()';
    end if;

    -- require providers.id exists
    if not exists(
      select 1 from information_schema.columns
      where table_schema='public' and table_name='providers' and column_name='id'
    ) then
      raise exception 'providers.id column not found; pass p_provider_id';
    end if;

    v_provider_id := gen_random_uuid();

    if exists(
      select 1 from information_schema.columns
      where table_schema='public' and table_name='providers' and column_name='owner_user_id'
    ) then
      execute 'insert into public.providers (id, owner_user_id) values ($1, $2)'
      using v_provider_id, v_user;
    elsif exists(
      select 1 from information_schema.columns
      where table_schema='public' and table_name='providers' and column_name='created_by'
    ) then
      execute 'insert into public.providers (id, created_by) values ($1, $2)'
      using v_provider_id, v_user;
    else
      raise exception 'providers has no owner_user_id/created_by column; pass p_provider_id';
    end if;
  end if;

  -- Membership: make applicant the owner
  insert into public.provider_memberships (provider_id, user_id, membership_role)
  values (v_provider_id, v_user, 'owner')
  on conflict (provider_id, user_id) do update
    set membership_role = excluded.membership_role;

  -- Mark application decided if those columns exist (your schema has decided_at/decided_by)
  if exists(
    select 1 from information_schema.columns
    where table_schema='public' and table_name='vendor_applications' and column_name='status'
  ) then
    execute 'update public.vendor_applications set status = ''approved'' where id = $1'
      using p_application_id;
  end if;

  if exists(
    select 1 from information_schema.columns
    where table_schema='public' and table_name='vendor_applications' and column_name='decided_at'
  ) then
    execute 'update public.vendor_applications set decided_at = now() where id = $1'
      using p_application_id;
  end if;

  if exists(
    select 1 from information_schema.columns
    where table_schema='public' and table_name='vendor_applications' and column_name='decided_by'
  ) then
    execute 'update public.vendor_applications set decided_by = auth.uid() where id = $1'
      using p_application_id;
  end if;

  return v_provider_id;
end;
$$;

revoke all on function public.approve_vendor_application(uuid, uuid) from public;
grant execute on function public.approve_vendor_application(uuid, uuid) to authenticated;

commit;
