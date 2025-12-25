-- 20251217194000_seed_interests_specialties_v1.sql
-- CANONICAL PATCH (pipeline rewrite - schema agnostic):
-- Fix: specialty_types schema differs across environments (may not have id and other columns).
-- Fix: DO blocks cannot declare procedures → inline schema-aware upsert in a loop.

begin;

do $$
declare
  -- optional columns
  has_label boolean;
  has_vertical_group boolean;
  has_vertical_code boolean;
  has_requires_compliance boolean;
  has_kids_allowed boolean;
  has_default_visibility boolean;
  has_description boolean;

  -- seed loop vars
  seeds jsonb;
  item jsonb;

  p_code text;
  p_label text;
  p_vertical_group text;
  p_vertical_code text;

  cols text[];
  vals text[];
  sets text[];

  col_list text;
  val_list text;
  set_list text;
  sql text;
begin
  -- discover what columns exist
  select exists (select 1 from information_schema.columns where table_schema='public' and table_name='specialty_types' and column_name='label')
    into has_label;

  select exists (select 1 from information_schema.columns where table_schema='public' and table_name='specialty_types' and column_name='vertical_group')
    into has_vertical_group;

  select exists (select 1 from information_schema.columns where table_schema='public' and table_name='specialty_types' and column_name='vertical_code')
    into has_vertical_code;

  select exists (select 1 from information_schema.columns where table_schema='public' and table_name='specialty_types' and column_name='requires_compliance')
    into has_requires_compliance;

  select exists (select 1 from information_schema.columns where table_schema='public' and table_name='specialty_types' and column_name='kids_allowed')
    into has_kids_allowed;

  select exists (select 1 from information_schema.columns where table_schema='public' and table_name='specialty_types' and column_name='default_visibility')
    into has_default_visibility;

  select exists (select 1 from information_schema.columns where table_schema='public' and table_name='specialty_types' and column_name='description')
    into has_description;

  -- canonical interests seed set (small + stable)
  seeds := jsonb_build_array(
    jsonb_build_object('code','INTERESTS_GENERAL','label','Interests (General)','vertical_group','INTERESTS','vertical_code','INTERESTS'),
    jsonb_build_object('code','INTERESTS_HOBBIES','label','Hobbies','vertical_group','INTERESTS','vertical_code','INTERESTS'),
    jsonb_build_object('code','INTERESTS_SPORTS','label','Sports','vertical_group','INTERESTS','vertical_code','INTERESTS'),
    jsonb_build_object('code','INTERESTS_ARTS','label','Arts','vertical_group','INTERESTS','vertical_code','INTERESTS'),
    jsonb_build_object('code','INTERESTS_TECH','label','Technology','vertical_group','INTERESTS','vertical_code','INTERESTS'),
    jsonb_build_object('code','INTERESTS_MUSIC','label','Music','vertical_group','INTERESTS','vertical_code','INTERESTS'),
    jsonb_build_object('code','INTERESTS_FOOD','label','Food','vertical_group','INTERESTS','vertical_code','INTERESTS')
  );

  for item in select * from jsonb_array_elements(seeds)
  loop
    p_code := item->>'code';
    p_label := item->>'label';
    p_vertical_group := item->>'vertical_group';
    p_vertical_code := item->>'vertical_code';

    cols := array['code'];
    vals := array[quote_literal(p_code)];
    sets := array['code = excluded.code'];

    if has_label then
      cols := cols || 'label';
      vals := vals || quote_literal(p_label);
      sets := sets || 'label = excluded.label';
    end if;

    if has_vertical_group then
      cols := cols || 'vertical_group';
      vals := vals || quote_literal(p_vertical_group);
      sets := sets || 'vertical_group = excluded.vertical_group';
    end if;

    if has_vertical_code then
      cols := cols || 'vertical_code';
      vals := vals || quote_literal(p_vertical_code);
      sets := sets || 'vertical_code = excluded.vertical_code';
    end if;

    if has_requires_compliance then
      cols := cols || 'requires_compliance';
      vals := vals || 'false';
      sets := sets || 'requires_compliance = excluded.requires_compliance';
    end if;

    if has_kids_allowed then
      cols := cols || 'kids_allowed';
      vals := vals || 'true';
      sets := sets || 'kids_allowed = excluded.kids_allowed';
    end if;

    if has_default_visibility then
      cols := cols || 'default_visibility';
      vals := vals || quote_literal('public');
      sets := sets || 'default_visibility = excluded.default_visibility';
    end if;

    if has_description then
      cols := cols || 'description';
      vals := vals || quote_literal('Interests specialty seed');
      sets := sets || 'description = excluded.description';
    end if;

    col_list := array_to_string((select array_agg(format('%I', c)) from unnest(cols) c), ', ');
    val_list := array_to_string(vals, ', ');
    set_list := array_to_string(sets, ', ');

    sql := format(
      'insert into public.specialty_types (%s) values (%s) on conflict (code) do update set %s',
      col_list, val_list, set_list
    );

    execute sql;
  end loop;
end $$;

commit;