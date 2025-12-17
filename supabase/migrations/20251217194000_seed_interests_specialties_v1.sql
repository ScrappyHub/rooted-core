-- 20251217194000_seed_interests_specialties_v1.sql
-- Seed Interests & Hobbies specialties into:
--  - canonical_specialties (code-only)
--  - specialty_types (FK target + labels)
--  - vertical_canonical_specialties (vertical membership; default stays INTERESTS_GENERAL)

begin;

select set_config('rooted.migration_bypass', 'on', true);

-- ------------------------------------------------------------
-- 0) Ensure the default specialty exists in FK target
-- ------------------------------------------------------------
insert into public.canonical_specialties (specialty_code)
values ('INTERESTS_GENERAL')
on conflict (specialty_code) do nothing;

insert into public.specialty_types (
  id, code, label, vertical_group, requires_compliance, kids_allowed, default_visibility, vertical_code
)
select gen_random_uuid(), 'INTERESTS_GENERAL', 'Interests (General)', 'INTERESTS', false, true, true, 'INTERESTS_HOBBIES'
where not exists (select 1 from public.specialty_types where code = 'INTERESTS_GENERAL');

-- ------------------------------------------------------------
-- 1A) canonical_specialties (code-only)
-- ------------------------------------------------------------
with seed(code, label) as (
  values
    ('INTERESTS_HOBBY_STORE',            'Hobby Store'),
    ('INTERESTS_ART_STUDIO',             'Art Studio'),
    ('INTERESTS_PHOTOGRAPHY',            'Photography Class / Club'),
    ('INTERESTS_POTTERY_GLASS',          'Pottery / Ceramics / Glass Studio'),
    ('INTERESTS_MUSIC_LESSONS',          'Music Lessons / Studio'),
    ('INTERESTS_DANCE_STUDIO',           'Dance Studio'),
    ('INTERESTS_THEATER_WORKSHOP',       'Theater / Acting Workshop'),

    ('INTERESTS_CODING_WORKSHOP',        'Coding Workshop / Club'),
    ('INTERESTS_GAME_DEV_CLASS',         'Game Development Class'),
    ('INTERESTS_ROBOTICS_CLUB',          'Robotics Club / Lab'),
    ('INTERESTS_MAKER_STUDIO',           'Maker Studio / Fabrication Lab'),
    ('INTERESTS_3D_PRINTING',            '3D Printing / CAD Studio'),

    ('INTERESTS_COOKING_CLASS',          'Cooking Class'),
    ('INTERESTS_BAKING_WORKSHOP',        'Baking Workshop'),
    ('INTERESTS_WOODWORKING',            'Woodworking / Carpentry Workshop'),
    ('INTERESTS_GARDENING',              'Gardening / Horticulture Workshop'),
    ('INTERESTS_DIY_SKILLS',             'DIY Skills / Home Projects Class'),

    ('INTERESTS_SURF_LESSONS',           'Surf Lessons'),
    ('INTERESTS_SKI_SNOWBOARD_LESSONS',  'Ski / Snowboard Lessons'),
    ('INTERESTS_SKATE_SCOOTER',          'Skateboarding / Scooter Lessons'),
    ('INTERESTS_CLIMBING_GYM',           'Climbing Gym / Instruction'),
    ('INTERESTS_WATER_SPORTS',           'Water Sports Lessons'),
    ('INTERESTS_DISC_GOLF',              'Disc Golf League / Clinic'),
    ('INTERESTS_GOLF_CLINIC',            'Golf Clinic / Lessons'),
    ('INTERESTS_OUTDOOR_SKILLS',         'Outdoor Skills / Survival / Navigation')
)
insert into public.canonical_specialties (specialty_code)
select code from seed
on conflict (specialty_code) do nothing;

