-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251213185955_canonical_verticals_uniques_v1.sql
-- Fix: ON CONFLICT (vertical_code) requires a UNIQUE/PK constraint.
-- Also ensures vertical_canonical_specialties supports ON CONFLICT (vertical_code) used in reseed.

begin;

-- 1) canonical_verticals: ensure vertical_code is unique
do $$
begin
  if to_regclass('public.canonical_verticals') is null then
    raise notice 'canonical_verticals missing; skipping uniques';
    return;
  end if;

  -- Safety: de-dupe in case any duplicates exist
  with d as (
    select ctid,
           row_number() over (
             partition by vertical_code
             order by sort_order nulls last, ctid
           ) as rn
    from public.canonical_verticals
    where vertical_code is not null
  )
  delete from public.canonical_verticals cv
  using d
  where cv.ctid = d.ctid
    and d.rn > 1;

  -- Add UNIQUE constraint if missing
  if not exists (
    select 1
    from pg_constraint
    where conname = 'canonical_verticals_vertical_code_key'
      and conrelid = 'public.canonical_verticals'::regclass
  ) then
    alter table public.canonical_verticals
      add constraint canonical_verticals_vertical_code_key unique (vertical_code);
  end if;
end;
$$;

-- 2) vertical_canonical_specialties: ensure vertical_code is unique
-- (because reseed uses ON CONFLICT (vertical_code))
do $$
begin
  if to_regclass('public.vertical_canonical_specialties') is null then
    raise notice 'vertical_canonical_specialties missing; skipping uniques';
    return;
  end if;

  -- Safety: de-dupe 1-per-vertical_code (matches your "default specialty per vertical" model)
  with d as (
    select ctid,
           row_number() over (partition by vertical_code order by ctid) as rn
    from public.vertical_canonical_specialties
    where vertical_code is not null
  )
  delete from public.vertical_canonical_specialties vcs
  using d
  where vcs.ctid = d.ctid
    and d.rn > 1;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'vertical_canonical_specialties_vertical_code_key'
      and conrelid = 'public.vertical_canonical_specialties'::regclass
  ) then
    alter table public.vertical_canonical_specialties
      add constraint vertical_canonical_specialties_vertical_code_key unique (vertical_code);
  end if;
end;
$$;

commit;