-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251217054500_engine_enforcement_core_v1.sql
-- ROOTED Engine-first enforcement core (tables + flags + deterministic engine evaluation)
-- Safe for Supabase migrations (no UI assumptions)

begin;

-- ------------------------------------------------------------
-- 0) Enums
-- ------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'engine_state') then
    create type engine_state as enum (
      'community',
      'discovery',
      'discovery_events',
      'registration',
      'b2b'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'engine_type') then
    create type engine_type as enum (
      'core_community',
      'core_discovery',
      'core_events',
      'core_registration',
      'core_b2b',
      'meta_infra',
      'regional_intel'
    );
  end if;
end;
$$;

-- ------------------------------------------------------------
-- 1) Engine registry (includes future engines, non-assignable)
-- ------------------------------------------------------------
create table if not exists public.engine_registry (
  engine_type engine_type primary key,
  is_active boolean not null default true,
  is_assignable_to_entities boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

insert into public.engine_registry (engine_type, is_assignable_to_entities)
values
  ('core_community', true),
  ('core_discovery', true),
  ('core_events', true),
  ('core_registration', true),
  ('core_b2b', true),
  ('meta_infra', false),
  ('regional_intel', false)
on conflict (engine_type) do update
  set is_assignable_to_entities = excluded.is_assignable_to_entities;

-- ------------------------------------------------------------
-- 2) Vertical policy (behavior ceiling)
-- ------------------------------------------------------------
create table if not exists public.vertical_policy (
  vertical_code text primary key,
  max_engine_state engine_state not null,
  allows_events boolean not null default false,
  allows_payments boolean not null default false,
  allows_b2b boolean not null default false,
  requires_moderation_for_discovery boolean not null default true,
  requires_age_rules_for_registration boolean not null default false,
  requires_refund_policy_for_registration boolean not null default false,
  requires_waiver_for_registration boolean not null default false,
  requires_insurance_for_registration boolean not null default false,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 3) Entity vertical state (runtime truth)
-- ------------------------------------------------------------
create table if not exists public.entity_vertical_state (
  entity_id uuid not null,
  vertical_code text not null references public.vertical_policy(vertical_code) on delete cascade,
  engine_state engine_state not null default 'community',
  last_evaluated_at timestamptz not null default now(),
  primary key (entity_id, vertical_code)
);

-- ------------------------------------------------------------
-- 4) Entity flags (truth layer)
-- ------------------------------------------------------------
create table if not exists public.entity_flags (
  entity_id uuid not null,
  vertical_code text not null references public.vertical_policy(vertical_code) on delete cascade,
  flag_key text not null,
  flag_value boolean not null,
  verified_at timestamptz not null default now(),
  expires_at timestamptz,
  source text not null check (source in ('system','admin','institution')),
  primary key (entity_id, vertical_code, flag_key)
);

-- ------------------------------------------------------------
-- 5) Specialty policy map (pre-seed guardrail)
-- ------------------------------------------------------------
create table if not exists public.specialty_policy_map (
  specialty_code text primary key,
  vertical_code text not null references public.vertical_policy(vertical_code) on delete restrict,
  engine_entry_state engine_state not null,
  max_engine_state engine_state not null,
  required_flags jsonb not null,
  allowed_groups jsonb
);

-- ------------------------------------------------------------
-- 6) Groups (routing only) + memberships
-- ------------------------------------------------------------
create table if not exists public.groups (
  group_code text primary key,
  vertical_code text not null references public.vertical_policy(vertical_code) on delete cascade,
  required_engine_state engine_state not null,
  allow_cross_engine boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.group_memberships (
  entity_id uuid not null,
  group_code text not null references public.groups(group_code) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (entity_id, group_code)
);

-- ------------------------------------------------------------
-- 7) Helpers
-- ------------------------------------------------------------

-- Enum rank so we can compare states safely.
create or replace function public.engine_state_rank(p_state engine_state)
returns int
language sql
immutable
as $$
  select case p_state
    when 'community' then 1
    when 'discovery' then 2
    when 'discovery_events' then 3
    when 'registration' then 4
    when 'b2b' then 5
  end;
$$;

create or replace function public.has_valid_flag(
  p_entity uuid,
  p_vertical text,
  p_flag text
) returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.entity_flags f
    where f.entity_id = p_entity
      and f.vertical_code = p_vertical
      and f.flag_key = p_flag
      and f.flag_value = true
      and (f.expires_at is null or f.expires_at > now())
  );
$$;

