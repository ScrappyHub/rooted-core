-- 20251216242000_seed_standard_vendor_specialty_groups.sql
-- Creates specialty governance groups + membership table (if missing)
-- Seeds STANDARD_VENDOR memberships (idempotent)

begin;

-- ------------------------------------------------------------
-- 1) Core governance tables (schema-safe)
-- ------------------------------------------------------------

create table if not exists public.specialty_governance_groups (
  group_key text primary key,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.specialty_governance_group_members (
  specialty_code text not null,
  group_key text not null references public.specialty_governance_groups(group_key) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (specialty_code, group_key)
);

-- Basic safety (no blank codes) — Postgres has no "ADD CONSTRAINT IF NOT EXISTS"
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'specialty_governance_group_members_specialty_not_blank_chk'
  ) then
    alter table public.specialty_governance_group_members
      add constraint specialty_governance_group_members_specialty_not_blank_chk
      check (nullif(btrim(specialty_code), '') is not null);
  end if;
end $$;

-- ------------------------------------------------------------
-- 2) Ensure group exists
-- ------------------------------------------------------------

insert into public.specialty_governance_groups (group_key, description)
values ('STANDARD_VENDOR', 'Default vetted vendor access across supported marketplaces')
on conflict (group_key) do update
  set description = excluded.description;

-- ------------------------------------------------------------
-- 3) Seed specialty → group (only if specialty exists in your canon view)
-- ------------------------------------------------------------

insert into public.specialty_governance_group_members (specialty_code, group_key)
select distinct s.specialty_code, 'STANDARD_VENDOR'
from (
  values
    ('ASSEMBLY_PLANT'),
    ('RESEARCH_CENTER'),
    ('FARM'),
    ('META_INFRA'),
    ('CONSERVATION_GROUP'),
    ('THERAPY_CENTER'),
    ('LAND_TRUST'),
    ('TOWN_HALL'),
    ('MUSEUM'),
    ('HOUSING_AUTHORITY'),
    ('PUBLIC_TRANSIT'),
    ('CAMPUS_SAFETY'),
    ('CLINIC'),
    ('COMMUNITY_CENTER'),
    ('GENERAL_CONTRACTOR'),
    ('PARKS_AND_RECREATION')
) as s(specialty_code)
where exists (
  select 1
  from public.vertical_specialties_v1 vs
  where vs.specialty_code = s.specialty_code
)
on conflict (specialty_code, group_key) do nothing;

commit;
