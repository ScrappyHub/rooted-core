-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: ENFORCE-DO-CLOSE-DELIMITER-STEP-1S (canonical)
-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
begin;

-- ============================================================
-- ROOTED: Phase 2 Seed (FK-SAFE + PK-SAFE + PRODUCT_TYPE CHECK-SAFE)
-- ============================================================

-- 0) Preconditions
do $$
begin
  if to_regclass('public.billing_entitlements') is null then
    raise exception 'Missing required table: public.billing_entitlements';
  end if;
  if to_regclass('public.billing_products') is null then
    raise exception 'Missing required table: public.billing_products';
  end if;
  if to_regclass('public.canonical_verticals') is null then
    raise exception 'Missing required table: public.canonical_verticals';
  end if;
  if to_regclass('public.vertical_policy') is null then
    raise exception 'Missing required table: public.vertical_policy';
  end if;
  if to_regclass('public.vertical_lane_policy') is null then
    raise exception 'Missing required table: public.vertical_lane_policy';
  end if;
  if to_regclass('public.lane_codes') is null then
    raise exception 'Missing required table: public.lane_codes';
  end if;
end;
$$;

-- 1) Ensure lane vocabulary (Phase 2)
insert into public.lane_codes (lane_code, label, description)
select x.lane_code, x.label, x.description
from (values
  ('discovery','Discovery','Discovery surfaces, search/browse/listing visibility rules.'),
  ('events','Events','Event listings + publishing + host gating.'),
  ('registration','Registration','Registration flows and compliance gates.'),
  ('ticketing','Ticketing','Tickets issuance/transfer/refund policy enforcement.'),
  ('commerce_listings','Commerce Listings','Listings/catalog/marketplace publishing lane.'),
  ('payments','Payments','Payment processing lane.'),
  ('digital_goods','Digital Goods','Digital purchase + ownership lane.'),
  ('games_library','Games Library','Game library access + downloads.'),
  ('streaming_music','Streaming Music','Music streaming/library lane.'),
  ('streaming_video','Streaming Video','Video streaming/library lane.'),
  ('b2b_bulk','B2B Bulk','Bulk procurement lane.'),
  ('b2b_bid','B2B Bid','RFQs/bidding lane.'),
  ('b2g_procurement','B2G Procurement','Government procurement lane.'),
  ('retail','Retail','Retail purchase/fulfillment lane (future specialization).'),
  ('p2p','P2P','Peer-to-peer transaction lane (future specialization).'),
  ('real_estate','Real Estate','Real estate transaction lane (future specialization).')
) x(lane_code,label,description)
where not exists (select 1 from public.lane_codes lc where lc.lane_code=x.lane_code);

-- 2) Ensure entitlement_codes registry exists + includes lane keys
create table if not exists public.entitlement_codes (
  entitlement_code text primary key,
  label text not null,
  description text not null,
  created_at timestamptz not null default now()
);

insert into public.entitlement_codes (entitlement_code, label, description)
select x.code, x.label, x.description
from (values
  ('free',           'Free',            'Free tier marker entitlement (optional).'),
  ('premium',        'Premium',         'Premium subscription entitlement.'),
  ('premium_plus',   'Premium Plus',    'Premium Plus subscription entitlement.'),

  ('registration',   'Registration',    'Registration capability entitlement.'),
  ('ticketing',      'Ticketing',       'Ticketing capability entitlement.'),
  ('commerce',       'Commerce',        'Commerce capability entitlement (listings).'),
  ('payments',       'Payments',        'Payments capability entitlement.'),

  ('streaming_music','Streaming Music', 'Music streaming lane entitlement.'),
  ('streaming_video','Streaming Video', 'Video streaming/library lane entitlement.'),
  ('games_library',  'Games Library',   'Games library entitlement.'),

  ('b2b_bulk',       'B2B Bulk',        'Bulk procurement capability entitlement.'),
  ('b2b_bid',        'B2B Bid',         'RFQ/bidding capability entitlement.'),
  ('b2g_procurement','B2G Procurement', 'Government procurement capability entitlement.'),

  ('ad_free_media',  'Ad-Free Media',   'Remove ads in media experiences.')
) x(code,label,description)
where not exists (select 1 from public.entitlement_codes ec where ec.entitlement_code=x.code);

-- 3) Normalize lane entitlement requirements (remove premium hardcoding)
update public.vertical_lane_policy
set requires_entitlement_code = 'commerce'
where lane_code = 'commerce_listings'
  and (requires_entitlement_code is null or requires_entitlement_code in ('premium','premium_plus'));

