-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- ROOTED: STRIP-EXECUTE-DOLLAR-QUOTES-STEP-1P (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
-- ROOTED: AUTO-FIX-EXECUTE-CLOSER-MISMATCH-STEP-1N (canonical)
begin;

-- ------------------------------------------------------------
-- 0) Preconditions (hard fail early if billing_entitlements missing)
-- ------------------------------------------------------------
do $$
begin
  if to_regclass('public.billing_entitlements') is null then
    raise exception 'Missing required table: public.billing_entitlements';
  end if;
end;

-- ------------------------------------------------------------
-- 1) Entitlement key vocabulary (what lanes will reference)
--    NOTE: billing_entitlements is the source of truth for who gets what;
--          entitlement_codes is just the canonical registry of keys.
-- ------------------------------------------------------------
create table if not exists public.entitlement_codes (
  entitlement_code text primary key,
  label text not null,
  description text not null,
  created_at timestamptz not null default now()
);

-- Global entitlements (plans / baseline)
insert into public.entitlement_codes (entitlement_code, label, description)
select x.code, x.label, x.description
from (values
  ('premium',        'Premium',      'Base Premium subscription entitlement.'),
  ('premium_plus',   'Premium Plus', 'Premium Plus subscription entitlement.'),
  ('registration',   'Registration', 'Registration capability entitlement.'),
  ('ticketing',      'Ticketing',    'Ticketing capability entitlement.'),
  ('commerce',       'Commerce',     'Commerce capability entitlement (listings/payments).'),
  ('payments',       'Payments',     'Payments capability entitlement.'),
  ('streaming_music','Streaming Music','Music streaming lane entitlement.'),
  ('streaming_video','Streaming Video','Video streaming lane entitlement.'),
  ('games_library',  'Games Library','Games library entitlement.'),
  ('b2b_bulk',       'B2B Bulk',     'Bulk procurement capability entitlement.'),
  ('b2b_bid',        'B2B Bid',      'RFQ/bidding capability entitlement.'),
  ('b2g_procurement','B2G Procurement','Government procurement capability entitlement.'),
  ('ad_free_media',  'Ad-Free Media','Remove ads in media experiences.')
) x(code,label,description)
where not exists (select 1 from public.entitlement_codes ec where ec.entitlement_code=x.code);

-- Scoped entitlements convention (NO rows inserted here):
--   v:<VERTICAL_CODE>:<CAPABILITY>
-- Examples:
--   v:AGRICULTURE_FOOD:b2b_bulk
--   v:AGRICULTURE_FOOD:b2b_bid
--   v:CONSTRUCTION_BUILT_ENVIRONMENT:b2b_bid
--   v:EDUCATION_WORKFORCE:registration
-- Packs simply grant multiple scoped entitlements.

-- ------------------------------------------------------------
-- 2) Safe role/tier resolver (DB-truth preferred; JWT fallback)
-- ------------------------------------------------------------
create or replace function public._user_role_safe(p_user_id uuid)
returns text
language plpgsql
stable
as $$
declare
  v_role text;
  has_user_tiers boolean := false;
  has_user_id_col boolean := false;
  has_role_col boolean := false;
begin
  -- Prefer public.user_tiers if present
  has_user_tiers := (to_regclass('public.user_tiers') is not null);

  if has_user_tiers then
    select exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name='user_tiers' and column_name='user_id'
    ) into has_user_id_col;

    -- accept common role column names
    select exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name='user_tiers' and column_name in ('role','user_role','account_role')
    ) into has_role_col;

    if has_user_id_col and has_role_col then
      -- Try role, user_role, account_role in order
        select coalesce(t.role, t.user_role, t.account_role)
        from public.user_tiers t
        where t.user_id = $1
        limit 1
      $q$ into v_role using p_user_id;

      if v_role is not null and length(v_role) > 0 then
        return v_role;
      end if;
    end if;
  end if;

  -- JWT fallback (common claim names; safe if absent)
  v_role := coalesce(
    nullif(auth.jwt() ->> 'app_role',''),
    nullif(auth.jwt() ->> 'role',''),
    nullif(auth.jwt() ->> 'user_role',''),
    'individual'
  );

  return v_role;

create or replace function public._user_tier_safe(p_user_id uuid)
returns text
language plpgsql
stable
as $$
declare
  v_tier text;
  has_user_tiers boolean := false;
  has_user_id_col boolean := false;
  has_tier_col boolean := false;