-- ------------------------------------------------------------
-- 8) The brain: deterministic evaluation (includes downgrades)
-- ------------------------------------------------------------
create or replace function public.evaluate_entity_engine_state(
  p_entity uuid,
  p_vertical text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_policy public.vertical_policy;
  v_new engine_state := 'community';
  v_cap engine_state;
begin
  select * into v_policy
  from public.vertical_policy
  where vertical_code = p_vertical;

  if not found then
    raise exception 'vertical_policy missing for vertical_code=%', p_vertical;
  end if;

  -- DISCOVERY gating (moderation may be required by vertical)
  if public.has_valid_flag(p_entity, p_vertical, 'profile_complete')
     and (
       v_policy.requires_moderation_for_discovery = false
       or public.has_valid_flag(p_entity, p_vertical, 'moderation_approved')
     )
  then
    v_new := 'discovery';
  end if;

  -- EVENTS gating
  if v_policy.allows_events
     and public.has_valid_flag(p_entity, p_vertical, 'events_enabled')
     and public.engine_state_rank(v_new) >= public.engine_state_rank('discovery')
  then
    v_new := 'discovery_events';
  end if;

  -- REGISTRATION gating
  if v_policy.allows_payments
     and public.has_valid_flag(p_entity, p_vertical, 'payments_enabled')
     and public.engine_state_rank(v_new) >= public.engine_state_rank('discovery_events')
  then
    -- required vertical flags
    if v_policy.requires_age_rules_for_registration
       and not public.has_valid_flag(p_entity, p_vertical, 'age_rules_defined') then
      -- stay at discovery_events
    elsif v_policy.requires_refund_policy_for_registration
       and not public.has_valid_flag(p_entity, p_vertical, 'refund_policy_defined') then
      -- stay at discovery_events
    elsif v_policy.requires_waiver_for_registration
       and not public.has_valid_flag(p_entity, p_vertical, 'waivers_configured') then
      -- stay at discovery_events
    elsif v_policy.requires_insurance_for_registration
       and not public.has_valid_flag(p_entity, p_vertical, 'insurance_verified') then
      -- stay at discovery_events
    else
      v_new := 'registration';
    end if;
  end if;

  -- B2B gating (strict, never default)
  if v_policy.allows_b2b
     and public.has_valid_flag(p_entity, p_vertical, 'b2b_eligible')
     and public.has_valid_flag(p_entity, p_vertical, 'vetting_approved')
  then
    v_new := 'b2b';
  end if;

  -- Hard cap by vertical max_engine_state
  v_cap := v_policy.max_engine_state;
  if public.engine_state_rank(v_new) > public.engine_state_rank(v_cap) then
    v_new := v_cap;
  end if;

  -- Upsert state row (if missing, create it)
  insert into public.entity_vertical_state(entity_id, vertical_code, engine_state, last_evaluated_at)
  values (p_entity, p_vertical, v_new, now())
  on conflict (entity_id, vertical_code)
  do update set engine_state = excluded.engine_state,
                last_evaluated_at = excluded.last_evaluated_at;

end;
$$;

-- ------------------------------------------------------------
-- 9) Triggers: no silent drift
-- ------------------------------------------------------------
create or replace function public._on_entity_flags_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_entity uuid;
  v_vertical text;
begin
  if (tg_op = 'DELETE') then
    v_entity := old.entity_id;
    v_vertical := old.vertical_code;
  else
    v_entity := new.entity_id;
    v_vertical := new.vertical_code;
  end if;

  perform public.evaluate_entity_engine_state(v_entity, v_vertical);

  if (tg_op = 'DELETE') then
    return old;
  else
    return new;
  end if;
end;
$$;

drop trigger if exists trg_entity_flags_change on public.entity_flags;
create trigger trg_entity_flags_change
after insert or update or delete on public.entity_flags
for each row execute function public._on_entity_flags_change();

-- Group guard trigger
create or replace function public._enforce_group_engine_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_required engine_state;
  v_vertical text;
  v_current engine_state;
begin
  select g.required_engine_state, g.vertical_code
    into v_required, v_vertical
  from public.groups g
  where g.group_code = new.group_code;

  if not found then
    raise exception 'Unknown group_code=%', new.group_code;
  end if;

  select s.engine_state into v_current
  from public.entity_vertical_state s
  where s.entity_id = new.entity_id
    and s.vertical_code = v_vertical;

  if v_current is null then
    raise exception 'Entity has no entity_vertical_state for vertical_code=%', v_vertical;
  end if;

  if public.engine_state_rank(v_current) < public.engine_state_rank(v_required) then
    raise exception 'Entity does not meet engine requirement for group (need %, have %)', v_required, v_current;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_group_guard on public.group_memberships;
create trigger trg_group_guard
before insert on public.group_memberships
for each row execute function public._enforce_group_engine_guard();

-- OPTIONAL: seed safety
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'prevent_illegal_engine_seed') then
    alter table public.entity_vertical_state
      add constraint prevent_illegal_engine_seed
      check (engine_state in ('community','discovery','discovery_events'));
  end if;
end;
$$;

commit;