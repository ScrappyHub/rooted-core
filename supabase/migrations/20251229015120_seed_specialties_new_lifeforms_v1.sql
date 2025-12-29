begin;

-- Helper: detect columns (returns bool)
create or replace function public._col_exists(p_table text, p_col text)
returns boolean language sql stable as begin;

-- 1) canonical_verticals (uses columns you showed)
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (
  values
    ('MUSIC_CREATORS_MARKET', 'Music Creators Marketplace',
      'Producers/artists portfolio, sessions, lessons, beat packs, verses, licensing, payments.', 14000, 'ROOTED_PLATFORM_CANONICAL'),
    ('MUSIC_LIBRARY_STREAMING', 'Music Library',
      'Future: music library / streaming competitor lane (separate lifeform).', 14010, 'ROOTED_PLATFORM_CANONICAL')
) as v(vertical_code,label,description,sort_order,default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

-- 2) vertical_policy
insert into public.vertical_policy (
  vertical_code,
  min_engine_state,
  max_engine_state,
  allows_events,
  allows_payments,
  allows_b2b,
  requires_moderation_for_discovery,
  requires_age_rules_for_registration,
  requires_refund_policy_for_registration,
  requires_waiver_for_registration,
  requires_insurance_for_registration,
  allowed_roles,
  is_internal_only
)
select
  v.vertical_code,
  v.min_state::public.engine_state,
  v.max_state::public.engine_state,
  v.allows_events,
  v.allows_payments,
  v.allows_b2b,
  v.requires_moderation_for_discovery,
  v.requires_age_rules_for_registration,
  v.requires_refund_policy_for_registration,
  v.requires_waiver_for_registration,
  v.requires_insurance_for_registration,
  v.allowed_roles::jsonb,
  v.is_internal_only
from (
  values
    ('MUSIC_CREATORS_MARKET','discovery','commerce', false, true, true,  true, true, true, false, false, '["individual","vendor","institution","admin"]', false),
    ('MUSIC_LIBRARY_STREAMING','discovery','commerce', false, true, false, true, true, true, false, false, '["individual","admin"]', true)
) as v(vertical_code,min_state,max_state,allows_events,allows_payments,allows_b2b,requires_moderation_for_discovery,requires_age_rules_for_registration,requires_refund_policy_for_registration,requires_waiver_for_registration,requires_insurance_for_registration,allowed_roles,is_internal_only)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

-- 3) market requirements placeholders for music creator commerce
insert into public.vertical_market_requirements (
  vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes
)
select v.vertical_code, v.market_code, v.required_badge_codes, v.require_verified_provider, v.enabled, v.notes
from (
  values
    ('MUSIC_CREATORS_MARKET','listings', array[]::text[], false, true, 'Creator listings lane: portfolios/sessions/packs (badge rules defined later).')
) as v(vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes)
where not exists (
  select 1 from public.vertical_market_requirements vmr
  where vmr.vertical_code = v.vertical_code
    and vmr.market_code = v.market_code
);

commit;
  select exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name=p_table
      and column_name=p_col
  );
begin;

-- 1) canonical_verticals (uses columns you showed)
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (
  values
    ('MUSIC_CREATORS_MARKET', 'Music Creators Marketplace',
      'Producers/artists portfolio, sessions, lessons, beat packs, verses, licensing, payments.', 14000, 'ROOTED_PLATFORM_CANONICAL'),
    ('MUSIC_LIBRARY_STREAMING', 'Music Library',
      'Future: music library / streaming competitor lane (separate lifeform).', 14010, 'ROOTED_PLATFORM_CANONICAL')
) as v(vertical_code,label,description,sort_order,default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

-- 2) vertical_policy
insert into public.vertical_policy (
  vertical_code,
  min_engine_state,
  max_engine_state,
  allows_events,
  allows_payments,
  allows_b2b,
  requires_moderation_for_discovery,
  requires_age_rules_for_registration,
  requires_refund_policy_for_registration,
  requires_waiver_for_registration,
  requires_insurance_for_registration,
  allowed_roles,
  is_internal_only
)
select
  v.vertical_code,
  v.min_state::public.engine_state,
  v.max_state::public.engine_state,
  v.allows_events,
  v.allows_payments,
  v.allows_b2b,
  v.requires_moderation_for_discovery,
  v.requires_age_rules_for_registration,
  v.requires_refund_policy_for_registration,
  v.requires_waiver_for_registration,
  v.requires_insurance_for_registration,
  v.allowed_roles::jsonb,
  v.is_internal_only
