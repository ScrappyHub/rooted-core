begin;

-- Add engine_state 'commerce' if missing
do )
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
end );

-- Add engine_type 'core_commerce' if missing
do )
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
end );

commit;