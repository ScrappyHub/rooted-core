-- ROOTED: FIX-HAS-IS-DEFAULT-IF-CLOSURE-STEP-1V (canonical)
-- ROOTED: AUTO-REPAIR-SEED-DO-SQL-CLOSURE-STEP-1U (canonical)
-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ROOTED: STRIP-EXECUTE-DOLLAR-QUOTES-STEP-1P (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
-- ROOTED: AUTO-FIX-EXECUTE-CLOSER-MISMATCH-STEP-1N (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- ROOTED: AUTO-FIX-NESTED-EXECUTE-DOLLAR-TAG-STEP-1L (canonical)
-- ROOTED: AUTO-FIX-DO-TAG-MISMATCH-STEP-1K (canonical)
-- 20251216204500_seed_new_vertical_specialties.sql
-- ROOTED CORE: Seed new vertical specialties (schema-adaptive, safe, idempotent)

begin;

do $sql$
declare
  has_is_default boolean;
  has_table      boolean;
begin
  has_table := to_regclass('public.vertical_canonical_specialties') is not null;

  -- If the mapping table isn't created yet in this rebuild order, skip safely.
  if not has_table then
    return;
  end if;

  -- Does the table have is_default?
  select exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='vertical_canonical_specialties'
      and column_name='is_default'
  )
  into has_is_default;

  -- Ensure placeholder specialty exists; if not, skip safely (or raise if you truly require it).
  if to_regclass('public.specialty_types') is not null then
    if not exists (
      select 1 from public.specialty_types st
      where st.code = 'ROOTED_PLATFORM_CANONICAL'
    ) then
      -- If you want hard-fail, replace RETURN with RAISE EXCEPTION
      return;
    end if;
  else
    return;
  end if;

  -- Insert/Upsert mapping rows
  -- NOTE: adjust the VALUES list below to match what you actually want seeded.
  if has_is_default then
      insert into public.vertical_canonical_specialties (vertical_code, specialty_code, is_default)
      values
        ('META_INFRASTRUCTURE', 'ROOTED_PLATFORM_CANONICAL', true),
        ('REGIONAL_INTELLIGENCE', 'ROOTED_PLATFORM_CANONICAL', true)
      on conflict (vertical_code, specialty_code) do update
      set is_default = excluded.is_default;
  else
      insert into public.vertical_canonical_specialties (vertical_code, specialty_code)
      values
        ('META_INFRASTRUCTURE', 'ROOTED_PLATFORM_CANONICAL'),
        ('REGIONAL_INTELLIGENCE', 'ROOTED_PLATFORM_CANONICAL')
      on conflict (vertical_code, specialty_code) do nothing;
  end if;
end;
    $sql$;
  else
    execute $q$
      insert into public.vertical_canonical_specialties (vertical_code, specialty_code)
      values
        ('META_INFRASTRUCTURE', 'ROOTED_PLATFORM_CANONICAL'),
        ('REGIONAL_INTELLIGENCE', 'ROOTED_PLATFORM_CANONICAL')
      on conflict (vertical_code, specialty_code) do nothing
  end if;
end $$;

commit;