from (
  values
    ('MUSIC_CREATORS_MARKET','discovery','commerce', false, true, true,  true, true, true, false, false, '["individual","vendor","institution","admin"]', false),
    ('MUSIC_LIBRARY_STREAMING','discovery','commerce', false, true, false, true, true, true, false, false, '["individual","admin"]', true)
) as v(vertical_code,min_state,max_state,allows_events,allows_payments,allows_b2b,requires_moderation_for_discovery,requires_age_rules_for_registration,requires_refund_policy_for_registration,requires_waiver_for_registration,requires_insurance_for_registration,allowed_roles,is_internal_only)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

-- 3) market requirements placeholders for music creator commerce
insert into public.vertical_market_requirements (
  vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes
)
select v.vertical_code, v.market_code, v.required_badge_codes, v.require_verified_provider, v.enabled, v.notes
from (
  values
    ('MUSIC_CREATORS_MARKET','listings', array[]::text[], false, true, 'Creator listings lane: portfolios/sessions/packs (badge rules defined later).')
) as v(vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes)
where not exists (
  select 1 from public.vertical_market_requirements vmr
  where vmr.vertical_code = v.vertical_code
    and vmr.market_code = v.market_code
);

commit;;

-- We expect these tables to exist in some form:
-- canonical_specialties
-- vertical_canonical_specialties (mapping vertical_code -> specialty_code)
-- If not present, we hard-stop with a clear error.

do begin;

-- 1) canonical_verticals (uses columns you showed)
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (
  values
    ('MUSIC_CREATORS_MARKET', 'Music Creators Marketplace',
      'Producers/artists portfolio, sessions, lessons, beat packs, verses, licensing, payments.', 14000, 'ROOTED_PLATFORM_CANONICAL'),
    ('MUSIC_LIBRARY_STREAMING', 'Music Library',
      'Future: music library / streaming competitor lane (separate lifeform).', 14010, 'ROOTED_PLATFORM_CANONICAL')
) as v(vertical_code,label,description,sort_order,default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

-- 2) vertical_policy
insert into public.vertical_policy (
  vertical_code,
  min_engine_state,
  max_engine_state,
  allows_events,
  allows_payments,
  allows_b2b,
  requires_moderation_for_discovery,
  requires_age_rules_for_registration,
  requires_refund_policy_for_registration,
  requires_waiver_for_registration,
  requires_insurance_for_registration,
  allowed_roles,
  is_internal_only
)
select
  v.vertical_code,
  v.min_state::public.engine_state,
  v.max_state::public.engine_state,
  v.allows_events,
  v.allows_payments,
  v.allows_b2b,
  v.requires_moderation_for_discovery,
  v.requires_age_rules_for_registration,
  v.requires_refund_policy_for_registration,
  v.requires_waiver_for_registration,
  v.requires_insurance_for_registration,
  v.allowed_roles::jsonb,
  v.is_internal_only
from (
  values
    ('MUSIC_CREATORS_MARKET','discovery','commerce', false, true, true,  true, true, true, false, false, '["individual","vendor","institution","admin"]', false),
    ('MUSIC_LIBRARY_STREAMING','discovery','commerce', false, true, false, true, true, true, false, false, '["individual","admin"]', true)
) as v(vertical_code,min_state,max_state,allows_events,allows_payments,allows_b2b,requires_moderation_for_discovery,requires_age_rules_for_registration,requires_refund_policy_for_registration,requires_waiver_for_registration,requires_insurance_for_registration,allowed_roles,is_internal_only)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

-- 3) market requirements placeholders for music creator commerce
insert into public.vertical_market_requirements (
  vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes
)
select v.vertical_code, v.market_code, v.required_badge_codes, v.require_verified_provider, v.enabled, v.notes
from (
  values
    ('MUSIC_CREATORS_MARKET','listings', array[]::text[], false, true, 'Creator listings lane: portfolios/sessions/packs (badge rules defined later).')
) as v(vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes)
where not exists (
  select 1 from public.vertical_market_requirements vmr
  where vmr.vertical_code = v.vertical_code
    and vmr.market_code = v.market_code
);

commit;
begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='canonical_specialties') then
    raise exception 'Missing table: public.canonical_specialties';
  end if;
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name in ('vertical_canonical_specialties','vertical_canonical_specialties_bak')) then
    raise exception 'Missing mapping table: public.vertical_canonical_specialties (or _bak)';
  end if;
end begin;

