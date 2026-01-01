-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251213190000_reseed_canonical_verticals_and_specialties.sql
-- ROOTED CORE: Canonical reseed to the locked 21 verticals + rebuild defaults
-- Safe for local rebuilds where some tables may not exist yet.

begin;

-- Enable migration bypass for canonical vertical write trigger
select set_config('rooted.migration_bypass', 'on', true);

do $$
begin
  -- If canonical table isn't present yet, nothing to do.
  if to_regclass('public.canonical_verticals') is null then
    return;
  end if;

  -- If mapping table isn't present yet, skip mapping rebuild.
  -- (We still want canonical_verticals upsert to run if it exists.)
  -- We'll guard mapping actions separately.

  -- 2) Remove any legacy/incorrect canonical_verticals rows (keep only locked 21 codes)
  delete from public.canonical_verticals
  where vertical_code not in (
    'AGRICULTURE_FOOD',
    'ARTS_CULTURE_HERITAGE',
    'COMMUNITY_SERVICES',
    'CONSTRUCTION_BUILT_ENVIRONMENT',
    'EDUCATION_WORKFORCE',
    'EMERGENCY_RESPONSE',
    'ENVIRONMENT_SUSTAINABILITY',
    'EXPERIENCES_RECREATION_TOURISM',
    'GOVERNMENT_CIVIC_SERVICES',
    'HEALTHCARE_COMMUNITY_HEALTH',
    'HOUSING_COMMUNITY_DEV',
    'LAND_NATURAL_RESOURCES',
    'LOGISTICS_TRANSPORT',
    'MANUFACTURING_SUPPLY_CHAIN',
    'MENTAL_HEALTH_WELLNESS',
    'META_INFRASTRUCTURE',
    'PUBLIC_SAFETY_NONPOLICE',
    'REGIONAL_INTELLIGENCE',
    'SCIENCE_MAKER_INNOVATION',
    'TRADES_SKILLS_APPRENTICESHIPS',
    'UTILITIES_ENERGY'
  );

  -- 3) Upsert the locked 21 canonical verticals
  insert into public.canonical_verticals
    (vertical_code, label, sort_order, default_specialty)
  values
    ('AGRICULTURE_FOOD',               'Agriculture & Local Food',             1,  'FARM'),
    ('ARTS_CULTURE_HERITAGE',          'Arts, Culture & Heritage',             2,  'MUSEUM'),
    ('COMMUNITY_SERVICES',             'Community Services',                   3,  'COMMUNITY_CENTER'),
    ('CONSTRUCTION_BUILT_ENVIRONMENT', 'Construction & Built Environment',     4,  'GENERAL_CONTRACTOR'),
    ('EDUCATION_WORKFORCE',            'Education & Workforce',                5,  'AFTER_SCHOOL_PROGRAM'),
    ('EMERGENCY_RESPONSE',             'Emergency Response',                   6,  'FIRE_DEPARTMENT'),
    ('ENVIRONMENT_SUSTAINABILITY',     'Environment & Sustainability',         7,  'CONSERVATION_GROUP'),
    ('EXPERIENCES_RECREATION_TOURISM', 'Experiences, Recreation & Tourism',    8,  'PARKS_AND_RECREATION'),
    ('GOVERNMENT_CIVIC_SERVICES',      'Government & Civic Services',          9,  'TOWN_HALL'),
    ('HEALTHCARE_COMMUNITY_HEALTH',    'Healthcare & Community Health',       10,  'CLINIC'),
    ('HOUSING_COMMUNITY_DEV',          'Housing & Community Development',     11,  'HOUSING_AUTHORITY'),
    ('LAND_NATURAL_RESOURCES',         'Land & Natural Resources',            12,  'LAND_TRUST'),
    ('LOGISTICS_TRANSPORT',            'Logistics & Transport',               13,  'PUBLIC_TRANSIT'),
    ('MANUFACTURING_SUPPLY_CHAIN',     'Manufacturing & Supply Chain',        14,  'ASSEMBLY_PLANT'),
    ('MENTAL_HEALTH_WELLNESS',         'Mental Health & Wellness',            15,  'THERAPY_CENTER'),
    ('META_INFRASTRUCTURE',            'Meta-Infrastructure',                 16,  'META_INFRA'),
    ('PUBLIC_SAFETY_NONPOLICE',        'Public Safety (Non-Police)',          17,  'CAMPUS_SAFETY'),
    ('REGIONAL_INTELLIGENCE',          'Regional Intelligence',               18,  'RESEARCH_CENTER'),
    ('SCIENCE_MAKER_INNOVATION',       'Science, Maker & Innovation',         19,  'MAKER_SPACE'),
    ('TRADES_SKILLS_APPRENTICESHIPS',  'Trades, Skills & Apprenticeships',    20,  'TRADE_SCHOOL'),
    ('UTILITIES_ENERGY',               'Utilities & Energy',                  21,  'ELECTRIC_PROVIDER')
  on conflict (vertical_code) do update
  set
    label             = excluded.label,
    sort_order        = excluded.sort_order,
    default_specialty = excluded.default_specialty;

  -- 1 + 4) Only touch the mapping table if it exists
  if to_regclass('public.vertical_canonical_specialties') is not null then
    -- Reset defaults mapping table
    delete from public.vertical_canonical_specialties;

    -- Rebuild mapping (1 per vertical)
    insert into public.vertical_canonical_specialties (vertical_code, specialty_code)
    select cv.vertical_code, cv.default_specialty
    from public.canonical_verticals cv
    on conflict (vertical_code) do update
    set specialty_code = excluded.specialty_code;
  end if;
end;
$$;

commit;