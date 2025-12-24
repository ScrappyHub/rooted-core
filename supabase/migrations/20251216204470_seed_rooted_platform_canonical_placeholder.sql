-- 20251216204470_seed_rooted_platform_canonical_placeholder.sql
-- Bridge: required placeholder row for specialty_types

begin;

insert into public.specialty_types (code, label, description)
values
  ('ROOTED_PLATFORM_CANONICAL', 'ROOTED Platform Canonical', 'Internal placeholder specialty used for canonical/seed integrity checks.')
on conflict (code) do update
set
  label       = excluded.label,
  description = excluded.description,
  updated_at  = now();

commit;