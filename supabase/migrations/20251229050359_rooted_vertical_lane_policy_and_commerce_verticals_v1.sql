-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
begin;

-- ------------------------------------------------------------
-- A) Insert commerce verticals (upsert-style, no hallucinations)
-- ------------------------------------------------------------
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (values
  ('REAL_ESTATE_PROPERTY', 'Real Estate & Property', 'Property listings, rentals, sales, inventory (commerce lane).', 12000, 'ROOTED_PLATFORM_CANONICAL'),
  ('RETAIL_CATALOG',       'Retail Catalog',        'Retail catalogs / storefront discovery (commerce lane).',        12010, 'ROOTED_PLATFORM_CANONICAL'),
  ('P2P_MARKETPLACE',      'P2P Marketplace',       'Peer-to-peer listings / exchanges (commerce lane).',             12020, 'ROOTED_PLATFORM_CANONICAL')
) v(vertical_code,label,description,sort_order,default_specialty)
where not exists (
  select 1 from public.canonical_verticals cv
  where cv.vertical_code = v.vertical_code
);

-- Ensure each commerce vertical has a default specialty mapping (safe with your schema)
insert into public.vertical_canonical_specialties (vertical_code, specialty_code, is_default)
select v.vertical_code, v.specialty_code, true
from (values
  ('REAL_ESTATE_PROPERTY','ROOTED_PLATFORM_CANONICAL'),
  ('RETAIL_CATALOG','ROOTED_PLATFORM_CANONICAL'),
  ('P2P_MARKETPLACE','ROOTED_PLATFORM_CANONICAL')
) v(vertical_code,specialty_code)
where not exists (
  select 1 from public.vertical_canonical_specialties vcs
  where vcs.vertical_code = v.vertical_code
    and vcs.specialty_code = v.specialty_code
);

-- Add vertical_policy for commerce verticals (your existing columns only)
insert into public.vertical_policy (
  vertical_code,
  min_engine_state,
  max_engine_state,
  allows_events,
  allows_payments,
  allows_b2b,
  requires_moderation_for_discovery,
  requires_age_rules_for_registration,
  requires_refund_policy_for_registration,
  requires_waiver_for_registration,
  requires_insurance_for_registration,
  allowed_roles,
  is_internal_only
)
select
  v.vertical_code,
  'discovery'::public.engine_state,
  'commerce'::public.engine_state,
  false,
  true,
  false,
  true,
  true,
  true,
  false,
  false,
  v.allowed_roles::text[],
  false
from (values
  ('REAL_ESTATE_PROPERTY', array['individual','vendor','institution','admin']),
  ('RETAIL_CATALOG',       array['vendor','institution','admin']),
  ('P2P_MARKETPLACE',      array['individual','vendor','institution','admin'])
) v(vertical_code,allowed_roles)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

-- ------------------------------------------------------------
-- B) Lane policy layer (because vertical_policy cannot express tickets/games/streaming/b2g)
-- ------------------------------------------------------------

create table if not exists public.lane_codes (
  lane_code text primary key,
  label text not null,
  description text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.entitlement_codes (
  entitlement_code text primary key,
  label text not null,
  description text not null,
  created_at timestamptz not null default now()
);

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

-- Touch trigger (kept isolated; wonÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢t break if already exists)
create or replace function public._touch_updated_at_lane()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname='trg_vertical_lane_policy_touch') then
    create trigger trg_vertical_lane_policy_touch
    before update on public.vertical_lane_policy
    for each row execute function public._touch_updated_at_lane();
  end if;
end;

-- Seed lane codes (canonical lane vocabulary)
insert into public.lane_codes (lane_code, label, description)
select x.lane_code, x.label, x.description
from (values
  ('discovery','Discovery','Discovery surfaces, search/browse/listing visibility rules.'),
  ('events','Events','Event listings + publishing + host gating.'),
  ('registration','Registration','Registration flows and compliance gates.'),
  ('ticketing','Ticketing','Tickets issuance/transfer/refund policy enforcement.'),
  ('commerce_listings','Commerce Listings','Listings/catalog/marketplace publishing lane.'),
  ('payments','Payments','Payment processing lane (requires commerce).'),
  ('games_library','Games Library','Game library access + downloads.'),
  ('digital_goods','Digital Goods','Digital purchase + ownership lane.'),
  ('streaming_music','Streaming Music','Music streaming/library lane.'),
  ('streaming_video','Streaming Video','Video streaming/library lane.'),
  ('b2b_bulk','B2B Bulk','Bulk procurement lane.'),
  ('b2b_bid','B2B Bid','RFQs/bidding lane.'),
  ('b2g_procurement','B2G Procurement','Government procurement lane.')
) x(lane_code,label,description)
where not exists (select 1 from public.lane_codes lc where lc.lane_code = x.lane_code);

