-- 20251216204465_specialty_types_add_description_v1.sql
-- Fix: seed_rooted_platform_canonical_placeholder expects specialty_types.description
-- This migration ensures the column exists BEFORE the seed runs.

begin;

do $$
begin
  if to_regclass('public.specialty_types') is null then
    raise notice 'specialty_types missing; skipping add description';
    return;
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='specialty_types'
      and column_name='description'
  ) then
    alter table public.specialty_types
      add column description text;
  end if;
end $$;

commit;