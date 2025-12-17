begin;

create or replace function public._specialty_capability_allowed(
  p_specialty_code text,
  p_capability_key text
) returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select ec.is_allowed
       from public.specialty_effective_capabilities_v1 ec
      where ec.specialty_code = p_specialty_code
        and ec.capability_key = p_capability_key),
    false
  );
$$;

commit;