-- 1) canonical_verticals (uses columns you showed)
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (
  values
    ('MUSIC_CREATORS_MARKET', 'Music Creators Marketplace',
      'Producers/artists portfolio, sessions, lessons, beat packs, verses, licensing, payments.', 14000, 'ROOTED_PLATFORM_CANONICAL'),
    ('MUSIC_LIBRARY_STREAMING', 'Music Library',
      'Future: music library / streaming competitor lane (separate lifeform).', 14010, 'ROOTED_PLATFORM_CANONICAL')
) as v(vertical_code,label,description,sort_order,default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

-- 2) vertical_policy
insert into public.vertical_policy (
  vertical_code,
  min_engine_state,
  max_engine_state,
  allows_events,
  allows_payments,
  allows_b2b,
  requires_moderation_for_discovery,
  requires_age_rules_for_registration,
  requires_refund_policy_for_registration,
  requires_waiver_for_registration,
  requires_insurance_for_registration,
  allowed_roles,
  is_internal_only
)
select
  v.vertical_code,
  v.min_state::public.engine_state,
  v.max_state::public.engine_state,
  v.allows_events,
  v.allows_payments,
  v.allows_b2b,
  v.requires_moderation_for_discovery,
  v.requires_age_rules_for_registration,
  v.requires_refund_policy_for_registration,
  v.requires_waiver_for_registration,
  v.requires_insurance_for_registration,
  v.allowed_roles::jsonb,
  v.is_internal_only
from (
  values
    ('MUSIC_CREATORS_MARKET','discovery','commerce', false, true, true,  true, true, true, false, false, '["individual","vendor","institution","admin"]', false),
    ('MUSIC_LIBRARY_STREAMING','discovery','commerce', false, true, false, true, true, true, false, false, '["individual","admin"]', true)
) as v(vertical_code,min_state,max_state,allows_events,allows_payments,allows_b2b,requires_moderation_for_discovery,requires_age_rules_for_registration,requires_refund_policy_for_registration,requires_waiver_for_registration,requires_insurance_for_registration,allowed_roles,is_internal_only)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

-- 3) market requirements placeholders for music creator commerce
insert into public.vertical_market_requirements (
  vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes
)
select v.vertical_code, v.market_code, v.required_badge_codes, v.require_verified_provider, v.enabled, v.notes
from (
  values
    ('MUSIC_CREATORS_MARKET','listings', array[]::text[], false, true, 'Creator listings lane: portfolios/sessions/packs (badge rules defined later).')
) as v(vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes)
where not exists (
  select 1 from public.vertical_market_requirements vmr
  where vmr.vertical_code = v.vertical_code
    and vmr.market_code = v.market_code
);

commit;;

-- Determine canonical specialty key column name
-- Prefer: specialty_code, else: code
do begin;

-- 1) canonical_verticals (uses columns you showed)
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (
  values
    ('MUSIC_CREATORS_MARKET', 'Music Creators Marketplace',
      'Producers/artists portfolio, sessions, lessons, beat packs, verses, licensing, payments.', 14000, 'ROOTED_PLATFORM_CANONICAL'),
    ('MUSIC_LIBRARY_STREAMING', 'Music Library',
      'Future: music library / streaming competitor lane (separate lifeform).', 14010, 'ROOTED_PLATFORM_CANONICAL')
) as v(vertical_code,label,description,sort_order,default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

-- 2) vertical_policy
insert into public.vertical_policy (
  vertical_code,
  min_engine_state,
  max_engine_state,
  allows_events,
  allows_payments,
  allows_b2b,
  requires_moderation_for_discovery,
  requires_age_rules_for_registration,
  requires_refund_policy_for_registration,
  requires_waiver_for_registration,
  requires_insurance_for_registration,
  allowed_roles,
  is_internal_only
)
select
  v.vertical_code,
  v.min_state::public.engine_state,
  v.max_state::public.engine_state,
  v.allows_events,
  v.allows_payments,
  v.allows_b2b,
  v.requires_moderation_for_discovery,
  v.requires_age_rules_for_registration,
  v.requires_refund_policy_for_registration,
  v.requires_waiver_for_registration,
  v.requires_insurance_for_registration,
  v.allowed_roles::jsonb,
  v.is_internal_only
