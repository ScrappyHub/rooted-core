-- 20251220002700_backfill_specialty_types_vertical_group.sql
-- SAFETY PATCH: Backfill specialty_types.vertical_group so 20251220002724_remote_schema.sql can set NOT NULL safely.
-- Runs BEFORE 20251220002724_remote_schema.sql (filename order).

begin;

do $$
declare
  v_st regclass;
begin
  v_st := to_regclass('public.specialty_types');

  if v_st is null then
    raise notice 'backfill_specialty_types_vertical_group: public.specialty_types missing; skipping.';
    return;
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='specialty_types'
      and column_name='vertical_group'
  ) then
    raise notice 'backfill_specialty_types_vertical_group: specialty_types.vertical_group missing; skipping.';
    return;
  end if;

  -- Backfill NULL vertical_group.
  -- Prefer vertical_code if present; else fall back to ROOTED_CORE.
  if exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='specialty_types'
      and column_name='vertical_code'
  ) then
    update public.specialty_types
    set vertical_group = coalesce(nullif(btrim(vertical_code), ''), 'ROOTED_CORE')
    where vertical_group is null;
  else
    update public.specialty_types
    set vertical_group = 'ROOTED_CORE'
    where vertical_group is null;
  end if;

end
$$;

commit;