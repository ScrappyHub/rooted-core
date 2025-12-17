begin;

-- Ensure group exists
insert into public.specialty_governance_groups (group_key, description)
values ('STANDARD_VENDOR', 'Default vetted vendor access across supported marketplaces')
on conflict (group_key) do update
  set description = excluded.description;

-- Seed memberships (idempotent)
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
