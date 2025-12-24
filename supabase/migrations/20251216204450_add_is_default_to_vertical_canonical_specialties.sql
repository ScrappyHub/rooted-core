-- 20251216204450_add_is_default_to_vertical_canonical_specialties.sql
-- Bridge: add is_default required by later seed migrations

begin;

alter table public.vertical_canonical_specialties
  add column if not exists is_default boolean not null default true;

commit;