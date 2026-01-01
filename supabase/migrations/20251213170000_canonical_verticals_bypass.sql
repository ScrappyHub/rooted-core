-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251213170000_canonical_verticals_bypass.sql
-- ROOTED CORE: Allow migration-only bypass for canonical_verticals lock trigger
-- Canonical: still read-only from app/UI. Only migrations can seed.

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

  raise exception 'canonical_verticals is read-only Ã¢â‚¬â€œ modify via migration, not from the app.';
end;
$$;

do $$
declare
  _tbl regclass;
begin
  _tbl := to_regclass('public.canonical_verticals');

  if _tbl is null then
    return;
  end if;

  if not exists (
    select 1
    from pg_trigger
    where tgname = 'prevent_canonical_verticals_changes'
      and tgrelid = _tbl
  ) then
    create trigger prevent_canonical_verticals_changes
    before insert or update or delete on public.canonical_verticals
    for each row execute function public.prevent_canonical_verticals_changes();
  end if;
end;
$$;

commit;