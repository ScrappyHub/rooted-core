-- 20251216231500_add_sanctuary_specialties_to_canon.sql
-- Adds sanctuary specialties to canonical_specialties, maps them to AGRICULTURE,
-- then registers them in sanctuary_specialties. Idempotent + safe.

begin;

-- ---------------------------------------------------------------------
-- 1) Seed canonical specialties (must exist before sanctuary_specialties FK)
-- ---------------------------------------------------------------------
do $$
declare
  cols text[];
  has_label boolean;
begin
  if to_regclass('public.canonical_specialties') is null then
    raise exception 'public.canonical_specialties does not exist';
  end if;

  select array_agg(column_name::text)
  into cols
  from information_schema.columns
  where table_schema='public'
    and table_name='canonical_specialties';

  has_label := ('specialty_label' = any(cols));

  if has_label then
    execute $ins$
      insert into public.canonical_specialties (specialty_code, specialty_label)
      values
        ('AGRI_ANIMAL_SANCTUARY', 'Animal Sanctuary'),
        ('AGRI_WILDLIFE_RESCUE_REHAB', 'Wildlife Rescue & Rehabilitation')
      on conflict (specialty_code) do update
        set specialty_label = excluded.specialty_label
    $ins$;
  else
    execute $ins$
      insert into public.canonical_specialties (specialty_code)
      values
        ('AGRI_ANIMAL_SANCTUARY'),
        ('AGRI_WILDLIFE_RESCUE_REHAB')
      on conflict (specialty_code) do nothing
    $ins$;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 2) Map to AGRICULTURE in vertical_canonical_specialties (non-default)
-- ---------------------------------------------------------------------
do $$
begin
  if to_regclass('public.vertical_canonical_specialties') is null then
    raise exception 'public.vertical_canonical_specialties does not exist';
  end if;

  -- If your table has more columns, they should have defaults.
  insert into public.vertical_canonical_specialties (vertical_code, specialty_code, is_default)
  values
    ('AGRICULTURE', 'AGRI_ANIMAL_SANCTUARY', false),
    ('AGRICULTURE', 'AGRI_WILDLIFE_RESCUE_REHAB', false)
  on conflict do nothing;
end $$;

-- ---------------------------------------------------------------------
-- 3) Register as sanctuary specialties (this is your enforcement list)
-- ---------------------------------------------------------------------
do $$
begin
  if to_regclass('public.sanctuary_specialties') is null then
    raise exception 'public.sanctuary_specialties does not exist';
  end if;

  insert into public.sanctuary_specialties (specialty_code)
  values
    ('AGRI_ANIMAL_SANCTUARY'),
    ('AGRI_WILDLIFE_RESCUE_REHAB')
  on conflict do nothing;
end $$;

commit;
