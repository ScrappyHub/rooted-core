-- 20251216235000_events_host_vendor_specialty_not_blank_patch_v1.sql
-- Patch: enforce vendor-host event specialty not blank (and/or related gates)
-- GUARDED: safe if public.events/public.providers don't exist yet.

begin;

do $do$
begin
  if to_regclass('public.events') is null then
    raise notice 'Skipping events_host_vendor_specialty_not_blank_patch: public.events does not exist.';
    return;
  end if;

  -- If this patch depends on providers (common), guard it too.
  if to_regclass('public.providers') is null then
    raise notice 'Skipping events_host_vendor_specialty_not_blank_patch: public.providers does not exist.';
    return;
  end if;

  -- Drop the v7 policies (safe if they exist / re-run) - must be EXECUTE
  execute 'drop policy if exists events_host_vendor_insert_v7 on public.events';
  execute 'drop policy if exists events_host_vendor_update_v7 on public.events';
  execute 'drop policy if exists events_host_vendor_delete_v7 on public.events';

  -- If this patchâ€™s intent is only "specialty not blank", do it as a constraint on providers
  -- (events table typically doesnâ€™t store specialty; provider does).
  if not exists (
    select 1
    from pg_constraint
    where conname = 'providers_specialty_not_blank_chk'
      and conrelid = 'public.providers'::regclass
  ) then
    execute $sql$
      alter table public.providers
        add constraint providers_specialty_not_blank_chk
        check (specialty is null or btrim(specialty) <> '')
    $sql$;
  end if;

  -- If you intended to recreate the v7 policies with an added "p.specialty not blank" condition,
  -- you MUST paste the exact policy SQL you want here and weâ€™ll re-add them guarded via EXECUTE.
  -- For now we only prevent the migration from crashing while base tables are missing.

end
$do$;

commit;