-- Seed entitlement codes (minimal + future-proof)
insert into public.entitlement_codes (entitlement_code, label, description)
select x.entitlement_code, x.label, x.description
from (values
  ('premium','Premium','Premium subscription baseline entitlements.'),
  ('premium_plus','Premium Plus','Premium Plus subscription entitlements.'),
  ('ad_free_media','Ad-Free Media','Removes ads in streaming/media experiences.'),
  ('games_nsfw_opt_in','NSFW Games Opt-In','Explicit opt-in required for NSFW games access.'),
  ('b2b_bulk','B2B Bulk','Bulk procurement capability.'),
  ('b2b_bid','B2B Bid','Bidding/RFQ capability.'),
  ('b2g_procurement','B2G Procurement','Government procurement capability.'),
  ('ticketing','Ticketing','Ticketing capability.'),
  ('registration','Registration','Registration capability.')
) x(entitlement_code,label,description)
where not exists (select 1 from public.entitlement_codes ec where ec.entitlement_code = x.entitlement_code);

-- Safe entitlement resolver that will NOT break if your billing tables differ.
create or replace function public._user_has_entitlement_safe(p_user_id uuid, p_entitlement_code text)
returns boolean
language plpgsql
stable
as $$
declare
  v_has boolean := false;
begin
  -- If you have a table named public.user_entitlements(user_id, entitlement_code), weÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ll use it.
  if to_regclass('public.user_entitlements') is not null then
    execute
      'select exists (select 1 from public.user_entitlements ue where ue.user_id = $1 and ue.entitlement_code = $2)'
    into v_has
    using p_user_id, p_entitlement_code;

    return coalesce(v_has,false);
  end if;

  -- If you instead have a function user_has_entitlement(uuid,text), use it.
  if to_regprocedure('public.user_has_entitlement(uuid,text)') is not null then
    execute 'select public.user_has_entitlement($1,$2)' into v_has using p_user_id, p_entitlement_code;
    return coalesce(v_has,false);
  end if;

  return false;
end $$;

-- Canonical lane check (single source of truth)
create or replace function public.vertical_lane_enabled(p_vertical_code text, p_lane_code text, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
as $$
  select coalesce(vlp.enabled, false)
     and (
       vlp.requires_entitlement_code is null
       or public._user_has_entitlement_safe(p_user_id, vlp.requires_entitlement_code)
     )
  from public.vertical_lane_policy vlp
  where vlp.vertical_code = p_vertical_code
    and vlp.lane_code = p_lane_code;
$$;

-- ------------------------------------------------------------
-- C) Seed baseline lane policy for commerce verticals
-- ------------------------------------------------------------
insert into public.vertical_lane_policy (vertical_code, lane_code, enabled, requires_entitlement_code, requires_moderation, requires_age_gate, notes)
select v.vertical_code, v.lane_code, v.enabled, v.req_ent, v.req_mod, v.req_age, v.notes
from (values
  -- Commerce verticals: listings + payments are ON, require moderation, require age gate for registration-ish surfaces
  ('REAL_ESTATE_PROPERTY','commerce_listings', true,  null,          true,  false, 'Real estate listings lane.'),
  ('REAL_ESTATE_PROPERTY','payments',          true,  'premium',     true,  false, 'Payments allowed only through commerce lane.'),
  ('RETAIL_CATALOG',      'commerce_listings', true,  null,          true,  false, 'Retail catalog publishing.'),
  ('RETAIL_CATALOG',      'payments',          true,  'premium',     true,  false, 'Checkout/transactions.'),
  ('P2P_MARKETPLACE',     'commerce_listings', true,  null,          true,  false, 'P2P listing publishing.'),
  ('P2P_MARKETPLACE',     'payments',          true,  'premium',     true,  false, 'P2P transactions.'),

  -- Placeholder lanes you said are coming (seeded OFF until we wire full engines)
  ('INTERESTS_HOBBIES',    'registration',     false, 'registration', true, true,  'Registration lane placeholder.'),
  ('CELEBRATIONS_EVENTS',  'ticketing',        false, 'ticketing',    true, true,  'Ticketing lane placeholder.')
) v(vertical_code,lane_code,enabled,req_ent,req_mod,req_age,notes)
where not exists (
  select 1 from public.vertical_lane_policy vlp
  where vlp.vertical_code = v.vertical_code and vlp.lane_code = v.lane_code
);

commit;