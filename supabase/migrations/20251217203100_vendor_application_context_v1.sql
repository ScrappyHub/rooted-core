-- 20251217201500_vendor_application_context_v1.sql
-- Canonical: One auth user can operate multiple provider entities.
-- Adds: vendor_applications + provider_memberships + hard-lock submit/approve functions (no UI trust).
-- Safe: additive, idempotent, avoids guessing existing columns.

begin;

-- Canonical tables are guarded by triggers
select set_config('rooted.migration_bypass', 'on', true);

-- ------------------------------------------------------------
-- 0) Helper: detect ROOTED admin safely (supports multiple schemas)
--    Returns false if it can't prove admin.
-- ------------------------------------------------------------
create or replace function public.is_rooted_admin()
returns boolean
language plpgsql
stable
as $$
declare
  v_is_admin boolean := false;
  v_has_user_tiers boolean := (to_regclass('public.user_tiers') is not null);
  v_has_role_col boolean := false;
  v_has_user_id_col boolean := false;
begin
  if auth.uid() is null then
    return false;
  end if;

  if v_has_user_tiers then
    select exists(
      select 1
      from information_schema.columns
      where table_schema='public' and table_name='user_tiers' and column_name='role'
    ) into v_has_role_col;

    select exists(
      select 1
      from information_schema.columns
      where table_schema='public' and table_name='user_tiers' and column_name in ('user_id','id')
    ) into v_has_user_id_col;

    if v_has_role_col and v_has_user_id_col then
      -- try user_id first
      if exists(
        select 1
        from information_schema.columns
        where table_schema='public' and table_name='user_tiers' and column_name='user_id'
      ) then
        select exists(
          select 1 from public.user_tiers ut
          where ut.user_id = auth.uid()
            and ut.role = 'admin'
        ) into v_is_admin;
        return coalesce(v_is_admin,false);
      end if;

      -- fallback to id
      if exists(
        select 1
        from information_schema.columns
        where table_schema='public' and table_name='user_tiers' and column_name='id'
      ) then
        select exists(
          select 1 from public.user_tiers ut
          where ut.id = auth.uid()
            and ut.role = 'admin'
        ) into v_is_admin;
        return coalesce(v_is_admin,false);
      end if;
    end if;
  end if;

  return false;
end;
$$;

-- ------------------------------------------------------------
-- 1) provider_memberships (context switching authority)
--    This is the hard link: user <-> provider with explicit membership_role.
-- ------------------------------------------------------------
create table if not exists public.provider_memberships (
  provider_id uuid not null,
  user_id uuid not null,
  membership_role text not null check (membership_role in ('owner','admin','manager','staff','viewer')),
  created_at timestamptz not null default now(),
  primary key (provider_id, user_id)
);

