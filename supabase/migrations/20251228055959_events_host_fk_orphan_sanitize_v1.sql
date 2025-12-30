begin;

-- ============================================================
-- ROOTED: events_host_fk_orphan_sanitize_v1 (DB-TRUTH SAFE PATCH)
-- - Fix: do NOT assume public.events.event_type exists.
-- - Uses schema introspection to find the discriminator column.
-- - NO-OP (with NOTICE) if required columns are missing.
-- ============================================================

do $$
declare
  has_requires_partner boolean;
  has_host_inst boolean;

  col_event_type text; -- which discriminator column exists
begin
  -- Precondition: events table must exist
  if to_regclass('public.events') is null then
    raise exception 'Missing required table: public.events';
  end if;

  -- Check columns that this migration intends to touch
  select exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='events' and column_name='requires_institutional_partner'
  ) into has_requires_partner;

  select exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='events' and column_name='host_institution_id'
  ) into has_host_inst;

  -- Find the event "type discriminator" column (DB-truth)
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='events' and column_name='event_type') then
    col_event_type := 'event_type';
  elsif exists (select 1 from information_schema.columns where table_schema='public' and table_name='events' and column_name='type') then
    col_event_type := 'type';
  elsif exists (select 1 from information_schema.columns where table_schema='public' and table_name='events' and column_name='kind') then
    col_event_type := 'kind';
  elsif exists (select 1 from information_schema.columns where table_schema='public' and table_name='events' and column_name='category') then
    col_event_type := 'category';
  else
    col_event_type := null;
  end if;

  if not has_requires_partner then
    raise notice 'events_host_fk_orphan_sanitize_v1: NO-OP (missing events.requires_institutional_partner)';
    return;
  end if;

  if col_event_type is null then
    raise notice 'events_host_fk_orphan_sanitize_v1: NO-OP (no discriminator column found: event_type/type/kind/category)';
    return;
  end if;

  -- ------------------------------------------------------------
  -- PRE-GUARD:
  -- satisfy large-scale/partner-required CHECK before nulling orphans
  -- If a volunteer event is large-scale AND partner-required, it MUST have host_institution_id.
  -- For rows where host is NULL/ORPHAN, flip requires_institutional_partner=false (minimal + auditable).
  -- ------------------------------------------------------------
  execute format($q$
    update public.events e
    set requires_institutional_partner = false
    where e.%I = 'volunteer'
      and e.requires_institutional_partner = true
      %s
  $q$,
    col_event_type,
    case when has_host_inst then 'and (e.host_institution_id is null)' else '' end
  );

  raise notice 'events_host_fk_orphan_sanitize_v1: applied PRE-GUARD using discriminator column %', col_event_type;

end $$;

commit;