from (
  values
    ('MUSIC_CREATORS_MARKET','discovery','commerce', false, true, true,  true, true, true, false, false, '["individual","vendor","institution","admin"]', false),
    ('MUSIC_LIBRARY_STREAMING','discovery','commerce', false, true, false, true, true, true, false, false, '["individual","admin"]', true)
) as v(vertical_code,min_state,max_state,allows_events,allows_payments,allows_b2b,requires_moderation_for_discovery,requires_age_rules_for_registration,requires_refund_policy_for_registration,requires_waiver_for_registration,requires_insurance_for_registration,allowed_roles,is_internal_only)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

-- 3) market requirements placeholders for music creator commerce
insert into public.vertical_market_requirements (
  vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes
)
select v.vertical_code, v.market_code, v.required_badge_codes, v.require_verified_provider, v.enabled, v.notes
from (
  values
    ('MUSIC_CREATORS_MARKET','listings', array[]::text[], false, true, 'Creator listings lane: portfolios/sessions/packs (badge rules defined later).')
) as v(vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes)
where not exists (
  select 1 from public.vertical_market_requirements vmr
  where vmr.vertical_code = v.vertical_code
    and vmr.market_code = v.market_code
);

commit;
declare
  kcol text;
  lcol text;
  dcol text;
begin
  if public._col_exists('canonical_specialties','specialty_code') then
    kcol := 'specialty_code';
  elsif public._col_exists('canonical_specialties','code') then
    kcol := 'code';
  else
    raise exception 'canonical_specialties missing (specialty_code|code)';
  end if;

  if public._col_exists('canonical_specialties','label') then
    lcol := 'label';
  elsif public._col_exists('canonical_specialties','name') then
    lcol := 'name';
  else
    lcol := null;
  end if;

  if public._col_exists('canonical_specialties','description') then
    dcol := 'description';
  else
    dcol := null;
  end if;

  -- Insert specialties (dynamic SQL)
  -- Commerce
  execute format(C:\rooted-live\rooted-core\supabase\migrations\20251228060000_events_host_and_collaborators_v1.sql$
    insert into public.canonical_specialties (%I%s%s)
    select x.code%s%s
    from (values
      ('PROPERTY_LISTING'),
      ('RETAIL_LISTING'),
      ('P2P_LISTING'),
      ('GAME'),
      ('GAME_KIDS_APPROVED'),
      ('GAME_TEEN_APPROVED'),
      ('GAME_ADULT_ONLY'),
      ('MUSIC_ARTIST'),
      ('MUSIC_PRODUCER'),
      ('STUDIO_SESSION'),
      ('MUSIC_LESSONS'),
      ('BEAT_PACK'),
      ('VERSE_FOR_HIRE')
    ) as x(code)
    where not exists (
      select 1 from public.canonical_specialties cs where cs.%I = x.code
    );
  C:\rooted-live\rooted-core\supabase\migrations\20251228060000_events_host_and_collaborators_v1.sql$,
    kcol,
    case when lcol is null then '' else format(', %I', lcol) end,
    case when dcol is null then '' else format(', %I', dcol) end,
    case when lcol is null then '' else format(', x.code') end,
    case when dcol is null then '' else format(', null') end,
    kcol
  );

end begin;

-- 1) canonical_verticals (uses columns you showed)
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (
  values
    ('MUSIC_CREATORS_MARKET', 'Music Creators Marketplace',
      'Producers/artists portfolio, sessions, lessons, beat packs, verses, licensing, payments.', 14000, 'ROOTED_PLATFORM_CANONICAL'),
    ('MUSIC_LIBRARY_STREAMING', 'Music Library',
      'Future: music library / streaming competitor lane (separate lifeform).', 14010, 'ROOTED_PLATFORM_CANONICAL')
) as v(vertical_code,label,description,sort_order,default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

-- 2) vertical_policy
insert into public.vertical_policy (
  vertical_code,
  min_engine_state,
  max_engine_state,
  allows_events,
  allows_payments,
  allows_b2b,
  requires_moderation_for_discovery,
  requires_age_rules_for_registration,
  requires_refund_policy_for_registration,
  requires_waiver_for_registration,
  requires_insurance_for_registration,
  allowed_roles,
  is_internal_only
)
select
  v.vertical_code,
  v.min_state::public.engine_state,
  v.max_state::public.engine_state,
  v.allows_events,
  v.allows_payments,
  v.allows_b2b,
  v.requires_moderation_for_discovery,
  v.requires_age_rules_for_registration,
  v.requires_refund_policy_for_registration,
  v.requires_waiver_for_registration,
  v.requires_insurance_for_registration,
  v.allowed_roles::jsonb,
  v.is_internal_only
