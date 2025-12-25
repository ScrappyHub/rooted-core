-- 20251216204466_specialty_types_timestamps_v1.sql
-- Fix: seed_rooted_platform_canonical_placeholder uses updated_at = now()
-- Ensure specialty_types has created_at + updated_at (idempotent).

begin;

do $$
begin
  if to_regclass('public.specialty_types') is null then
    raise notice 'specialty_types missing; skipping timestamps';
    return;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='specialty_types' and column_name='created_at'
  ) then
    alter table public.specialty_types
      add column created_at timestamptz not null default now();
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='specialty_types' and column_name='updated_at'
  ) then
    alter table public.specialty_types
      add column updated_at timestamptz not null default now();
  end if;
end $$;

commit;