update public.vertical_lane_policy
set requires_entitlement_code = 'payments'
where lane_code = 'payments'
  and (requires_entitlement_code is null or requires_entitlement_code in ('premium','premium_plus'));

-- 4) Ensure baseline lane rows exist for EVERY canonical vertical
insert into public.vertical_lane_policy (
  vertical_code, lane_code, enabled, requires_entitlement_code, requires_moderation, requires_age_gate, notes
)
select
  cv.vertical_code,
  lane.lane_code,
  case
    when lane.lane_code = 'discovery' then true
    when lane.lane_code = 'events' then coalesce(vp.allows_events,false)
    when lane.lane_code = 'commerce_listings' then coalesce(vp.allows_payments,false)
    when lane.lane_code = 'payments' then coalesce(vp.allows_payments,false)
    else false
  end as enabled,
  case
    when lane.lane_code = 'commerce_listings' and coalesce(vp.allows_payments,false) then 'commerce'
    when lane.lane_code = 'payments' and coalesce(vp.allows_payments,false) then 'payments'
    when lane.lane_code = 'ticketing' then 'ticketing'
    when lane.lane_code = 'registration' then 'registration'
    when lane.lane_code = 'b2b_bulk' then 'b2b_bulk'
    when lane.lane_code = 'b2b_bid' then 'b2b_bid'
    when lane.lane_code = 'b2g_procurement' then 'b2g_procurement'
    when lane.lane_code = 'streaming_music' then 'streaming_music'
    when lane.lane_code = 'streaming_video' then 'streaming_video'
    when lane.lane_code = 'games_library' then 'games_library'
    else null
  end as requires_entitlement_code,
  true as requires_moderation,
  (lane.lane_code in ('registration','ticketing')) as requires_age_gate,
  'Phase2 baseline lane row (seeded)' as notes
from public.canonical_verticals cv
join public.vertical_policy vp on vp.vertical_code = cv.vertical_code
cross join (values
  ('discovery'),
  ('events'),
  ('registration'),
  ('ticketing'),
  ('commerce_listings'),
  ('payments'),
  ('digital_goods'),
  ('games_library'),
  ('streaming_music'),
  ('streaming_video'),
  ('b2b_bulk'),
  ('b2b_bid'),
  ('b2g_procurement')
) lane(lane_code)
where not exists (
  select 1 from public.vertical_lane_policy vlp
  where vlp.vertical_code = cv.vertical_code
    and vlp.lane_code = lane.lane_code
);

-- 5) Seed billing_products (display_name + product_type CHECK-safe via constraint introspection)
do $$
declare
  has_display_name boolean;
  has_display_description boolean;
  has_label boolean;
  has_description boolean;
  has_is_active boolean;
  has_active boolean;
  has_metadata boolean;
  has_product_type boolean;

  active_col text;
  must_cols text[];

  -- product_type constraint parsing
  ct text;
  allowed text[];

  pt_base text;
  pt_sub  text;
  pt_cap  text;
  pt_pack text;
