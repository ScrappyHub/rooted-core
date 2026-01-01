-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
begin;

-- ROOTED PATCH: ensure enum value exists before inserting rows that reference it.
-- NOTE: enum ADD VALUE requires commit before use (Postgres safety rule).
do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    join pg_enum e on e.enumtypid = t.oid
    where t.typname = 'engine_type'
      and n.nspname = 'public'
      and e.enumlabel = 'core_commerce'
  ) then
    alter type public.engine_type add value 'core_commerce';
  end if;
end;
-- ROOTED PATCH: txn split for enum safety (Postgres 55P04)
commit;
begin;
-- ROOTED PATCH: ensure enum value exists before inserting rows that reference it.
-- NOTE: enum ADD VALUE requires commit before use (Postgres safety rule).
do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    join pg_enum e on e.enumtypid = t.oid
    where t.typname = 'engine_type'
      and n.nspname = 'public'
      and e.enumlabel = 'core_commerce'
  ) then
    alter type public.engine_type add value 'core_commerce';
  end if;
end;
insert into public.engine_registry (
  engine_type,
  is_active,
  is_assignable_to_entities,
  notes
)
select
  'core_commerce'::public.engine_type,
  true,
  true,
  'Commerce engine: isolated marketplace & catalog lane.'
where not exists (
  select 1 from public.engine_registry
  where engine_type = 'core_commerce'
);

create or replace function public.engine_state_rank(p_state public.engine_state)
returns integer
language plpgsql
stable
as $$
begin
  return case p_state
    when 'discovery'        then 10
    when 'discovery_events' then 20
    when 'registration'     then 30
    when 'commerce'         then 40
    when 'b2b'              then 50
    when 'community'        then 60
    else 999;
  end;
end;
$$;

commit;