-- ------------------------------------------------------------
-- 2) vendor_applications (no limbo: always tied to applicant_user_id)
-- ------------------------------------------------------------
create table if not exists public.vendor_applications (
  id uuid primary key default gen_random_uuid(),
  applicant_user_id uuid not null,
  application_type text not null check (application_type in ('vendor','institution')),
  status text not null check (status in ('draft','submitted','needs_info','approved','rejected','withdrawn')),
  proposed_display_name text,
  proposed_verticals jsonb,
  proposed_specialties jsonb,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  review_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists vendor_applications_applicant_idx
  on public.vendor_applications(applicant_user_id);

-- Keep updated_at current
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
  if not exists (
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
-- Applicants can CRUD while draft; submit/approve is function-driven.
drop policy if exists vendor_applications_select_self on public.vendor_applications;
create policy vendor_applications_select_self
on public.vendor_applications
for select
using (
  applicant_user_id = auth.uid()
  or public.is_rooted_admin()
);

drop policy if exists vendor_applications_insert_self on public.vendor_applications;
create policy vendor_applications_insert_self
on public.vendor_applications
for insert
with check (
  applicant_user_id = auth.uid()
  and status = 'draft'
);

drop policy if exists vendor_applications_update_draft_self on public.vendor_applications;
create policy vendor_applications_update_draft_self
on public.vendor_applications
for update
using (
  applicant_user_id = auth.uid()
  and status = 'draft'
)
with check (
  applicant_user_id = auth.uid()
  and status = 'draft'
);

-- Admin review updates allowed (needs_info/approved/rejected) via function or direct update
drop policy if exists vendor_applications_admin_review on public.vendor_applications;
create policy vendor_applications_admin_review
on public.vendor_applications
for update
using (public.is_rooted_admin())
with check (public.is_rooted_admin());

-- ------------------------------------------------------------
-- 4) Age gate hook: submit must go through a function.
--    This avoids “UI says submitted” and avoids relying on unknown tables in RLS.
-- ------------------------------------------------------------

-- Optional: if you already have an age intel function/table, wire it here later.
-- For now: we enforce via entity_flags if present; otherwise we hard-fail with a clear error.
create or replace function public.can_submit_vendor_application(p_user uuid)
returns boolean
language plpgsql
stable
as $$
declare
  v_has_entity_flags boolean := (to_regclass('public.entity_flags') is not null);
  v_ok boolean := false;
begin
  if p_user is null then
    return false;
  end if;

  -- Preferred: engine flag gate (matches your engine-first architecture)
  if v_has_entity_flags then
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

  -- If we can't prove eligibility, fail closed (hard lock).
  return false;
end;
$$;

create or replace function public.submit_vendor_application(p_application_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_app public.vendor_applications;
begin
  select * into v_app
  from public.vendor_applications
  where id = p_application_id;

  if v_app.id is null then
    raise exception 'Application not found';
  end if;

  if v_app.applicant_user_id <> auth.uid() then
    raise exception 'Not your application';
  end if;

  if v_app.status <> 'draft' then
    raise exception 'Only draft applications can be submitted';
  end if;

  if not public.can_submit_vendor_application(v_app.applicant_user_id) then
    raise exception 'Vendor submission blocked: age-band gate not satisfied (requires engine flag).';
  end if;

  update public.vendor_applications
  set status = 'submitted',
      submitted_at = now()
  where id = v_app.id;
end;
$$;

revoke all on function public.submit_vendor_application(uuid) from public;
grant execute on function public.submit_vendor_application(uuid) to authenticated;

-- ------------------------------------------------------------
-- 5) Approve flow: create/attach provider membership (owner) safely.
--    We do NOT assume provider schema; we attempt inserts only if columns exist.
-- ------------------------------------------------------------

create or replace function public.approve_vendor_application(p_application_id uuid, p_provider_id uuid default null)
returns uuid
language plpgsql
security definer
as $$
declare
  v_app public.vendor_applications;
  v_provider_id uuid;
  v_has_providers boolean := (to_regclass('public.providers') is not null);
  v_has_id boolean := false;
  v_has_owner boolean := false;
begin
  if not public.is_rooted_admin() then
    raise exception 'Admin required';
  end if;

  select * into v_app
  from public.vendor_applications
  where id = p_application_id;

  if v_app.id is null then
    raise exception 'Application not found';
  end if;

  if v_app.status not in ('submitted','needs_info') then
    raise exception 'Application must be submitted/needs_info to approve';
  end if;

  -- If provider already exists (admin supplied), use it.
  if p_provider_id is not null then
    v_provider_id := p_provider_id;
  else
    -- Otherwise, create provider if your providers table exists and supports it.
    if not v_has_providers then
      raise exception 'providers table not found; pass p_provider_id to approve_vendor_application()';
    end if;

    select exists(
      select 1 from information_schema.columns
      where table_schema='public' and table_name='providers' and column_name='id'
    ) into v_has_id;

    select exists(
      select 1 from information_schema.columns
      where table_schema='public' and table_name='providers' and column_name in ('owner_user_id','created_by')
    ) into v_has_owner;

    if not v_has_id then
      raise exception 'providers.id column not found; pass p_provider_id';
    end if;

    -- Create minimal provider row using whatever ownership column you have.
    v_provider_id := gen_random_uuid();

    if exists(
      select 1 from information_schema.columns
      where table_schema='public' and table_name='providers' and column_name='owner_user_id'
    ) then
      execute format(
        'insert into public.providers (id, owner_user_id) values ($1, $2)'
      )
      using v_provider_id, v_app.applicant_user_id;
    elsif exists(
      select 1 from information_schema.columns
      where table_schema='public' and table_name='providers' and column_name='created_by'
    ) then
      execute format(
        'insert into public.providers (id, created_by) values ($1, $2)'
      )
      using v_provider_id, v_app.applicant_user_id;
    else
      raise exception 'providers has no owner_user_id/created_by column; pass p_provider_id';
    end if;
  end if;

  -- Membership: make applicant the owner
  insert into public.provider_memberships (provider_id, user_id, membership_role)
  values (v_provider_id, v_app.applicant_user_id, 'owner')
  on conflict (provider_id, user_id) do update
    set membership_role = excluded.membership_role;

  update public.vendor_applications
  set status = 'approved',
      reviewed_at = now(),
      review_notes = coalesce(review_notes,'')
  where id = v_app.id;

  return v_provider_id;
end;
$$;

revoke all on function public.approve_vendor_application(uuid, uuid) from public;
grant execute on function public.approve_vendor_application(uuid, uuid) to authenticated;

commit;
