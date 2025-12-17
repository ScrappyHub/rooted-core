begin;

-- 1) Add the new vertical
insert into public.canonical_verticals (vertical_code, label, default_specialty)
values ('INTERESTS_HOBBIES', 'Interests & Hobbies', 'INTERESTS_GENERAL')
on conflict (vertical_code) do update
  set label = excluded.label,
      default_specialty = excluded.default_specialty;

-- 2) Add a real default specialty for Interests (minimal + safe)
-- NOTE: This only works if canonical_specialties has defaults for any extra columns.
insert into public.canonical_specialties (specialty_code, specialty_label)
values ('INTERESTS_GENERAL', 'Interests / Hobbies (General)')
on conflict (specialty_code) do update
  set specialty_label = excluded.specialty_label;

-- 3) Ensure the vertical→specialty default mapping exists
insert into public.vertical_canonical_specialties (vertical_code, specialty_code, is_default)
values ('INTERESTS_HOBBIES', 'INTERESTS_GENERAL', true)
on conflict (vertical_code, specialty_code) do update
  set is_default = excluded.is_default;

commit;
