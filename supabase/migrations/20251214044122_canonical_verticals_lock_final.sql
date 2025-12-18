-- 20251214044122_canonical_verticals_lock_final.sql
-- ROOTED CORE: Final lock for canonical_verticals (safe if table not yet created)

begin;

do $$
declare
  _tbl regclass;
begin
  _tbl := to_regclass('public.canonical_verticals');

  -- If the table doesn't exist in this rebuild order, skip safely.
  if _tbl is null then
    return;
  end if;

  -- Drop old trigger if present (must use dynamic SQL so missing table won't error)
  execute 'drop trigger if exists canonical_verticals_read_only on public.canonical_verticals';

  -- Ensure the canonical lock trigger exists (points at your existing function)
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'canonical_verticals_read_only'
      and tgrelid = _tbl
  ) then
    execute '
      create trigger canonical_verticals_read_only
      before insert or update or delete on public.canonical_verticals
      for each row execute function public.prevent_canonical_verticals_changes()
    ';
  end if;
end $$;

commit;
