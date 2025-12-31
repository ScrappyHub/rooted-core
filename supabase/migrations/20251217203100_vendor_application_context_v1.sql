-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- ROOTED: AUTO-FIX-NESTED-EXECUTE-DOLLAR-TAG-STEP-1L (canonical)
-- ROOTED: AUTO-FIX-DO-TAG-MISMATCH-STEP-1K (canonical)
-- 20251217203100_vendor_application_context_v1.sql
-- CANONICAL PATCH:
-- Fix: some environments do NOT have public.vendor_applications during clean reset.
-- We only apply vendor_applications patches if the table (and required columns) exist.

begin;

-- ------------------------------------------------------------
-- vendor_applications (schema-aware / safe no-op)
-- ------------------------------------------------------------
do $idx$
declare
  has_table boolean;
  has_user_id boolean;
begin
  has_table := (to_regclass('public.vendor_applications') is not null);

  if not has_table then
    raise notice 'Skipping vendor_applications patches: table public.vendor_applications does not exist in this schema.';
    return;
  end if;

  select exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='vendor_applications'
      and column_name='user_id'
  ) into has_user_id;

  if has_user_id then
    execute $q$
      create index if not exists vendor_applications_user_idx
        on public.vendor_applications(user_id)
    $idx$;
  else
    raise notice 'Skipping vendor_applications_user_idx: column user_id does not exist on public.vendor_applications.';
  end if;
end $$;

commit;