-- 20251217055200_add_interests_vertical.sql
-- CANONICAL PATCH (rewritten via pipeline):
-- Fix: some environments do NOT have specialty_types.vertical_group.
-- We conditionally insert using dynamic SQL based on schema introspection.
-- This preserves canonical pipeline and prevents db reset failures.

begin;

-- ------------------------------------------------------------
-- 1) Ensure the default specialty exists in FK target table
--    canonical_verticals.default_specialty -> specialty_types(code)
-- ------------------------------------------------------------
do $$
declare
  has_vertical_group boolean;
begin
  select exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name   = 'specialty_types'
      and column_name  = 'vertical_group'
  )
  into has_vertical_group;

  if has_vertical_group then
    execute $ins$
      insert into public.specialty_types (code, label, vertical_group)
      values ('INTERESTS_GENERAL', 'Interests (General)', 'INTERESTS')
      on conflict (code) do update
        set label = excluded.label,
            vertical_group = excluded.vertical_group
    $ins$;
  else
    execute $ins$
      insert into public.specialty_types (code, label)
      values ('INTERESTS_GENERAL', 'Interests (General)')
      on conflict (code) do update
        set label = excluded.label
    $ins$;
  end if;
end $$;

-- ------------------------------------------------------------
-- 2) Ensure the INTERESTS vertical exists (canonical table)
-- ------------------------------------------------------------
insert into public.canonical_verticals (code, name, default_specialty)
values ('INTERESTS', 'Interests', 'INTERESTS_GENERAL')
on conflict (code) do update
  set name = excluded.name,
      default_specialty = excluded.default_specialty;

-- ------------------------------------------------------------
-- 3) Ensure INTERESTS is wired into vertical_canonical_specialties
-- ------------------------------------------------------------
insert into public.vertical_canonical_specialties (vertical_code, specialty_code, is_default)
values ('INTERESTS', 'INTERESTS_GENERAL', true)
on conflict (vertical_code, specialty_code) do update
  set is_default = excluded.is_default;

commit;