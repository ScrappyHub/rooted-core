-- 20251213185950_create_vertical_canonical_specialties.sql
-- ROOTED CORE: mapping of canonical vertical -> default specialty

begin;

create table if not exists public.vertical_canonical_specialties (
  vertical_code  text primary key,
  specialty_code text not null,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint fk_vcs_vertical
    foreign key (vertical_code)
    references public.canonical_verticals(vertical_code)
    on delete cascade
);

alter table public.vertical_canonical_specialties enable row level security;

-- read-only from app; writable only via migrations / service role paths you define later
drop policy if exists vcs_read_authenticated_v1 on public.vertical_canonical_specialties;

create policy vcs_read_authenticated_v1
on public.vertical_canonical_specialties
for select
to authenticated
using (true);

commit;