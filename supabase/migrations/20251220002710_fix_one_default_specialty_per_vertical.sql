-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251220002710_fix_one_default_specialty_per_vertical.sql
-- CANONICAL PATCH: enforce exactly ONE is_default=true per vertical_code
-- Why this version:
--  - Avoids UNIQUE violations by never turning a new default true while another is still true
--  - No CTE scope bugs (each statement carries its own CTE)
--  - Deterministic fallback: smallest specialty_code

begin;

do $$
declare
  v_vcs regclass := to_regclass('public.vertical_canonical_specialties');
  v_cv  regclass := to_regclass('public.canonical_verticals');

  has_is_default boolean;
  has_cv_default boolean;
  has_cv_vertical_code boolean;
begin
  if v_vcs is null then
    raise notice 'fix_one_default_specialty_per_vertical: public.vertical_canonical_specialties missing; skipping.';
    return;
  end if;

  select exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='vertical_canonical_specialties'
      and column_name='is_default'
  ) into has_is_default;

  if not has_is_default then
    raise notice 'fix_one_default_specialty_per_vertical: is_default column missing; skipping.';
    return;
  end if;

  -- Normalize nulls
  update public.vertical_canonical_specialties
  set is_default = false
  where is_default is null;

  -------------------------------------------------------------------
  -- STEP A: collapse duplicates among existing defaults (safe)
  -------------------------------------------------------------------
  with ranked as (
    select
      vcs.vertical_code,
      vcs.specialty_code,
      row_number() over (
        partition by vcs.vertical_code
        order by vcs.specialty_code asc
      ) as rn
    from public.vertical_canonical_specialties vcs
    where vcs.is_default = true
  )
  update public.vertical_canonical_specialties u
  set is_default = false
  from ranked r
  where u.vertical_code = r.vertical_code
    and u.specialty_code = r.specialty_code
    and r.rn > 1;

  -------------------------------------------------------------------
  -- STEP B: apply canonical_verticals preferred default (TWO-PHASE)
  -------------------------------------------------------------------
  if v_cv is not null then
    select exists (
      select 1
      from information_schema.columns
      where table_schema='public'
        and table_name='canonical_verticals'
        and column_name='default_specialty'
    ) into has_cv_default;

    select exists (
      select 1
      from information_schema.columns
      where table_schema='public'
        and table_name='canonical_verticals'
        and column_name='vertical_code'
    ) into has_cv_vertical_code;

    if has_cv_default and has_cv_vertical_code then

      -- B1) CLEAR defaults for verticals that have a valid preferred mapping row (cv_hit)
      with cv_pref as (
        select distinct on (cv.vertical_code)
          cv.vertical_code,
          cv.default_specialty
        from public.canonical_verticals cv
        where cv.default_specialty is not null
        order by cv.vertical_code, cv.default_specialty asc
      ),
      cv_hit as (
        select p.vertical_code, p.default_specialty
        from cv_pref p
        join public.vertical_canonical_specialties vcs
          on vcs.vertical_code = p.vertical_code
         and vcs.specialty_code = p.default_specialty
      )
      update public.vertical_canonical_specialties vcs
      set is_default = false
      from cv_hit h
      where vcs.vertical_code = h.vertical_code
        and vcs.is_default = true;

      -- B2) SET the preferred row true (now guaranteed no other true remains for that vertical_code)
      with cv_pref as (
        select distinct on (cv.vertical_code)
          cv.vertical_code,
          cv.default_specialty
        from public.canonical_verticals cv
        where cv.default_specialty is not null
        order by cv.vertical_code, cv.default_specialty asc
      ),
      cv_hit as (
        select p.vertical_code, p.default_specialty
        from cv_pref p
        join public.vertical_canonical_specialties vcs
          on vcs.vertical_code = p.vertical_code
         and vcs.specialty_code = p.default_specialty
      )
      update public.vertical_canonical_specialties vcs
      set is_default = true
      from cv_hit h
      where vcs.vertical_code = h.vertical_code
        and vcs.specialty_code = h.default_specialty
        and vcs.is_default is distinct from true;

    end if;
  end if;

  -------------------------------------------------------------------
  -- STEP C: ensure every vertical_code has exactly one default
  -- (only fills gaps; never creates duplicates)
  -------------------------------------------------------------------
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

  -------------------------------------------------------------------
  -- STEP D: last-resort collapse if anything still has >1 default
  -------------------------------------------------------------------
  with ranked2 as (
    select
      vcs.vertical_code,
      vcs.specialty_code,
      row_number() over (
        partition by vcs.vertical_code
        order by vcs.specialty_code asc
      ) as rn
    from public.vertical_canonical_specialties vcs
    where vcs.is_default = true
  )
  update public.vertical_canonical_specialties u
  set is_default = false
  from ranked2 r
  where u.vertical_code = r.vertical_code
    and u.specialty_code = r.specialty_code
    and r.rn > 1;

end;
$$;

commit;