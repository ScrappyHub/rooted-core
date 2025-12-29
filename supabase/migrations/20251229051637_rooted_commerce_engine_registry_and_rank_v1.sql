begin;

-- Ensure engine_registry row exists (safe now that enum value is committed)
insert into public.engine_registry (engine_type, is_active, is_assignable_to_entities, notes)
select 'core_commerce'::public.engine_type, true, true, 'Commerce engine: listings + catalog + marketplace lane.'
where not exists (
  select 1 from public.engine_registry er
  where er.engine_type = 'core_commerce'::public.engine_type
);

-- Keep engine_state_rank aligned (safe to replace; avoids nested dollar quoting)
create or replace function public.engine_state_rank(p_state public.engine_state)
returns integer
language plpgsql
stable
as $ENGINE_STATE_RANK$
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
end
$ENGINE_STATE_RANK$;

commit;