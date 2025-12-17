begin;

select set_config('rooted.migration_bypass', 'on', true);

-- 1) Add minimum engine state + allowed roles
alter table public.vertical_policy
  add column if not exists min_engine_state engine_state not null default 'community';

alter table public.vertical_policy
  add column if not exists allowed_roles text[] not null default array['individual','vendor','institution','admin'];

-- 2) Set sane defaults: most verticals start at discovery and are broadly allowed
update public.vertical_policy
set min_engine_state = 'discovery'
where min_engine_state = 'community'
  and vertical_code <> 'INTERESTS_HOBBIES';

-- Interests already intentionally higher-capable; keep its min at discovery too
update public.vertical_policy
set min_engine_state = 'discovery'
where vertical_code = 'INTERESTS_HOBBIES';

-- 3) Hard lock META + REGIONAL to institution/admin only
update public.vertical_policy
set
  allowed_roles = array['institution','admin'],
  min_engine_state = 'discovery',
  max_engine_state = 'discovery',
  allows_events = false,
  allows_payments = false,
  allows_b2b = false,
  requires_moderation_for_discovery = false
where vertical_code = 'META_INFRASTRUCTURE';

update public.vertical_policy
set
  allowed_roles = array['institution','admin'],
  min_engine_state = 'discovery',
  -- choose ONE:
  max_engine_state = 'discovery_events',
allows_events = true
  allows_payments = false,
  allows_b2b = false,
  requires_moderation_for_discovery = false
where vertical_code = 'REGIONAL_INTELLIGENCE';

commit;