from (
  values
    ('MUSIC_CREATORS_MARKET','discovery','commerce', false, true, true,  true, true, true, false, false, '["individual","vendor","institution","admin"]', false),
    ('MUSIC_LIBRARY_STREAMING','discovery','commerce', false, true, false, true, true, true, false, false, '["individual","admin"]', true)
) as v(vertical_code,min_state,max_state,allows_events,allows_payments,allows_b2b,requires_moderation_for_discovery,requires_age_rules_for_registration,requires_refund_policy_for_registration,requires_waiver_for_registration,requires_insurance_for_registration,allowed_roles,is_internal_only)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

-- 3) market requirements placeholders for music creator commerce
insert into public.vertical_market_requirements (
  vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes
)
select v.vertical_code, v.market_code, v.required_badge_codes, v.require_verified_provider, v.enabled, v.notes
from (
  values
    ('MUSIC_CREATORS_MARKET','listings', array[]::text[], false, true, 'Creator listings lane: portfolios/sessions/packs (badge rules defined later).')
) as v(vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes)
where not exists (
  select 1 from public.vertical_market_requirements vmr
  where vmr.vertical_code = v.vertical_code
    and vmr.market_code = v.market_code
);

commit;;

-- Mapping: vertical_canonical_specialties
-- Prefer table vertical_canonical_specialties; fallback to _bak if that's your live table.
do begin;

-- 1) canonical_verticals (uses columns you showed)
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (
  values
    ('MUSIC_CREATORS_MARKET', 'Music Creators Marketplace',
      'Producers/artists portfolio, sessions, lessons, beat packs, verses, licensing, payments.', 14000, 'ROOTED_PLATFORM_CANONICAL'),
    ('MUSIC_LIBRARY_STREAMING', 'Music Library',
      'Future: music library / streaming competitor lane (separate lifeform).', 14010, 'ROOTED_PLATFORM_CANONICAL')
) as v(vertical_code,label,description,sort_order,default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

-- 2) vertical_policy
insert into public.vertical_policy (
  vertical_code,
  min_engine_state,
  max_engine_state,
  allows_events,
  allows_payments,
  allows_b2b,
  requires_moderation_for_discovery,
  requires_age_rules_for_registration,
  requires_refund_policy_for_registration,
  requires_waiver_for_registration,
  requires_insurance_for_registration,
  allowed_roles,
  is_internal_only
)
select
  v.vertical_code,
  v.min_state::public.engine_state,
  v.max_state::public.engine_state,
  v.allows_events,
  v.allows_payments,
  v.allows_b2b,
  v.requires_moderation_for_discovery,
  v.requires_age_rules_for_registration,
  v.requires_refund_policy_for_registration,
  v.requires_waiver_for_registration,
  v.requires_insurance_for_registration,
  v.allowed_roles::jsonb,
  v.is_internal_only
from (
  values
    ('MUSIC_CREATORS_MARKET','discovery','commerce', false, true, true,  true, true, true, false, false, '["individual","vendor","institution","admin"]', false),
    ('MUSIC_LIBRARY_STREAMING','discovery','commerce', false, true, false, true, true, true, false, false, '["individual","admin"]', true)
) as v(vertical_code,min_state,max_state,allows_events,allows_payments,allows_b2b,requires_moderation_for_discovery,requires_age_rules_for_registration,requires_refund_policy_for_registration,requires_waiver_for_registration,requires_insurance_for_registration,allowed_roles,is_internal_only)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

-- 3) market requirements placeholders for music creator commerce
insert into public.vertical_market_requirements (
  vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes
)
select v.vertical_code, v.market_code, v.required_badge_codes, v.require_verified_provider, v.enabled, v.notes
from (
  values
    ('MUSIC_CREATORS_MARKET','listings', array[]::text[], false, true, 'Creator listings lane: portfolios/sessions/packs (badge rules defined later).')
) as v(vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes)
where not exists (
  select 1 from public.vertical_market_requirements vmr
  where vmr.vertical_code = v.vertical_code
    and vmr.market_code = v.market_code
);

commit;
declare
  map_table text := 'vertical_canonical_specialties';
  scol text;
begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='vertical_canonical_specialties') then
    map_table := 'vertical_canonical_specialties_bak';
  end if;

  -- mapping specialty column: specialty_code or canonical_specialty_code
  if public._col_exists(map_table,'specialty_code') then
    scol := 'specialty_code';
  elsif public._col_exists(map_table,'canonical_specialty_code') then
    scol := 'canonical_specialty_code';
  else
    raise exception '% missing (specialty_code|canonical_specialty_code)', map_table;
  end if;

  -- Insert vertical->specialty maps
  execute format(C:\rooted-live\rooted-core\supabase\migrations\20251228060000_events_host_and_collaborators_v1.sql$
    insert into public.%I (vertical_code, %I)
    select v.vertical_code, v.spec
    from (values
      ('REAL_ESTATE_PROPERTY','PROPERTY_LISTING'),
      ('RETAIL_CATALOG','RETAIL_LISTING'),
      ('P2P_MARKETPLACE','P2P_LISTING'),
      ('ROOTED_GAMING','GAME'),
      ('ROOTED_GAMING','GAME_KIDS_APPROVED'),
      ('ROOTED_GAMING','GAME_TEEN_APPROVED'),
      ('ROOTED_GAMING','GAME_ADULT_ONLY'),
      ('MUSIC_CREATORS_MARKET','MUSIC_ARTIST'),
      ('MUSIC_CREATORS_MARKET','MUSIC_PRODUCER'),
      ('MUSIC_CREATORS_MARKET','STUDIO_SESSION'),
      ('MUSIC_CREATORS_MARKET','MUSIC_LESSONS'),
      ('MUSIC_CREATORS_MARKET','BEAT_PACK'),
      ('MUSIC_CREATORS_MARKET','VERSE_FOR_HIRE')
    ) as v(vertical_code, spec)
    where not exists (
      select 1 from public.%I m
      where m.vertical_code = v.vertical_code and m.%I = v.spec
    );
  C:\rooted-live\rooted-core\supabase\migrations\20251228060000_events_host_and_collaborators_v1.sql$, map_table, scol, map_table, scol);

end begin;

-- 1) canonical_verticals (uses columns you showed)
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (
  values
    ('MUSIC_CREATORS_MARKET', 'Music Creators Marketplace',
      'Producers/artists portfolio, sessions, lessons, beat packs, verses, licensing, payments.', 14000, 'ROOTED_PLATFORM_CANONICAL'),
    ('MUSIC_LIBRARY_STREAMING', 'Music Library',
      'Future: music library / streaming competitor lane (separate lifeform).', 14010, 'ROOTED_PLATFORM_CANONICAL')
) as v(vertical_code,label,description,sort_order,default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

-- 2) vertical_policy
insert into public.vertical_policy (
  vertical_code,
  min_engine_state,
  max_engine_state,
  allows_events,
  allows_payments,
  allows_b2b,
  requires_moderation_for_discovery,
  requires_age_rules_for_registration,
  requires_refund_policy_for_registration,
  requires_waiver_for_registration,
  requires_insurance_for_registration,
  allowed_roles,
  is_internal_only
)
select
  v.vertical_code,
  v.min_state::public.engine_state,
  v.max_state::public.engine_state,
  v.allows_events,
  v.allows_payments,
  v.allows_b2b,
  v.requires_moderation_for_discovery,
  v.requires_age_rules_for_registration,
  v.requires_refund_policy_for_registration,
  v.requires_waiver_for_registration,
  v.requires_insurance_for_registration,
  v.allowed_roles::jsonb,
  v.is_internal_only
from (
  values
    ('MUSIC_CREATORS_MARKET','discovery','commerce', false, true, true,  true, true, true, false, false, '["individual","vendor","institution","admin"]', false),
    ('MUSIC_LIBRARY_STREAMING','discovery','commerce', false, true, false, true, true, true, false, false, '["individual","admin"]', true)
) as v(vertical_code,min_state,max_state,allows_events,allows_payments,allows_b2b,requires_moderation_for_discovery,requires_age_rules_for_registration,requires_refund_policy_for_registration,requires_waiver_for_registration,requires_insurance_for_registration,allowed_roles,is_internal_only)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

-- 3) market requirements placeholders for music creator commerce
insert into public.vertical_market_requirements (
  vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes
)
select v.vertical_code, v.market_code, v.required_badge_codes, v.require_verified_provider, v.enabled, v.notes
from (
  values
    ('MUSIC_CREATORS_MARKET','listings', array[]::text[], false, true, 'Creator listings lane: portfolios/sessions/packs (badge rules defined later).')
) as v(vertical_code, market_code, required_badge_codes, require_verified_provider, enabled, notes)
where not exists (
  select 1 from public.vertical_market_requirements vmr
  where vmr.vertical_code = v.vertical_code
    and vmr.market_code = v.market_code
);

commit;;

commit;