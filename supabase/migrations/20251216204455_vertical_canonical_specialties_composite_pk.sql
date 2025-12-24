-- 20251216204455_vertical_canonical_specialties_composite_pk.sql
-- Make vertical_canonical_specialties support ON CONFLICT (vertical_code, specialty_code)
-- Also enforce: only ONE is_default=true row per vertical_code.

begin;

-- 1) Replace single-column PK (vertical_code) with composite PK (vertical_code, specialty_code)
alter table public.vertical_canonical_specialties
  drop constraint if exists vertical_canonical_specialties_pkey;

alter table public.vertical_canonical_specialties
  add constraint vertical_canonical_specialties_pkey
  primary key (vertical_code, specialty_code);

-- 2) Enforce only one default per vertical
drop index if exists vertical_canonical_specialties_one_default_per_vertical;

create unique index vertical_canonical_specialties_one_default_per_vertical
  on public.vertical_canonical_specialties (vertical_code)
  where is_default is true;

commit;