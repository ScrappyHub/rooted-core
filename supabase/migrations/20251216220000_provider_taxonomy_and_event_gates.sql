-- 20251216220000_provider_taxonomy_and_event_gates.sql
-- Purpose:
--   1) Enforce provider.primary_vertical + provider.specialty is a VALID canonical pair
--      (prevents "whole vertical" access and prevents UI bypass).
--   2) Enforce event write rules: draft-only for unverified, publish requires moderation approval.
--      Works with or without events.provider_id (auto-detect).
--
-- Assumptions (from your schema):
--   providers.id uuid PK
--   providers.owner_user_id uuid
--   providers.primary_vertical text
--   providers.vertical text (optional secondary/legacy)
--   providers.specialty text
--   providers.is_verified boolean
--   events.created_by uuid
--   events.event_vertical text
--   events.status text
--   events.moderation_status text
--   events.is_volunteer boolean
--   events.is_kids_safe boolean
--
-- Canonical tables:
--   canonical_verticals(vertical_code text PK, default_specialty text FK -> specialty_types.code)
--   specialty_types(code text PK)
--   vertical_canonical_specialties(vertical_code text, specialty_code text, is_default boolean, PK(vertical_code, specialty_code))

begin;

-- ---------------------------------------------------------------------
-- 0) Helper: treat blank strings as NULL in providers fields
-- ---------------------------------------------------------------------
create or replace function public._null_if_blank(p text)
returns text
language sql
immutable
as $$
  select nullif(btrim(p), '');
$$;

-- ---------------------------------------------------------------------
-- 1) PROVIDER TAXONOMY ENFORCEMENT
--    - Ensures: (primary_vertical, specialty) is allowed by vertical_canonical_specialties
--    - Optionally auto-fills specialty to canonical_verticals.default_specialty if missing
-- ---------------------------------------------------------------------
create or replace function public.enforce_provider_vertical_specialty()
returns trigger
language plpgsql
security definer
as $$
declare
  v_vertical text;
  v_specialty text;
  v_default_specialty text;
begin
  -- Normalize blanks -> NULL
  new.primary_vertical := public._null_if_blank(new.primary_vertical);
  new.vertical         := public._null_if_blank(new.vertical);
  new.specialty        := public._null_if_blank(new.specialty);

  -- Prefer primary_vertical; fall back to vertical (legacy)
  v_vertical := coalesce(new.primary_vertical, new.vertical);

  -- If neither is set, we can't validate mapping (leave it to your existing NOT BLANK checks if required)
  if v_vertical is null then
    return new;
  end if;

  -- If specialty is missing, auto-fill from canonical_verticals.default_specialty (cleanest behavior)
  if new.specialty is null then
    select cv.default_specialty
      into v_default_specialty
    from public.canonical_verticals cv
    where cv.vertical_code = v_vertical;

    if v_default_specialty is null then
      raise exception 'Provider vertical "%" is not a valid canonical_verticals.vertical_code', v_vertical;
    end if;

    new.specialty := v_default_specialty;
  end if;

  v_specialty := new.specialty;

  -- Validate the specialty exists in specialty_types (FK already exists, but keep error message clean)
  if not exists (
    select 1 from public.specialty_types st where st.code = v_specialty
  ) then
    raise exception 'Provider specialty "%" is not a valid specialty_types.code', v_specialty;
  end if;

  -- Validate the pair is allowed (THIS is what prevents "whole vertical access")
  if not exists (
    select 1
    from public.vertical_canonical_specialties vcs
    where vcs.vertical_code = v_vertical
      and vcs.specialty_code = v_specialty
  ) then
    raise exception
      'Invalid provider taxonomy: specialty "%" is not allowed for vertical "%"', v_specialty, v_vertical;
  end if;

  return new;
end;
$$;

-- Drop/recreate trigger idempotently
do $$
begin
  if exists (
    select 1 from pg_trigger
    where tgname = 'providers_enforce_vertical_specialty_trg'
  ) then
    drop trigger providers_enforce_vertical_specialty_trg on public.providers;
  end if;

  create trigger providers_enforce_vertical_specialty_trg
  before insert or update of primary_vertical, vertical, specialty
  on public.providers
  for each row
  execute function public.enforce_provider_vertical_specialty();
end $$;

-- ---------------------------------------------------------------------
-- 2) EVENT WRITE GATES (RLS SAFE)
--    - Unverified providers: can create/update drafts only
--    - Publishing requires moderation_status='approved' AND verified provider
--    - Works with or without events.provider_id (auto-detect)
-- ---------------------------------------------------------------------

-- Ensure RLS is on
alter table public.events enable row level security;

