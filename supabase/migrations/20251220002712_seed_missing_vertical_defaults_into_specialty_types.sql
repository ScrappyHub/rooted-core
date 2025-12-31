-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251220002712_seed_missing_vertical_defaults_into_specialty_types.sql
-- SAFETY PATCH: Ensure canonical_verticals.default_specialty values exist in specialty_types(code)
-- Must run BEFORE 20251220002724_remote_schema.sql validates canonical_verticals_default_specialty_fkey

begin;

do $$
declare
  v_cv regclass;
  v_st regclass;
  has_vertical_group boolean;
begin
  v_cv := to_regclass('public.canonical_verticals');
  v_st := to_regclass('public.specialty_types');

  if v_cv is null then
    raise notice 'seed_missing_vertical_defaults: public.canonical_verticals missing; skipping.';
    return;
  end if;

  if v_st is null then
    raise notice 'seed_missing_vertical_defaults: public.specialty_types missing; skipping.';
    return;
  end if;

  select exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='specialty_types'
      and column_name='vertical_group'
  ) into has_vertical_group;

  if has_vertical_group then
    insert into public.specialty_types (code, label, vertical_group)
    select
      cv.default_specialty,
      initcap(replace(cv.default_specialty, '_', ' ')),
      'MIGRATED_DEFAULTS'
    from public.canonical_verticals cv
    where cv.default_specialty is not null
      and btrim(cv.default_specialty) <> ''
      and not exists (
        select 1 from public.specialty_types st
        where st.code = cv.default_specialty
      )
    on conflict (code) do update
      set label = excluded.label;
  else
    insert into public.specialty_types (code, label)
    select
      cv.default_specialty,
      initcap(replace(cv.default_specialty, '_', ' '))
    from public.canonical_verticals cv
    where cv.default_specialty is not null
      and btrim(cv.default_specialty) <> ''
      and not exists (
        select 1 from public.specialty_types st
        where st.code = cv.default_specialty
      )
    on conflict (code) do update
      set label = excluded.label;
  end if;
end;
$$;

commit;