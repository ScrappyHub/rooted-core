begin;

create table if not exists public.canonical_verticals (
  vertical_code text primary key,
  label text not null,
  description text,
  sort_order int not null,
  default_specialty text,
  created_at timestamptz not null default now()
);

commit;

