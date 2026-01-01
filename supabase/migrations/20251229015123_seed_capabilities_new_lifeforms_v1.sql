-- ROOTED: ENFORCE-DO-CLOSE-DELIMITER-STEP-1S (canonical)
-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
begin;

do begin;

-- Helper: detect columns (returns bool)
create or replace function public._col_exists(p_table text, p_col text)
returns boolean language sql stable as $$
  select exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name=p_table
      and column_name=p_col
  );
$$;

-- We expect these tables to exist in some form:
-- canonical_specialties
-- vertical_canonical_specialties (mapping vertical_code -> specialty_code)
-- If not present, we hard-stop with a clear error.

do $$
begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='canonical_specialties') then
    raise exception 'Missing table: public.canonical_specialties';
  end if;
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name in ('vertical_canonical_specialties','vertical_canonical_specialties_bak')) then
    raise exception 'Missing mapping table: public.vertical_canonical_specialties (or _bak)';
  end if;
end;
$$;

-- Determine canonical specialty key column name
-- Prefer: specialty_code, else: code
do $$
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
  execute format($f$
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
  $f$,
    kcol,
    case when lcol is null then '' else format(', %I', lcol) end,
    case when dcol is null then '' else format(', %I', dcol) end,
    case when lcol is null then '' else format(', x.code') end,
    case when dcol is null then '' else format(', null') end,
    kcol
  );

end;
$$;

-- Mapping: vertical_canonical_specialties
-- Prefer table vertical_canonical_specialties; fallback to _bak if that's your live table.
do $$
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
  execute format($f$
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
  $f$, map_table, scol, map_table, scol);

end;
$$;

commit;
begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='specialty_capabilities') then
    raise exception 'Missing table: public.specialty_capabilities';
  end if;
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='specialty_capability_grants') then
    raise exception 'Missing table: public.specialty_capability_grants';
  end if;
end begin;

-- Helper: detect columns (returns bool)
create or replace function public._col_exists(p_table text, p_col text)
returns boolean language sql stable as $$
  select exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name=p_table
      and column_name=p_col
  );

-- We expect these tables to exist in some form:
-- canonical_specialties
-- vertical_canonical_specialties (mapping vertical_code -> specialty_code)
-- If not present, we hard-stop with a clear error.

do $$
begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='canonical_specialties') then
    raise exception 'Missing table: public.canonical_specialties';
  end if;
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name in ('vertical_canonical_specialties','vertical_canonical_specialties_bak')) then
    raise exception 'Missing mapping table: public.vertical_canonical_specialties (or _bak)';
  end if;
end;
$$;

-- Determine canonical specialty key column name
-- Prefer: specialty_code, else: code
do $$
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
  execute format($f$
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
  $f$,
    kcol,
    case when lcol is null then '' else format(', %I', lcol) end,
    case when dcol is null then '' else format(', %I', dcol) end,
    case when lcol is null then '' else format(', x.code') end,
    case when dcol is null then '' else format(', null') end,
    kcol
  );

end;
$$;

-- Mapping: vertical_canonical_specialties
-- Prefer table vertical_canonical_specialties; fallback to _bak if that's your live table.
do $$
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
  execute format($f$
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
  $f$, map_table, scol, map_table, scol);

end;
$$;

commit;;

-- We do NOT assume exact columns beyond: (specialty_code?, capability_code?)
-- We'll introspect column names similarly.
create or replace function public._cap_col(p_table text, p_prefer text, p_fallback text)
returns text language sql stable as begin;

-- Helper: detect columns (returns bool)
create or replace function public._col_exists(p_table text, p_col text)
returns boolean language sql stable as $$
  select exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name=p_table
      and column_name=p_col
  );

-- We expect these tables to exist in some form:
-- canonical_specialties
-- vertical_canonical_specialties (mapping vertical_code -> specialty_code)
-- If not present, we hard-stop with a clear error.

do $$
begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='canonical_specialties') then
    raise exception 'Missing table: public.canonical_specialties';
  end if;
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name in ('vertical_canonical_specialties','vertical_canonical_specialties_bak')) then
    raise exception 'Missing mapping table: public.vertical_canonical_specialties (or _bak)';
  end if;
end;
$$;

-- Determine canonical specialty key column name
-- Prefer: specialty_code, else: code
do $$
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
  execute format($f$
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
  $f$,
    kcol,
    case when lcol is null then '' else format(', %I', lcol) end,
    case when dcol is null then '' else format(', %I', dcol) end,
    case when lcol is null then '' else format(', x.code') end,
    case when dcol is null then '' else format(', null') end,
    kcol
  );

