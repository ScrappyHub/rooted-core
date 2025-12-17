begin;

create or replace function public.prevent_canonical_verticals_changes()
returns trigger
language plpgsql
as $$
begin
  if current_setting('rooted.migration_bypass', true) = 'on' then
    if tg_op = 'DELETE' then
      return old;
    else
      return new;
    end if;
  end if;

  raise exception 'canonical_verticals is read-only – modify via migration, not from the app.';
end;
$$;

drop trigger if exists canonical_verticals_read_only on public.canonical_verticals;

create trigger canonical_verticals_read_only
before insert or update or delete on public.canonical_verticals
for each row execute function public.prevent_canonical_verticals_changes();

commit;