-- ------------------------------------------------------------
-- 1B) specialty_types (labels + FK target + vertical attachment)
-- ------------------------------------------------------------
with seed(code, label) as (
  values
    ('INTERESTS_HOBBY_STORE',            'Hobby Store'),
    ('INTERESTS_ART_STUDIO',             'Art Studio'),
    ('INTERESTS_PHOTOGRAPHY',            'Photography Class / Club'),
    ('INTERESTS_POTTERY_GLASS',          'Pottery / Ceramics / Glass Studio'),
    ('INTERESTS_MUSIC_LESSONS',          'Music Lessons / Studio'),
    ('INTERESTS_DANCE_STUDIO',           'Dance Studio'),
    ('INTERESTS_THEATER_WORKSHOP',       'Theater / Acting Workshop'),

    ('INTERESTS_CODING_WORKSHOP',        'Coding Workshop / Club'),
    ('INTERESTS_GAME_DEV_CLASS',         'Game Development Class'),
    ('INTERESTS_ROBOTICS_CLUB',          'Robotics Club / Lab'),
    ('INTERESTS_MAKER_STUDIO',           'Maker Studio / Fabrication Lab'),
    ('INTERESTS_3D_PRINTING',            '3D Printing / CAD Studio'),

    ('INTERESTS_COOKING_CLASS',          'Cooking Class'),
    ('INTERESTS_BAKING_WORKSHOP',        'Baking Workshop'),
    ('INTERESTS_WOODWORKING',            'Woodworking / Carpentry Workshop'),
    ('INTERESTS_GARDENING',              'Gardening / Horticulture Workshop'),
    ('INTERESTS_DIY_SKILLS',             'DIY Skills / Home Projects Class'),

    ('INTERESTS_SURF_LESSONS',           'Surf Lessons'),
    ('INTERESTS_SKI_SNOWBOARD_LESSONS',  'Ski / Snowboard Lessons'),
    ('INTERESTS_SKATE_SCOOTER',          'Skateboarding / Scooter Lessons'),
    ('INTERESTS_CLIMBING_GYM',           'Climbing Gym / Instruction'),
    ('INTERESTS_WATER_SPORTS',           'Water Sports Lessons'),
    ('INTERESTS_DISC_GOLF',              'Disc Golf League / Clinic'),
    ('INTERESTS_GOLF_CLINIC',            'Golf Clinic / Lessons'),
    ('INTERESTS_OUTDOOR_SKILLS',         'Outdoor Skills / Survival / Navigation')
)
insert into public.specialty_types (
  id, code, label, vertical_group, requires_compliance, kids_allowed, default_visibility, vertical_code
)
select
  gen_random_uuid(),
  s.code,
  s.label,
  'INTERESTS',
  false,
  true,
  true,
  'INTERESTS_HOBBIES'
from seed s
where not exists (select 1 from public.specialty_types st where st.code = s.code);

-- ------------------------------------------------------------
-- 1C) vertical_canonical_specialties (membership; default stays INTERESTS_GENERAL)
-- ------------------------------------------------------------
with seed(code) as (
  values
    ('INTERESTS_GENERAL'),
    ('INTERESTS_HOBBY_STORE'),
    ('INTERESTS_ART_STUDIO'),
    ('INTERESTS_PHOTOGRAPHY'),
    ('INTERESTS_POTTERY_GLASS'),
    ('INTERESTS_MUSIC_LESSONS'),
    ('INTERESTS_DANCE_STUDIO'),
    ('INTERESTS_THEATER_WORKSHOP'),
    ('INTERESTS_CODING_WORKSHOP'),
    ('INTERESTS_GAME_DEV_CLASS'),
    ('INTERESTS_ROBOTICS_CLUB'),
    ('INTERESTS_MAKER_STUDIO'),
    ('INTERESTS_3D_PRINTING'),
    ('INTERESTS_COOKING_CLASS'),
    ('INTERESTS_BAKING_WORKSHOP'),
    ('INTERESTS_WOODWORKING'),
    ('INTERESTS_GARDENING'),
    ('INTERESTS_DIY_SKILLS'),
    ('INTERESTS_SURF_LESSONS'),
    ('INTERESTS_SKI_SNOWBOARD_LESSONS'),
    ('INTERESTS_SKATE_SCOOTER'),
    ('INTERESTS_CLIMBING_GYM'),
    ('INTERESTS_WATER_SPORTS'),
    ('INTERESTS_DISC_GOLF'),
    ('INTERESTS_GOLF_CLINIC'),
    ('INTERESTS_OUTDOOR_SKILLS')
)
insert into public.vertical_canonical_specialties (vertical_code, specialty_code, is_default)
select 'INTERESTS_HOBBIES', s.code, (s.code = 'INTERESTS_GENERAL')
from seed s
on conflict (vertical_code, specialty_code) do update
set is_default = excluded.is_default;

-- Force single default (defensive)
update public.vertical_canonical_specialties
set is_default = (specialty_code = 'INTERESTS_GENERAL')
where vertical_code = 'INTERESTS_HOBBIES'
  and specialty_code in (
    'INTERESTS_GENERAL',
    'INTERESTS_HOBBY_STORE','INTERESTS_ART_STUDIO','INTERESTS_PHOTOGRAPHY','INTERESTS_POTTERY_GLASS',
    'INTERESTS_MUSIC_LESSONS','INTERESTS_DANCE_STUDIO','INTERESTS_THEATER_WORKSHOP',
    'INTERESTS_CODING_WORKSHOP','INTERESTS_GAME_DEV_CLASS','INTERESTS_ROBOTICS_CLUB','INTERESTS_MAKER_STUDIO','INTERESTS_3D_PRINTING',
    'INTERESTS_COOKING_CLASS','INTERESTS_BAKING_WORKSHOP','INTERESTS_WOODWORKING','INTERESTS_GARDENING','INTERESTS_DIY_SKILLS',
    'INTERESTS_SURF_LESSONS','INTERESTS_SKI_SNOWBOARD_LESSONS','INTERESTS_SKATE_SCOOTER','INTERESTS_CLIMBING_GYM','INTERESTS_WATER_SPORTS',
    'INTERESTS_DISC_GOLF','INTERESTS_GOLF_CLINIC','INTERESTS_OUTDOOR_SKILLS'
  );

commit;
