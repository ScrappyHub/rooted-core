-- 20251216231500_add_sanctuary_specialties_to_canon.sql
-- Purpose: ensure sanctuary specialties exist in canonical_specialties and (if present) map them to AGRICULTURE.
-- GUARDED: some repos/boot orders may not include vertical_canonical_specialties yet.

begin;

-- ---------------------------------------------------------------------
-- 1) Ensure the sanctuary specialty codes exist in canonical_specialties
-- ---------------------------------------------------------------------
create table if not exists public.canonical_specialties (
  specialty_code text primary key,
  created_at timestamptz not null default now()
);

insert into public.canonical_specialties (specialty_code) values
  ('AGRI_ANIMAL_SANCTUARY'),
  ('AGRI_WILDLIFE_RESCUE_REHAB')
on conflict do nothing;

-- ---------------------------------------------------------------------
-- 2) Map to AGRICULTURE in vertical_canonical_specialties (if it exists)
-- ---------------------------------------------------------------------
do $do$
begin
  if to_regclass('public.vertical_canonical_specialties') is null then
    raise notice 'Skipping sanctuary mapping: public.vertical_canonical_specialties does not exist.';
    return;
  end if;

  -- If your relation has different column names, adjust here later.
  execute $sql$
    insert into public.vertical_canonical_specialties (vertical_code, specialty_code, is_default)
    values
      ('AGRICULTURE', 'AGRI_ANIMAL_SANCTUARY', false),
      ('AGRICULTURE', 'AGRI_WILDLIFE_RESCUE_REHAB', false)
    on conflict do nothing
  $sql$;
end
$do$;

commit;
