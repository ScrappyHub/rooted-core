-- Verify enum values
select t.typname as enum_type, e.enumlabel
from pg_type t
join pg_enum e on e.enumtypid=t.oid
join pg_namespace n on n.oid=t.typnamespace
where n.nspname='public'
  and t.typname in ('engine_state','engine_type')
order by t.typname, e.enumsortorder;

-- Verify verticals exist
select vertical_code, label
from public.canonical_verticals
where vertical_code in (
  'REAL_ESTATE_PROPERTY','RETAIL_CATALOG','P2P_MARKETPLACE',
  'ROOTED_GAMING','MUSIC_CREATORS_MARKET','MUSIC_LIBRARY_STREAMING'
)
order by vertical_code;

-- Verify policies
select vertical_code, min_engine_state, max_engine_state, allows_payments, requires_moderation_for_discovery, is_internal_only
from public.vertical_policy
where vertical_code in ('ROOTED_GAMING','MUSIC_CREATORS_MARKET','MUSIC_LIBRARY_STREAMING')
order by vertical_code;

-- Verify specialty mappings (if mapping table exists)
select *
from public.vertical_canonical_specialties
where vertical_code in ('ROOTED_GAMING','MUSIC_CREATORS_MARKET','REAL_ESTATE_PROPERTY')
limit 50;