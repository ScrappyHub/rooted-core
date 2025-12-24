-- 20251216204460_create_specialty_types.sql
-- Bridge: specialty_types required by 20251216204500_seed_new_vertical_specialties.sql

begin;

create table if not exists public.specialty_types (
  code        text primary key,
  label       text not null,
  description text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.specialty_types enable row level security;

-- Read for authenticated (safe default; writes governed elsewhere)
drop policy if exists specialty_types_read_authenticated_v1 on public.specialty_types;

create policy specialty_types_read_authenticated_v1
on public.specialty_types
for select
to authenticated
using (true);

commit;