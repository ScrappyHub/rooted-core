begin;

-- ============================================================
-- Canonical cleanup:
-- 1) Normalize subscription_tier values to canonical tokens
-- 2) Fix user_tiers.feature_flags JSON types (string -> boolean)
-- ============================================================

-- 1) Normalize subscription_tier (keep this permissive, not a hard constraint yet)
update public.user_tiers
set subscription_tier = case
  when subscription_tier is null then null
  when lower(subscription_tier) in ('premium plus','premium-plus','premiumplus','premium_plus') then 'premium_plus'
  when lower(subscription_tier) in ('premium','prem') then 'premium'
  when lower(subscription_tier) in ('free') then 'free'
  else subscription_tier
end
where subscription_tier is not null;

-- 2) Fix feature_flags types (only touches keys if present and currently strings)
-- NOTE: jsonb_typeof(feature_flags->'key') = 'string' catches "true"/"false"
update public.user_tiers
set feature_flags =
  jsonb_set(
    jsonb_set(
      jsonb_set(
        jsonb_set(
          jsonb_set(
            feature_flags,
            '{is_kids_mode}',
            to_jsonb( (lower(coalesce(feature_flags->>'is_kids_mode','false')) = 'true') ),
            true
          ),
          '{can_use_bid_marketplace}',
          to_jsonb( (lower(coalesce(feature_flags->>'can_use_bid_marketplace','false')) = 'true') ),
          true
        ),
        '{can_use_bulk_marketplace}',
        to_jsonb( (lower(coalesce(feature_flags->>'can_use_bulk_marketplace','false')) = 'true') ),
        true
      ),
      '{can_view_basic_analytics}',
      to_jsonb( (lower(coalesce(feature_flags->>'can_view_basic_analytics','false')) = 'true') ),
      true
    ),
    '{can_view_advanced_analytics}',
    to_jsonb( (lower(coalesce(feature_flags->>'can_view_advanced_analytics','false')) = 'true') ),
    true
  )
where feature_flags ?| array[
  'is_kids_mode',
  'can_use_bid_marketplace',
  'can_use_bulk_marketplace',
  'can_view_basic_analytics',
  'can_view_advanced_analytics'
];

commit;