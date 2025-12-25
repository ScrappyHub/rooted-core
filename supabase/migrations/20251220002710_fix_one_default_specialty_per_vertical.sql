-- 20251220002710_fix_one_default_specialty_per_vertical.sql
-- CANONICAL PATCH: enforce exactly ONE default specialty per vertical_code
-- Goals:
--  1) Never violate unique constraint: vertical_canonical_specialties_one_default_per_vertical
--  2) Collapse duplicates BEFORE attempting any "preferred default" logic
--  3) Avoid CTE scope bugs by keeping cv_hit inside ONE UPDATE statement
--  4) Ensure every vertical_code has exactly one is_default=true (deterministic fallback)
--
-- Assumptions (minimal):
--  - public.vertical_canonical_specialties exists
--  - it has columns: vertical_code, specialty_code
--  - it may have is_default boolean (required for this fix; otherwise we skip)
--  - public.canonical_verticals may exist; if it has (vertical_code, default_specialty) we use it as preference

begin;

do $$
declare
  v_vcs regclass := to_regclass('public.vertical_canonical_specialties');
  v_cv  regclass := to_regclass('public.canonical_verticals');

  has_is_default boolean;
  has_cv_default boolean;
  has_cv_vertical_code boolean;
begin
  -- Guard: VCS table must exist
  if v_vcs is null then
    raise notice 'fix_one_default_specialty_per_vertical: public.vertical_canonical_specialties missing; skipping.';
    return;
  end if;

  -- Guard: is_default column must exist
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

  -------------------------------------------------------------------
  -- STEP 0: normalize nulls (defensive)
  -------------------------------------------------------------------
  update public.vertical_canonical_specialties
  set is_default = false
  where is_default is null;

  -------------------------------------------------------------------
  -- STEP A: collapse ANY duplicates FIRST (prevents unique violation)
  -- Keep exactly ONE existing default per vertical_code (deterministic).
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
  -- STEP B: if canonical_verticals provides a preferred default_specialty,
  -- apply it WITHOUT ever creating >1 true.
  -- (single UPDATE; CTE scope is correct)
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
      with cv_pref as (
        -- Deduplicate canonical_verticals per vertical_code (deterministic)
        select distinct on (cv.vertical_code)
          cv.vertical_code,
          cv.default_specialty
        from public.canonical_verticals cv
        where cv.default_specialty is not null
        order by cv.vertical_code, cv.default_specialty asc
      ),
      cv_hit as (
        -- Only apply where mapping row exists in VCS
        select p.vertical_code, p.default_specialty
        from cv_pref p
        join public.vertical_canonical_specialties vcs
          on vcs.vertical_code = p.vertical_code
         and vcs.specialty_code = p.default_specialty
      )
      update public.vertical_canonical_specialties vcs
      set is_default = (vcs.specialty_code = h.default_specialty)
      from cv_hit h
      where vcs.vertical_code = h.vertical_code
        and (vcs.is_default is distinct from (vcs.specialty_code = h.default_specialty));
    end if;
  end if;

  -------------------------------------------------------------------
  -- STEP C: ensure every vertical_code has a default (pick smallest specialty)
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
  -- STEP D: FINAL SAFETY PASS
  -- If any vertical_code still has >1 default (shouldn't happen), collapse deterministically.
  -------------------------------------------------------------------
  with ranked2 as (
    select
      vcs.vertical_code,
      vcs.specialty_code,
      row_number() over (
        partition by vcs.vertical_code
        order by
          case when vcs.is_default then 0 else 1 end,
          vcs.specialty_code asc
      ) as rn,
      vcs.is_default
    from public.vertical_canonical_specialties vcs
  ),
  bad as (
    select vertical_code
    from public.vertical_canonical_specialties
    where is_default = true
    group by vertical_code
    having count(*) > 1
  )
  update public.vertical_canonical_specialties u
  set is_default = false
  from ranked2 r
  join bad b on b.vertical_code = r.vertical_code
  where u.vertical_code = r.vertical_code
    and u.specialty_code = r.specialty_code
    and u.is_default = true
    and r.rn > 1;

end $$;

commit;