-- Helper function: determine if events has provider_id
create or replace function public._events_has_provider_id()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='events'
      and column_name='provider_id'
  );
$$;

-- Helper function: check provider ownership + verification for a given provider_id
create or replace function public._is_owned_provider(p_provider_id uuid)
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1
    from public.providers p
    where p.id = p_provider_id
      and p.owner_user_id = auth.uid()
  );
$$;

create or replace function public._is_verified_owned_provider(p_provider_id uuid)
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1
    from public.providers p
    where p.id = p_provider_id
      and p.owner_user_id = auth.uid()
      and coalesce(p.is_verified,false) = true
  );
$$;

-- Policy creation helper (idempotent)
create or replace function public._create_policy_if_missing(
  p_policy_name text,
  p_cmd text,
  p_using text,
  p_with_check text
) returns void
language plpgsql
security definer
as $$
declare
  v_exists boolean;
  v_sql text;
begin
  select exists(
    select 1
    from pg_policies
    where schemaname='public'
      and tablename='events'
      and policyname = p_policy_name
  ) into v_exists;

  if v_exists then
    return;
  end if;

  v_sql := format(
    'create policy %I on public.events for %s using (%s) with check (%s)',
    p_policy_name, p_cmd, p_using, p_with_check
  );

  execute v_sql;
end;
$$;

-- We will create TWO sets of policies:
--   If events.provider_id exists: strict provider-based enforcement
--   Else: fallback enforcement on events.created_by only (still blocks publish bypass)

do $$
declare
  has_provider_id boolean;
begin
  has_provider_id := public._events_has_provider_id();

  if has_provider_id then
    -- -----------------------------------------------------------------
    -- STRICT MODE (events.provider_id exists)
    -- -----------------------------------------------------------------

    -- INSERT: must be owned provider, event_vertical must match provider vertical, draft-only unless verified+approved
    perform public._create_policy_if_missing(
      'events_insert_owned_provider_strict_v1',
      'insert',
      -- USING doesn't apply to insert; Postgres still requires it syntactically. Set TRUE.
      'true',
      $chk$
        -- created_by must be the logged in user (no spoofing)
        created_by = auth.uid()
        and provider_id is not null
        and public._is_owned_provider(provider_id)
        and exists (
          select 1
          from public.providers p
          where p.id = provider_id
            and (
              -- event vertical must match provider's canonical vertical (prefer primary_vertical)
              event_vertical = coalesce(p.primary_vertical, p.vertical)
            )
        )
        and (
          -- Unverified providers: draft only
          (coalesce((select p.is_verified from public.providers p where p.id = provider_id), false) = false
           and coalesce(status,'') = 'draft')
          or
          -- Verified providers: can create draft/submitted, but publishing requires approval
          (coalesce((select p.is_verified from public.providers p where p.id = provider_id), false) = true
           and (
             coalesce(status,'') <> 'published'
             or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
           )
          )
        )
      $chk$
    );

    -- UPDATE: only for rows you created and provider you own; prevent publish unless verified+approved
    perform public._create_policy_if_missing(
      'events_update_owned_provider_strict_v1',
      'update',
      $using$
        created_by = auth.uid()
        and provider_id is not null
        and public._is_owned_provider(provider_id)
      $using$,
      $chk$
        created_by = auth.uid()
        and provider_id is not null
        and public._is_owned_provider(provider_id)
        and exists (
          select 1
          from public.providers p
          where p.id = provider_id
            and event_vertical = coalesce(p.primary_vertical, p.vertical)
        )
        and (
          -- Unverified providers cannot publish
          (not public._is_verified_owned_provider(provider_id) and coalesce(status,'') = 'draft')
          or
          -- Verified providers still must have approval to publish
          (public._is_verified_owned_provider(provider_id)
            and (
              coalesce(status,'') <> 'published'
              or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
            )
          )
        )
      $chk$
    );

  else
    -- -----------------------------------------------------------------
    -- FALLBACK MODE (no provider_id column)
    -- -----------------------------------------------------------------
    -- Still blocks publish bypass. You can tighten later by adding provider_id.

    perform public._create_policy_if_missing(
      'events_insert_created_by_only_v1',
      'insert',
      'true',
      $chk$
        created_by = auth.uid()
        and (
          coalesce(status,'') <> 'published'
          or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
        )
      $chk$
    );

    perform public._create_policy_if_missing(
      'events_update_created_by_only_v1',
      'update',
      $using$
        created_by = auth.uid()
      $using$,
      $chk$
        created_by = auth.uid()
        and (
          coalesce(status,'') <> 'published'
          or (coalesce(status,'') = 'published' and coalesce(moderation_status,'') = 'approved')
        )
      $chk$
    );
  end if;
end $$;

commit;
