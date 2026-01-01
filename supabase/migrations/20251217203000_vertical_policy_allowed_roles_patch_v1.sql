-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251217203000_vertical_policy_allowed_roles_patch_v1.sql
-- Add min_engine_state + allowed_roles to vertical_policy (engine-aware bounds + role hard-stop)
-- Safe/idempotent.

begin;

-- allow canonical writes in migration context (you use this pattern elsewhere)
select set_config('rooted.migration_bypass', 'on', true);

-- ------------------------------------------------------------
-- 1) Add missing columns (use the REAL enum type)
-- ------------------------------------------------------------
alter table public.vertical_policy
  add column if not exists min_engine_state public.engine_state,
  add column if not exists allowed_roles text[];

-- ------------------------------------------------------------
-- 2) Backfill defaults (do not change existing max_engine_state)
--    min defaults to 'discovery' unless you explicitly set otherwise later.
-- ------------------------------------------------------------
update public.vertical_policy
set min_engine_state = 'discovery'
where min_engine_state is null;

-- ------------------------------------------------------------
-- 3) Hard-stop future verticals: META + REGIONAL are institution/admin only
--    (you can expand later, but the floor is locked to non-community roles)
-- ------------------------------------------------------------
update public.vertical_policy
set allowed_roles = array['admin','institution']
where vertical_code in ('META_INFRASTRUCTURE', 'REGIONAL_INTELLIGENCE')
  and (allowed_roles is null or cardinality(allowed_roles) = 0);

-- For everything else: default to allow all core roles if not set yet
-- (You can tighten per-vertical later in your matrix.)
update public.vertical_policy
set allowed_roles = array['admin','institution','vendor','community']
where (allowed_roles is null or cardinality(allowed_roles) = 0)
  and vertical_code not in ('META_INFRASTRUCTURE', 'REGIONAL_INTELLIGENCE');

-- ------------------------------------------------------------
-- 4) Sanity constraint: min <= max (blocks invalid configs)
-- ------------------------------------------------------------
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'vertical_policy_min_le_max'
      and conrelid = 'public.vertical_policy'::regclass
  ) then
    alter table public.vertical_policy
      add constraint vertical_policy_min_le_max
      check (min_engine_state <= max_engine_state);
  end if;
end;
$$;

commit;