begin
  has_user_tiers := (to_regclass('public.user_tiers') is not null);

  if has_user_tiers then
    select exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name='user_tiers' and column_name='user_id'
    ) into has_user_id_col;

    -- accept common tier column names
    select exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name='user_tiers' and column_name in ('tier','plan_tier','subscription_tier')
    ) into has_tier_col;

    if has_user_id_col and has_tier_col then
        select coalesce(t.tier, t.plan_tier, t.subscription_tier)
        from public.user_tiers t
        where t.user_id = $1
        limit 1
      $q$ into v_tier using p_user_id;

      if v_tier is not null and length(v_tier) > 0 then
        return v_tier;
      end if;
    end if;
  end if;

  -- JWT fallback
  v_tier := coalesce(
    nullif(auth.jwt() ->> 'tier',''),
    nullif(auth.jwt() ->> 'plan_tier',''),
    'free'
  );

  return v_tier;

-- ------------------------------------------------------------
-- 3) Billing-backed entitlement check (THIS is the canonical truth)
-- ------------------------------------------------------------
create or replace function public.user_has_entitlement(p_user_id uuid, p_entitlement_key text)
returns boolean
language sql
stable
as $$
  with ctx as (
    select
      public._user_role_safe(p_user_id) as role,
      public._user_tier_safe(p_user_id) as tier
  )
  select exists (
    select 1
    from public.billing_entitlements be
    cross join ctx
    where be.is_active = true
      and be.entitlement_key = p_entitlement_key
      and (be.role is null or be.role = ctx.role or be.role = 'any')
      and (be.tier is null or be.tier = ctx.tier or be.tier = 'any')
  );

-- ------------------------------------------------------------
-- 4) Lane gating: vertical_lane_enabled()
--    MUST honor:
--      - vertical_lane_policy enabled
--      - required entitlement_key (global or scoped)
--      - vertical_policy ceilings (engine state + allows_payments, etc.)
-- ------------------------------------------------------------
create table if not exists public.vertical_lane_policy (
  vertical_code text not null references public.canonical_verticals(vertical_code) on delete cascade,
  lane_code text not null references public.lane_codes(lane_code) on delete cascade,
  enabled boolean not null default false,
  requires_entitlement_code text null references public.entitlement_codes(entitlement_code),
  requires_moderation boolean not null default true,
  requires_age_gate boolean not null default false,
  notes text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (vertical_code, lane_code)
);

-- Helper: minimal lane->vertical_policy constraint mapping
create or replace function public._lane_allowed_by_vertical_policy(p_vertical_code text, p_lane_code text)
returns boolean
language sql
stable
as $$
  select case
    when vp.vertical_code is null then false
    when p_lane_code in ('payments') then coalesce(vp.allows_payments,false)
    when p_lane_code in ('events') then coalesce(vp.allows_events,false)
    when p_lane_code in ('b2b_bulk','b2b_bid') then coalesce(vp.allows_b2b,false)
    else true
  end
  from public.vertical_policy vp
  where vp.vertical_code = p_vertical_code;

create or replace function public.vertical_lane_enabled(
  p_vertical_code text,
  p_lane_code text,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
as $$
  with pol as (
    select
      vlp.enabled,
      vlp.requires_entitlement_code as req,
      public._lane_allowed_by_vertical_policy(p_vertical_code, p_lane_code) as ok_by_vp
    from public.vertical_lane_policy vlp
    where vlp.vertical_code = p_vertical_code
      and vlp.lane_code = p_lane_code
  )
  select coalesce(pol.enabled,false)
     and coalesce(pol.ok_by_vp,false)
     and (
       pol.req is null
       or public.user_has_entitlement(p_user_id, pol.req)
     )
  from pol;

-- ------------------------------------------------------------
-- 5) OPTIONAL: Scoped entitlement gate helper
--    - Allows lanes to require a scoped entitlement without exploding lane table rows.
--    - Convention: v:<VERTICAL_CODE>:<CAPABILITY>
-- ------------------------------------------------------------
create or replace function public.user_has_scoped_entitlement(
  p_user_id uuid,
  p_vertical_code text,
  p_capability text
)
returns boolean
language sql
stable
as $$
  select public.user_has_entitlement(p_user_id, ('v:' || p_vertical_code || ':' || p_capability));
$$;

commit;