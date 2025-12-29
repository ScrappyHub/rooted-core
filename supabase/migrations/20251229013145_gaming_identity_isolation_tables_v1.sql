begin;

-- Gamer account is the ONLY identity visible in gaming.
-- It is not linked publicly to provider/vendor/institution identities.
create table if not exists public.gamer_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique, -- 1 gamer account per auth user
  screen_name text not null unique,
  status text not null default 'active', -- active/suspended/etc
  age_lane text not null default 'adult', -- kid/teen/adult (derived/enforced elsewhere)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Public gamer profile: intentionally minimal.
create table if not exists public.gamer_profiles_public (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  display_name text not null, -- usually screen_name copy
  bio text null,
  avatar_url text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Private stats/progress: never public.
create table if not exists public.gamer_private_stats (
  gamer_id uuid primary key references public.gamer_accounts(id) on delete cascade,
  total_play_time_seconds bigint not null default 0,
  save_state jsonb not null default '{}'::jsonb,
  nsfw_activity_hidden boolean not null default true, -- hard safety default
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- timestamps
create or replace function public._touch_updated_at()
returns trigger language plpgsql as begin;

-- vertical_policy columns you showed earlier include:
-- vertical_code, min_engine_state, max_engine_state,
-- allows_events, allows_payments, allows_b2b,
-- requires_moderation_for_discovery,
-- requires_age_rules_for_registration,
-- requires_refund_policy_for_registration,
-- requires_waiver_for_registration,
-- requires_insurance_for_registration,
-- allowed_roles, is_internal_only

-- Rooted Gaming (public, but isolated identity; enforced in its own tables + RLS below)
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
  'ROOTED_GAMING',
  'discovery'::public.engine_state,
  'registration'::public.engine_state, -- gaming has discovery->registration flows (accounts, approvals, sessions)
  false,
  true,   -- payments allowed later (cosmetics/subs), but not forced here
  false,
  true,   -- moderation for game catalog + listings
  true,   -- age rules required (kids/teens/adults)
  true,   -- if paid flows exist later, refunds must exist
  false,
  false,
  '["individual","admin"]'::jsonb,
  false
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = 'ROOTED_GAMING'
);

-- Future marketplaces: internal-only placeholders so nothing leaks early
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
  '["admin"]'::jsonb,
  true
from (values
  ('DELIVERY_LOGISTICS_MARKET'),
  ('ETHICAL_FOOD_MARKET')
) v(vertical_code)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

commit;
begin
  new.updated_at = now();
  return new;
end begin;

-- vertical_policy columns you showed earlier include:
-- vertical_code, min_engine_state, max_engine_state,
-- allows_events, allows_payments, allows_b2b,
-- requires_moderation_for_discovery,
-- requires_age_rules_for_registration,
-- requires_refund_policy_for_registration,
-- requires_waiver_for_registration,
-- requires_insurance_for_registration,
-- allowed_roles, is_internal_only

-- Rooted Gaming (public, but isolated identity; enforced in its own tables + RLS below)
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
  'ROOTED_GAMING',
  'discovery'::public.engine_state,
  'registration'::public.engine_state, -- gaming has discovery->registration flows (accounts, approvals, sessions)
  false,
  true,   -- payments allowed later (cosmetics/subs), but not forced here
  false,
  true,   -- moderation for game catalog + listings
  true,   -- age rules required (kids/teens/adults)
  true,   -- if paid flows exist later, refunds must exist
  false,
  false,
  '["individual","admin"]'::jsonb,
  false
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = 'ROOTED_GAMING'
);

-- Future marketplaces: internal-only placeholders so nothing leaks early
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
  '["admin"]'::jsonb,
  true
from (values
  ('DELIVERY_LOGISTICS_MARKET'),
  ('ETHICAL_FOOD_MARKET')
) v(vertical_code)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

commit;;

do begin;

-- vertical_policy columns you showed earlier include:
-- vertical_code, min_engine_state, max_engine_state,
-- allows_events, allows_payments, allows_b2b,
-- requires_moderation_for_discovery,
-- requires_age_rules_for_registration,
-- requires_refund_policy_for_registration,
-- requires_waiver_for_registration,
-- requires_insurance_for_registration,
-- allowed_roles, is_internal_only

-- Rooted Gaming (public, but isolated identity; enforced in its own tables + RLS below)
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
  'ROOTED_GAMING',
  'discovery'::public.engine_state,
  'registration'::public.engine_state, -- gaming has discovery->registration flows (accounts, approvals, sessions)
  false,
  true,   -- payments allowed later (cosmetics/subs), but not forced here
  false,
  true,   -- moderation for game catalog + listings
  true,   -- age rules required (kids/teens/adults)
  true,   -- if paid flows exist later, refunds must exist
  false,
  false,
  '["individual","admin"]'::jsonb,
  false
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = 'ROOTED_GAMING'
);

-- Future marketplaces: internal-only placeholders so nothing leaks early
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
  '["admin"]'::jsonb,
  true
from (values
  ('DELIVERY_LOGISTICS_MARKET'),
  ('ETHICAL_FOOD_MARKET')
) v(vertical_code)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

commit;
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_accounts_touch') then
    create trigger trg_gamer_accounts_touch
    before update on public.gamer_accounts
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_profiles_public_touch') then
    create trigger trg_gamer_profiles_public_touch
    before update on public.gamer_profiles_public
    for each row execute function public._touch_updated_at();
  end if;

  if not exists (select 1 from pg_trigger where tgname = 'trg_gamer_private_stats_touch') then
    create trigger trg_gamer_private_stats_touch
    before update on public.gamer_private_stats
    for each row execute function public._touch_updated_at();
  end if;
end begin;

-- vertical_policy columns you showed earlier include:
-- vertical_code, min_engine_state, max_engine_state,
-- allows_events, allows_payments, allows_b2b,
-- requires_moderation_for_discovery,
-- requires_age_rules_for_registration,
-- requires_refund_policy_for_registration,
-- requires_waiver_for_registration,
-- requires_insurance_for_registration,
-- allowed_roles, is_internal_only

-- Rooted Gaming (public, but isolated identity; enforced in its own tables + RLS below)
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
  'ROOTED_GAMING',
  'discovery'::public.engine_state,
  'registration'::public.engine_state, -- gaming has discovery->registration flows (accounts, approvals, sessions)
  false,
  true,   -- payments allowed later (cosmetics/subs), but not forced here
  false,
  true,   -- moderation for game catalog + listings
  true,   -- age rules required (kids/teens/adults)
  true,   -- if paid flows exist later, refunds must exist
  false,
  false,
  '["individual","admin"]'::jsonb,
  false
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = 'ROOTED_GAMING'
);

-- Future marketplaces: internal-only placeholders so nothing leaks early
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
  '["admin"]'::jsonb,
  true
from (values
  ('DELIVERY_LOGISTICS_MARKET'),
  ('ETHICAL_FOOD_MARKET')
) v(vertical_code)
where not exists (
  select 1 from public.vertical_policy vp
  where vp.vertical_code = v.vertical_code
);

commit;;

commit;