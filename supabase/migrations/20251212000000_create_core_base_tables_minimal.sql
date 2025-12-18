-- 20251212000000_create_core_base_tables_minimal.sql
-- Minimal base schema so later policy/taxonomy migrations can apply cleanly.
-- This repo previously had policy migrations that referenced providers/events
-- but did not create those tables.

begin;

-- ---------------------------------------------------------------------------
-- A) Providers (minimal columns used by later migrations)
-- ---------------------------------------------------------------------------
create table if not exists public.providers (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null,
  vertical text,
  primary_vertical text,
  specialty text,
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- B) Events (minimal columns used by later RLS migrations)
-- ---------------------------------------------------------------------------
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null,
  host_vendor_id uuid,
  host_institution_id uuid,
  event_vertical text,
  status text not null default 'draft',
  moderation_status text not null default 'pending',
  is_volunteer boolean not null default false,
  is_large_scale_volunteer boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Optional FK for vendor host (safe because providers is created above)
do $$
begin
  if to_regclass('public.providers') is not null and to_regclass('public.events') is not null then
    if not exists (
      select 1 from pg_constraint
      where conname = 'events_host_vendor_fkey'
        and conrelid = 'public.events'::regclass
    ) then
      alter table public.events
        add constraint events_host_vendor_fkey
        foreign key (host_vendor_id)
        references public.providers(id)
        on delete set null;
    end if;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- C) Taxonomy objects that later migrations reference
-- ---------------------------------------------------------------------------

-- Some later migrations reference public.vertical_canonical_specialties directly
create table if not exists public.vertical_canonical_specialties (
  vertical_code text not null,
  specialty_code text not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (vertical_code, specialty_code)
);

-- Some later migrations seed from a view named public.vertical_specialties_v1
create or replace view public.vertical_specialties_v1 as
select
  vcs.vertical_code,
  vcs.specialty_code,
  vcs.is_default
from public.vertical_canonical_specialties vcs;

-- Some earlier enforcement migrations referenced specialty_types;
-- keep a minimal table so FK/constraints can be added later if needed.
create table if not exists public.specialty_types (
  code text primary key,
  label text,
  created_at timestamptz not null default now()
);

commit;
