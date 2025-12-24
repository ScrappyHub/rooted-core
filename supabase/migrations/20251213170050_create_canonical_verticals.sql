-- 20251213170050_create_canonical_verticals.sql
-- ROOTED CORE: canonical_verticals table (locked; seeded via migrations)
-- Schema aligns with locked 21-vertical system.

begin;

create table if not exists public.canonical_verticals (
  vertical_code      text primary key,
  label              text not null,
  sort_order         integer not null,
  default_specialty  text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

alter table public.canonical_verticals enable row level security;

-- Read-only from app: allow authenticated to SELECT only.
drop policy if exists canonical_verticals_read_authenticated_v1 on public.canonical_verticals;

create policy canonical_verticals_read_authenticated_v1
on public.canonical_verticals
for select
to authenticated
using (true);

commit;