begin
  select exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='billing_products' and column_name='display_name'
  ) into has_display_name;

  select exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='billing_products' and column_name in ('display_description','display_desc')
  ) into has_display_description;

  select exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='billing_products' and column_name='label'
  ) into has_label;

  select exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='billing_products' and column_name='description'
  ) into has_description;

  select exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='billing_products' and column_name='is_active'
  ) into has_is_active;

  select exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='billing_products' and column_name='active'
  ) into has_active;

  select exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='billing_products' and column_name='metadata'
  ) into has_metadata;

  select exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='billing_products' and column_name='product_type'
  ) into has_product_type;

  active_col := case when has_is_active then 'is_active' when has_active then 'active' else null end;

  -- Guardrail: fail if there are OTHER NOT NULL/no-default cols we don't know how to satisfy
  select array_agg(column_name order by ordinal_position)
  into must_cols
  from information_schema.columns
  where table_schema='public'
    and table_name='billing_products'
    and is_nullable='NO'
    and column_default is null
    and column_name not in (
      'product_key',
      'display_name','display_description','display_desc',
      'label','description',
      'metadata',
      'is_active','active',
      'product_type'
    );

  if must_cols is not null then
    raise exception 'billing_products has additional NOT NULL columns without defaults that this seed does not know how to satisfy: %', must_cols;
  end if;

  -- If product_type exists, read allowed labels from billing_products_product_type_check (CHECK constraint)
  if has_product_type then
    select pg_get_constraintdef(con.oid)
    into ct
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_namespace nsp on nsp.oid = rel.relnamespace
    where nsp.nspname='public'
      and rel.relname='billing_products'
      and con.conname='billing_products_product_type_check';

    -- Extract all quoted literals from constraint def (e.g., ARRAY['x','y'] or IN ('x','y'))
    if ct is not null then
      select coalesce(array_agg(m[1]), '{}')
      into allowed
      from regexp_matches(ct, '''([^'']+)''', 'g') as m;
    else
      allowed := '{}';
    end if;

    if array_length(allowed,1) is null then
      raise exception 'billing_products.product_type exists but allowed values could not be derived from billing_products_product_type_check';
    end if;

    -- Choose values from allowed set (fallback to first allowed)
    pt_base := coalesce((select v from unnest(allowed) v where v in ('base','core','foundation','rooted_base','product','base_product') limit 1), allowed[1]);
    pt_sub  := coalesce((select v from unnest(allowed) v where v in ('subscription','tier','plan','sub','premium','premium_plus') limit 1), allowed[1]);
    pt_cap  := coalesce((select v from unnest(allowed) v where v in ('capability','feature','module','service','addon_capability') limit 1), allowed[1]);
    pt_pack := coalesce((select v from unnest(allowed) v where v in ('pack','addon','add_on','add-on','bundle') limit 1), allowed[1]);
  end if;

  -- Insert products (idempotent)
  if has_display_name then
    execute format($q$
      insert into public.billing_products (%s)
      select %s
      from (values
        ('rooted_base',        'ROOTED Base',         'Base product marker for foundational capabilities.', '{"seed":"phase2"}'%s),
        ('rooted_premium',     'ROOTED Premium',      'Premium subscription marker.',                      '{"seed":"phase2"}'%s),
        ('rooted_premium_plus','ROOTED Premium Plus', 'Premium Plus subscription marker.',                 '{"seed":"phase2"}'%s),
        ('rooted_commerce',    'ROOTED Commerce',     'Commerce capability marker.',                       '{"seed":"phase2"}'%s),
        ('rooted_payments',    'ROOTED Payments',     'Payments capability marker.',                       '{"seed":"phase2"}'%s),
        ('rooted_streaming',   'ROOTED Streaming',    'Streaming capability marker.',                      '{"seed":"phase2"}'%s),
        ('rooted_games',       'ROOTED Games',        'Games library capability marker.',                  '{"seed":"phase2"}'%s),
        ('pack_b2b_bulk',      'Pack: B2B Bulk',      'Add-on pack for bulk procurement.',                 '{"seed":"phase2","pack":true}'%s),
        ('pack_b2b_bid',       'Pack: B2B Bid',       'Add-on pack for bidding/RFQs.',                     '{"seed":"phase2","pack":true}'%s),
        ('pack_b2g',           'Pack: B2G',           'Add-on pack for government procurement.',           '{"seed":"phase2","pack":true}'%s),
        ('pack_ad_free',       'Pack: Ad-Free',       'Add-on pack for ad-free media.',                    '{"seed":"phase2","pack":true}'%s)
      ) x(product_key, display_name, descr, meta%s)
      where not exists (select 1 from public.billing_products bp where bp.product_key = x.product_key)
    $q$,
      concat_ws(',',
        'product_key',
        'display_name',
        case when has_display_description then 'display_description' else null end,
        case when has_product_type then 'product_type' else null end,
        case when has_label then 'label' else null end,
        case when has_description then 'description' else null end,
        case when active_col is not null then active_col else null end,
        case when has_metadata then 'metadata' else null end
      ),
      concat_ws(',',
        'x.product_key',
        'x.display_name',
        case when has_display_description then 'x.descr' else null end,
        case when has_product_type then 'x.product_type' else null end,
        case when has_label then 'x.display_name' else null end,
        case when has_description then 'x.descr' else null end,
        case when active_col is not null then 'true' else null end,
        case when has_metadata then 'x.meta::jsonb' else null end
      ),
      case when has_product_type then format(', %L', pt_base) else '' end,
      case when has_product_type then format(', %L', pt_sub)  else '' end,
      case when has_product_type then format(', %L', pt_sub)  else '' end,
      case when has_product_type then format(', %L', pt_cap)  else '' end,
      case when has_product_type then format(', %L', pt_cap)  else '' end,
      case when has_product_type then format(', %L', pt_cap)  else '' end,
      case when has_product_type then format(', %L', pt_cap)  else '' end,
      case when has_product_type then format(', %L', pt_pack) else '' end,
      case when has_product_type then format(', %L', pt_pack) else '' end,
      case when has_product_type then format(', %L', pt_pack) else '' end,
      case when has_product_type then format(', %L', pt_pack) else '' end,
      case when has_product_type then ', product_type' else '' end
    );
  else
    -- If no display_name column exists, rely on label/description if present, else product_key only.
    execute $q$
      insert into public.billing_products (product_key)
      select x.product_key
      from (values
        ('rooted_base'),
        ('rooted_premium'),
        ('rooted_premium_plus'),
        ('rooted_commerce'),
        ('rooted_payments'),
        ('rooted_streaming'),
        ('rooted_games'),
        ('pack_b2b_bulk'),
        ('pack_b2b_bid'),
        ('pack_b2g'),
        ('pack_ad_free')
      ) x(product_key)
      where not exists (select 1 from public.billing_products bp where bp.product_key = x.product_key);
