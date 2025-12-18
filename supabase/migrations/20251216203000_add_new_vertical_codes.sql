-- 20251216203000_add_new_vertical_codes.sql
-- ROOTED CORE: Add/seed new vertical codes safely (skip if canonical_verticals not created yet)

begin;

do $$
begin
  -- If table doesn't exist in this rebuild order, skip safely.
  if to_regclass('public.canonical_verticals') is null then
    return;
  end if;

  -- If trigger exists, disable/enable via dynamic SQL so it won't hard-fail on rebuild oddities
  if exists (
    select 1
    from pg_trigger
    where tgname = 'canonical_verticals_read_only'
      and tgrelid = 'public.canonical_verticals'::regclass
  ) then
    execute 'alter table public.canonical_verticals disable trigger canonical_verticals_read_only';
  end if;

  -- (Put your upsert/insert statements here, or keep whatever you already had)
  -- Example pattern:
  -- insert into public.canonical_verticals (vertical_code, label, sort_order, default_specialty)
  -- values (...)
  -- on conflict (vertical_code) do update set ...;

  if exists (
    select 1
    from pg_trigger
    where tgname = 'canonical_verticals_read_only'
      and tgrelid = 'public.canonical_verticals'::regclass
  ) then
    execute 'alter table public.canonical_verticals enable trigger canonical_verticals_read_only';
  end if;
end $$;

commit;
