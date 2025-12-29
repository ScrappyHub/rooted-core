-- ============================================================
-- commerce_enums_v1
-- ============================================================

do \$\$
begin
  if not exists (
    select 1 from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    where t.typname = 'engine_state'
      and e.enumlabel = 'commerce'
  ) then
    alter type public.engine_state add value 'commerce';
  end if;
end
\$\$;

do \$\$
begin
  if not exists (
    select 1 from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    where t.typname = 'engine_type'
      and e.enumlabel = 'core_commerce'
  ) then
    alter type public.engine_type add value 'core_commerce';
  end if;
end
\$\$;