-- 20251213170000_canonical_verticals_bypass.sql
-- ROOTED CORE: Allow migration-only bypass for canonical_verticals lock trigger
-- Canonical: still read-only from app/UI. Only migrations can seed.

begin;

-- 0) Canonical lock trigger function (always safe to create)
create or replace function public.prevent_canonical_verticals_changes()
returns trigger
language plpgsql
as $$
begin
  -- ✅ allow only when migration explicitly sets a local bypass flag
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

-- 1) Ensure trigger exists IF (and only if) the table exists
--    IMPORTANT: never cast ::regclass unless to_regclass() proves it exists
do $$
begin
  if to_regclass('public.canonical_verticals') is null then
    -- Fresh local DB: table not created yet; skip safely.
    return;
  end if;

  if not exists (
    select 1
    from pg_trigger
    where tgname = 'prevent_canonical_verticals_changes'
      and tgrelid = 'public.canonical_verticals'::regclass
  ) then
    create trigger prevent_canonical_verticals_changes
    before insert or update or delete on public.canonical_verticals
    for each row execute function public.prevent_canonical_verticals_changes();
  end if;
end $$;

commit;
