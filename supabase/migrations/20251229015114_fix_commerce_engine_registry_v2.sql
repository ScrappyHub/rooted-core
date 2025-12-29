begin;

-- Ensure engine_registry has core_commerce
insert into public.engine_registry (engine_type, is_active, is_assignable_to_entities, notes)
select 'core_commerce'::public.engine_type, true, true, 'Commerce engine: isolated marketplace & catalog lane.'
where not exists (
  select 1 from public.engine_registry er
  where er.engine_type = 'core_commerce'::public.engine_type
);

-- Re-assert engine_state_rank with commerce included (canonical ordering)
create or replace function public.engine_state_rank(p_state public.engine_state)
returns integer
language plpgsql
stable
as begin;

-- Add engine_state 'commerce' if missing
do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_enum e on e.enumtypid = t.oid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname='public'
      and t.typname='engine_state'
      and e.enumlabel='commerce'
  ) then
    alter type public.engine_state add value 'commerce';
  end if;
end $$;

-- Add engine_type 'core_commerce' if missing
do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_enum e on e.enumtypid = t.oid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname='public'
      and t.typname='engine_type'
      and e.enumlabel='core_commerce'
  ) then
    alter type public.engine_type add value 'core_commerce';
  end if;
end $$;

commit;
begin
  return case p_state
    when 'discovery'        then 10
    when 'discovery_events' then 20
    when 'registration'     then 30
    when 'commerce'         then 40
    when 'b2b'              then 50
    when 'community'        then 60
    else 999
  end;
end begin;

-- Add engine_state 'commerce' if missing
do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_enum e on e.enumtypid = t.oid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname='public'
      and t.typname='engine_state'
      and e.enumlabel='commerce'
  ) then
    alter type public.engine_state add value 'commerce';
  end if;
end $$;

-- Add engine_type 'core_commerce' if missing
do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_enum e on e.enumtypid = t.oid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname='public'
      and t.typname='engine_type'
      and e.enumlabel='core_commerce'
  ) then
    alter type public.engine_type add value 'core_commerce';
  end if;
end $$;

commit;;

commit;