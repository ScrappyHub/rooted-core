-- 20251220002710_fix_one_default_specialty_per_vertical.sql
-- SAFETY PATCH: Ensure only ONE default specialty per vertical before remote_schema creates unique index.
-- Rule: keep canonical_verticals.default_specialty if present; else keep smallest specialty_code. Set all others is_default=false.

begin;

do $$
declare
  v_vcs regclass;
  v_cv  regclass;
begin
  v_vcs := to_regclass('public.vertical_canonical_specialties');
  v_cv  := to_regclass('public.canonical_verticals');

  if v_vcs is null then
    raise notice 'fix_one_default_specialty_per_vertical: public.vertical_canonical_specialties missing; skipping.';
    return;
  end if;

  -- If is_default column doesn't exist, nothing we can do here safely.
  if not exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='vertical_canonical_specialties'
      and column_name='is_default'
  ) then
    raise notice 'fix_one_default_specialty_per_vertical: is_default column missing; skipping.';
    return;
  end if;

  -- Normalize nulls to false (defensive)
  update public.vertical_canonical_specialties
  set is_default = false
  where is_default is null;

  -- If canonical_verticals exists, prefer its default_specialty as the single default.
  if v_cv is not null and exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='canonical_verticals'
      and column_name='default_specialty'
  ) then
    -- First, clear all defaults for a vertical if there are duplicates,
    -- then set the preferred one to true.
    with dup as (
      select vertical_code
      from public.vertical_canonical_specialties
      where is_default = true
      group by vertical_code
      having count(*) > 1
    )
    update public.vertical_canonical_specialties vcs
    set is_default = false
    from dup
    where vcs.vertical_code = dup.vertical_code
      and vcs.is_default = true;

    -- Now set the preferred default where it exists as a mapping row.
    update public.vertical_canonical_specialties vcs
    set is_default = true
    from public.canonical_verticals cv
    where vcs.vertical_code = cv.vertical_code
      and vcs.specialty_code = cv.default_specialty;

    -- For any vertical that still has ZERO defaults, set one deterministically (smallest specialty_code)
    with no_default as (
      select vcs.vertical_code
      from public.vertical_canonical_specialties vcs
      group by vcs.vertical_code
      having sum(case when vcs.is_default then 1 else 0 end) = 0
    ),
    pick as (
      select distinct on (vcs.vertical_code)
        vcs.vertical_code,
        vcs.specialty_code
      from public.vertical_canonical_specialties vcs
      join no_default nd on nd.vertical_code = vcs.vertical_code
      order by vcs.vertical_code, vcs.specialty_code asc
    )
    update public.vertical_canonical_specialties vcs
    set is_default = true
    from pick
    where vcs.vertical_code = pick.vertical_code
      and vcs.specialty_code = pick.specialty_code;

    -- For any vertical that STILL has duplicates (in case cv.default_specialty mapped to multiple rows somehow),
    -- collapse to one deterministically.
    with ranked as (
      select
        vcs.vertical_code,
        vcs.specialty_code,
        row_number() over (
          partition by vcs.vertical_code
          order by
            case when v_cv is not null and exists (
              select 1 from public.canonical_verticals cv
              where cv.vertical_code = vcs.vertical_code
                and cv.default_specialty = vcs.specialty_code
            ) then 0 else 1 end,
            vcs.specialty_code asc
        ) as rn
      from public.vertical_canonical_specialties vcs
      where vcs.is_default = true
    )
    update public.vertical_canonical_specialties vcs
    set is_default = false
    from ranked r
    where vcs.vertical_code = r.vertical_code
      and vcs.specialty_code = r.specialty_code
      and r.rn > 1;

  else
    -- canonical_verticals missing: just enforce one default by choosing smallest specialty_code per vertical
    with ranked as (
      select
        vertical_code,
        specialty_code,
        row_number() over (partition by vertical_code order by specialty_code asc) as rn
      from public.vertical_canonical_specialties
      where is_default = true
    )
    update public.vertical_canonical_specialties vcs
    set is_default = false
    from ranked r
    where vcs.vertical_code = r.vertical_code
      and vcs.specialty_code = r.specialty_code
      and r.rn > 1;

    -- If any vertical has zero defaults, set one.
    with no_default as (
      select vcs.vertical_code
      from public.vertical_canonical_specialties vcs
      group by vcs.vertical_code
      having sum(case when vcs.is_default then 1 else 0 end) = 0
    ),
    pick as (
      select distinct on (vcs.vertical_code)
        vcs.vertical_code,
        vcs.specialty_code
      from public.vertical_canonical_specialties vcs
      join no_default nd on nd.vertical_code = vcs.vertical_code
      order by vcs.vertical_code, vcs.specialty_code asc
    )
    update public.vertical_canonical_specialties vcs
    set is_default = true
    from pick
    where vcs.vertical_code = pick.vertical_code
      and vcs.specialty_code = pick.specialty_code;
  end if;

end
$$;

commit;