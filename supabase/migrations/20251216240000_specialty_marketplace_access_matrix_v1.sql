-- 20251216240000_specialty_marketplace_access_matrix_v1.sql
-- Specialty Marketplace Access Matrix + capability resolver
-- SAFE: can run before providers exists (resolver uses dynamic SQL)

begin;

-- If this file defines matrix tables, keep them schema-safe:
create table if not exists public.specialty_marketplace_access_matrix (
  capability_key text not null,
  marketplace_key text not null,
  is_allowed boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (capability_key, marketplace_key)
);

-- ---------------------------------------------------------------------
-- D) Effective capability resolver
-- ---------------------------------------------------------------------
-- NOTE: Must NOT reference public.providers directly at CREATE time.
-- We use dynamic SQL so the function can be created before providers exists.
create or replace function public._capability_allowed_for_provider(
  p_provider_id uuid,
  p_capability_key text
) returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_allowed boolean;
begin
  -- If base tables aren't present yet, fail closed
  if to_regclass('public.providers') is null then
    return false;
  end if;

  if to_regclass('public.specialty_capability_grants') is null
     or to_regclass('public.specialty_capabilities') is null then
    return false;
  end if;

  -- Resolve: specialty override (grant) wins, else fall back to default_allowed, else false
  execute $q$
    select coalesce(
      (
        select g.is_allowed
        from public.providers p
        join public.specialty_capability_grants g
          on g.specialty_code = p.specialty
        where p.id = $1
          and g.capability_key = $2
        limit 1
      ),
      (
        select c.default_allowed
        from public.specialty_capabilities c
        where c.capability_key = $2
        limit 1
      ),
      false
    )
  $q$
  into v_allowed
  using p_provider_id, p_capability_key;

  return coalesce(v_allowed, false);
end;
$$;

commit;
