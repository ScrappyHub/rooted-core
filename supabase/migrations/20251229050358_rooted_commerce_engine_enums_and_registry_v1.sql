-- ============================================================
-- ROOTED: Commerce engine enums (SAFE)
-- NOTE: Postgres requires enum ADD VALUE be committed before use.
-- This migration MUST NOT wrap in a transaction and MUST NOT use
-- the new enum values in inserts/updates in the same file.
-- ============================================================

-- 1) engine_state: add 'commerce' if missing
do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_enum e on e.enumtypid = t.oid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname='public'
      and t.typname='engine_state'
      and e.enumlabel='commerce'
  ) then
    alter type public.engine_state add value 'commerce';
  end if;
end $$;

-- 2) engine_type: add 'core_commerce' if missing
do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_enum e on e.enumtypid = t.oid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname='public'
      and t.typname='engine_type'
      and e.enumlabel='core_commerce'
  ) then
    alter type public.engine_type add value 'core_commerce';
  end if;
end $$;