end;
$$;

-- Mapping: vertical_canonical_specialties
-- Prefer table vertical_canonical_specialties; fallback to _bak if that's your live table.
do $$
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
  execute format($f$
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
  $f$, map_table, scol, map_table, scol);

end;
$$;

commit;
  select case
    when exists (select 1 from information_schema.columns where table_schema='public' and table_name=p_table and column_name=p_prefer) then p_prefer
    when exists (select 1 from information_schema.columns where table_schema='public' and table_name=p_table and column_name=p_fallback) then p_fallback
    else null;
  end;
begin;

-- Helper: detect columns (returns bool)
create or replace function public._col_exists(p_table text, p_col text)
returns boolean language sql stable as $$
  select exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name=p_table
      and column_name=p_col
  );

-- We expect these tables to exist in some form:
-- canonical_specialties
-- vertical_canonical_specialties (mapping vertical_code -> specialty_code)
-- If not present, we hard-stop with a clear error.

do $$
begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='canonical_specialties') then
    raise exception 'Missing table: public.canonical_specialties';
  end if;
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name in ('vertical_canonical_specialties','vertical_canonical_specialties_bak')) then
    raise exception 'Missing mapping table: public.vertical_canonical_specialties (or _bak)';
  end if;
end;
$$;

-- Determine canonical specialty key column name
-- Prefer: specialty_code, else: code
do $$
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
  execute format($f$
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
  $f$,
    kcol,
    case when lcol is null then '' else format(', %I', lcol) end,
    case when dcol is null then '' else format(', %I', dcol) end,
    case when lcol is null then '' else format(', x.code') end,
    case when dcol is null then '' else format(', null') end,
    kcol
  );

end;
$$;

-- Mapping: vertical_canonical_specialties
-- Prefer table vertical_canonical_specialties; fallback to _bak if that's your live table.
do $$
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
  execute format($f$
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
  $f$, map_table, scol, map_table, scol);

end;
$$;

commit;;

do begin;

-- Helper: detect columns (returns bool)
create or replace function public._col_exists(p_table text, p_col text)
returns boolean language sql stable as $$
  select exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name=p_table
      and column_name=p_col
  );

-- We expect these tables to exist in some form:
-- canonical_specialties
-- vertical_canonical_specialties (mapping vertical_code -> specialty_code)
-- If not present, we hard-stop with a clear error.

do $$
begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='canonical_specialties') then
    raise exception 'Missing table: public.canonical_specialties';
  end if;
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name in ('vertical_canonical_specialties','vertical_canonical_specialties_bak')) then
    raise exception 'Missing mapping table: public.vertical_canonical_specialties (or _bak)';
  end if;
end;
$$;

-- Determine canonical specialty key column name
-- Prefer: specialty_code, else: code
do $$
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
  execute format($f$
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
  $f$,
    kcol,
    case when lcol is null then '' else format(', %I', lcol) end,
    case when dcol is null then '' else format(', %I', dcol) end,
    case when lcol is null then '' else format(', x.code') end,
    case when dcol is null then '' else format(', null') end,
    kcol
  );

end;
$$;

-- Mapping: vertical_canonical_specialties
-- Prefer table vertical_canonical_specialties; fallback to _bak if that's your live table.
do $$
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
  execute format($f$
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
  $f$, map_table, scol, map_table, scol);

end;
$$;

commit;
declare
  spec_col text;
  cap_col text;
  grant_spec_col text;
  grant_cap_col text;
