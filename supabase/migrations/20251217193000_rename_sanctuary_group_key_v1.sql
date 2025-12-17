-- 20251217193000_rename_sanctuary_group_key_v1.sql
-- Rename specialty governance group key SANCTUARY_RESCUE -> ANIMAL_SANCTUARY_RESCUE_REHAB (idempotent)
begin;

select set_config('rooted.migration_bypass', 'on', true);

-- 1) Ensure new group exists
insert into public.specialty_governance_groups (group_key, description)
values (
  'ANIMAL_SANCTUARY_RESCUE_REHAB',
  'Animal sanctuaries + wildlife rescue/rehab. Volunteer-only events, conservative access, sanctuary-aligned safety rules.'
)
on conflict (group_key) do update
set description = excluded.description;

-- 2) Move memberships over (idempotent)
update public.specialty_governance_group_members
set group_key = 'ANIMAL_SANCTUARY_RESCUE_REHAB'
where group_key = 'SANCTUARY_RESCUE';

-- 3) Drop old group row if it exists and is now empty
delete from public.specialty_governance_groups g
where g.group_key = 'SANCTUARY_RESCUE'
  and not exists (
    select 1
    from public.specialty_governance_group_members m
    where m.group_key = 'SANCTUARY_RESCUE'
  );

commit;