$$;
  end if;

end $$;

-- 6) Seed billing_entitlements (ONE ROW PER KEY, PK-safe + FK-safe)
insert into public.billing_entitlements
  (entitlement_key, product_key, role, tier, feature_flags, capabilities, metadata, is_active)
select x.entitlement_key, x.product_key, x.role, x.tier, x.feature_flags::jsonb, x.capabilities::jsonb, x.metadata::jsonb, true
from (values
  ('registration',   'rooted_base',         null, null, '{}' , '{"default_tiers":["free","premium","premium_plus"]}', '{"seed":"phase2","pk_model":"one_row_per_key"}'),
  ('ticketing',      'rooted_base',         null, null, '{}' , '{"default_tiers":["free","premium","premium_plus"]}', '{"seed":"phase2","pk_model":"one_row_per_key"}'),

  ('premium',        'rooted_premium',      null, null, '{}' , '{"default_tiers":["premium"]}',                      '{"seed":"phase2","pk_model":"one_row_per_key"}'),
  ('premium_plus',   'rooted_premium_plus', null, null, '{}' , '{"default_tiers":["premium_plus"]}',                 '{"seed":"phase2","pk_model":"one_row_per_key"}'),

  ('commerce',       'rooted_commerce',     null, null, '{}' , '{"default_tiers":["premium","premium_plus"]}',        '{"seed":"phase2","pk_model":"one_row_per_key"}'),
  ('payments',       'rooted_payments',     null, null, '{}' , '{"default_tiers":["premium","premium_plus"]}',        '{"seed":"phase2","pk_model":"one_row_per_key"}'),

  ('streaming_music','rooted_streaming',    null, null, '{}' , '{"default_tiers":["premium","premium_plus"]}',        '{"seed":"phase2","pk_model":"one_row_per_key"}'),
  ('streaming_video','rooted_streaming',    null, null, '{}' , '{"default_tiers":["premium","premium_plus"]}',        '{"seed":"phase2","pk_model":"one_row_per_key"}'),

  ('games_library',  'rooted_games',        null, null, '{}' , '{"default_tiers":["premium","premium_plus"]}',        '{"seed":"phase2","pk_model":"one_row_per_key"}'),

  ('b2b_bulk',       'pack_b2b_bulk',       null, null, '{}' , '{"default_tiers":["premium_plus"]}',                  '{"seed":"phase2","pack":true,"pk_model":"one_row_per_key"}'),
  ('b2b_bid',        'pack_b2b_bid',        null, null, '{}' , '{"default_tiers":["premium_plus"]}',                  '{"seed":"phase2","pack":true,"pk_model":"one_row_per_key"}'),
  ('b2g_procurement','pack_b2g',            null, null, '{}' , '{"default_roles":["institution"]}',                   '{"seed":"phase2","pack":true,"pk_model":"one_row_per_key"}'),

  ('ad_free_media',  'pack_ad_free',        null, null, '{}' , '{"default_tiers":["premium_plus"]}',                  '{"seed":"phase2","pack":true,"pk_model":"one_row_per_key"}')
) x(entitlement_key,product_key,role,tier,feature_flags,capabilities,metadata)
where not exists (
  select 1 from public.billing_entitlements be
  where be.entitlement_key = x.entitlement_key
);

commit;