begin
  -- specialty_capabilities: specialty + capability
  spec_col := public._cap_col('specialty_capabilities','specialty_code','code');
  cap_col  := public._cap_col('specialty_capabilities','capability_code','capability');

  if spec_col is null or cap_col is null then
    raise exception 'specialty_capabilities missing required columns';
  end if;

  -- specialty_capability_grants: specialty + capability (+ role/tier/group columns may exist but we won't assume)
  grant_spec_col := public._cap_col('specialty_capability_grants','specialty_code','code');
  grant_cap_col  := public._cap_col('specialty_capability_grants','capability_code','capability');

  if grant_spec_col is null or grant_cap_col is null then
    raise exception 'specialty_capability_grants missing required columns';
  end if;

  -- Seed minimal capability definitions in specialty_capabilities (if your table stores the pairs)
  execute format(C:\rooted-live\rooted-core\supabase\migrations\20251228060000_events_host_and_collaborators_v1.sql$
    insert into public.specialty_capabilities (%I,%I)
    select x.spec, x.cap
    from (values
      -- Commerce listings
      ('PROPERTY_LISTING','listing:create'),
      ('PROPERTY_LISTING','listing:edit'),
      ('PROPERTY_LISTING','listing:publish'),
      ('RETAIL_LISTING','listing:create'),
      ('RETAIL_LISTING','listing:edit'),
      ('RETAIL_LISTING','listing:publish'),
      ('P2P_LISTING','listing:create'),
      ('P2P_LISTING','listing:edit'),
      ('P2P_LISTING','listing:publish'),

      -- Gaming
      ('GAME','game:play'),
      ('GAME','game:save_state'),
      ('GAME_KIDS_APPROVED','game:kids_safe'),
      ('GAME_TEEN_APPROVED','game:teen_safe'),
      ('GAME_ADULT_ONLY','game:nsfw_content'),

      -- Music creators
      ('MUSIC_ARTIST','portfolio:publish'),
      ('MUSIC_PRODUCER','portfolio:publish'),
      ('STUDIO_SESSION','booking:offer'),
      ('MUSIC_LESSONS','booking:offer'),
      ('BEAT_PACK','digital_goods:sell'),
      ('VERSE_FOR_HIRE','service:sell')
    ) as x(spec,cap)
    where not exists (
      select 1 from public.specialty_capabilities sc
      where sc.%I = x.spec and sc.%I = x.cap
    );
  C:\rooted-live\rooted-core\supabase\migrations\20251228060000_events_host_and_collaborators_v1.sql$, spec_col, cap_col, spec_col, cap_col);

  -- Seed grants: keep it conservative (no role guessing beyond your known set)
  -- If your grants table requires extra columns, this will fail loudly (as intended).
  execute format(C:\rooted-live\rooted-core\supabase\migrations\20251228060000_events_host_and_collaborators_v1.sql$
    insert into public.specialty_capability_grants (%I,%I)
    select x.spec, x.cap
    from (values
      ('PROPERTY_LISTING','listing:create'),
      ('RETAIL_LISTING','listing:create'),
      ('P2P_LISTING','listing:create'),

      ('GAME','game:play'),
      ('GAME','game:save_state'),

      ('MUSIC_ARTIST','portfolio:publish'),
      ('MUSIC_PRODUCER','portfolio:publish'),
      ('STUDIO_SESSION','booking:offer'),
      ('MUSIC_LESSONS','booking:offer'),
      ('BEAT_PACK','digital_goods:sell'),
      ('VERSE_FOR_HIRE','service:sell')
    ) as x(spec,cap)
    where not exists (
      select 1 from public.specialty_capability_grants g
      where g.%I = x.spec and g.%I = x.cap
    );
  C:\rooted-live\rooted-core\supabase\migrations\20251228060000_events_host_and_collaborators_v1.sql$, grant_spec_col, grant_cap_col, grant_spec_col, grant_cap_col);

end begin;

-- Helper: detect columns (returns bool)
create or replace function public._col_exists(p_table text, p_col text)
returns boolean language sql stable as $$
  select exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name=p_table
      and column_name=p_col
  );

-- We expect these tables to exist in some form:
-- canonical_specialties
-- vertical_canonical_specialties (mapping vertical_code -> specialty_code)
-- If not present, we hard-stop with a clear error.

do $$
begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='canonical_specialties') then
    raise exception 'Missing table: public.canonical_specialties';
  end if;
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name in ('vertical_canonical_specialties','vertical_canonical_specialties_bak')) then
    raise exception 'Missing mapping table: public.vertical_canonical_specialties (or _bak)';
  end if;
end;
$$;

-- Determine canonical specialty key column name
-- Prefer: specialty_code, else: code
do $$
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
  execute format($f$
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
  $f$,
    kcol,
    case when lcol is null then '' else format(', %I', lcol) end,
    case when dcol is null then '' else format(', %I', dcol) end,
    case when lcol is null then '' else format(', x.code') end,
    case when dcol is null then '' else format(', null') end,
    kcol
  );

end;
$$;

-- Mapping: vertical_canonical_specialties
-- Prefer table vertical_canonical_specialties; fallback to _bak if that's your live table.
do $$
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
  execute format($f$
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
  $f$, map_table, scol, map_table, scol);

end;
$$;

commit;;

commit;