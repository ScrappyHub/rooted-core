begin;

-- A) Insert missing verticals (idempotent)
insert into public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
select v.vertical_code, v.label, v.description, v.sort_order, v.default_specialty
from (values
  ('MUSIC_CREATORS',        'Music Creators',         'Creator tooling, sessions, releases, studio listings, lessons.',                      12100, 'ROOTED_PLATFORM_CANONICAL'),
  ('STREAMING_MUSIC',       'Streaming Music',        'Music streaming library and playback experiences.',                                 12110, 'ROOTED_PLATFORM_CANONICAL'),
  ('STREAMING_MEDIA',       'Streaming Media',        'Streaming media library (broad). Lanes can specialize (e.g., streaming_video).',    12120, 'ROOTED_PLATFORM_CANONICAL'),
  ('RELIGION_SPIRITUALITY', 'Religion & Spirituality','Faith communities, institutions, history, events (governed, moderated).',            12300, 'ROOTED_PLATFORM_CANONICAL'),
  ('FORGOTTEN_HISTORY',     'Forgotten History',      'Local & regional forgotten history, archives, landmarks, narratives (moderated).',   12310, 'ROOTED_PLATFORM_CANONICAL')
) v(vertical_code,label,description,sort_order,default_specialty)
where not exists (select 1 from public.canonical_verticals cv where cv.vertical_code=v.vertical_code);

-- B) Default specialty mapping (idempotent)
insert into public.vertical_canonical_specialties (vertical_code, specialty_code, is_default)
select x.vertical_code, x.specialty_code, true
from (values
  ('MUSIC_CREATORS',        'ROOTED_PLATFORM_CANONICAL'),
  ('STREAMING_MUSIC',       'ROOTED_PLATFORM_CANONICAL'),
  ('STREAMING_MEDIA',       'ROOTED_PLATFORM_CANONICAL'),
  ('RELIGION_SPIRITUALITY', 'ROOTED_PLATFORM_CANONICAL'),
  ('FORGOTTEN_HISTORY',     'ROOTED_PLATFORM_CANONICAL')
) x(vertical_code,specialty_code)
where not exists (
  select 1 from public.vertical_canonical_specialties vcs
  where vcs.vertical_code=x.vertical_code and vcs.specialty_code=x.specialty_code
);

-- C) vertical_policy rows (idempotent)
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
  p.vertical_code,
  p.min_state::public.engine_state,
  p.max_state::public.engine_state,
  p.allows_events,
  p.allows_payments,
  p.allows_b2b,
  p.requires_mod,
  p.req_age_rules,
  p.req_refund,
  p.req_waiver,
  p.req_insurance,
  p.allowed_roles::text[],
  p.is_internal
from (values
  ('MUSIC_CREATORS',        'discovery','registration', true,  true,  false, true,  true,  true,  false, false, array['individual','vendor','institution','admin'], false),
  ('STREAMING_MUSIC',       'discovery','commerce',     false, true,  false, true,  true,  true,  false, false, array['individual','vendor','institution','admin'], false),
  ('STREAMING_MEDIA',       'discovery','commerce',     false, true,  false, true,  true,  true,  false, false, array['individual','vendor','institution','admin'], false),
  ('RELIGION_SPIRITUALITY', 'discovery','discovery',    true,  false, false, true,  false, false, false, false, array['individual','vendor','institution','admin'], false),
  ('FORGOTTEN_HISTORY',     'discovery','discovery',    true,  false, false, true,  false, false, false, false, array['individual','vendor','institution','admin'], false)
) p(vertical_code,min_state,max_state,allows_events,allows_payments,allows_b2b,requires_mod,req_age_rules,req_refund,req_waiver,req_insurance,allowed_roles,is_internal)
where not exists (select 1 from public.vertical_policy vp where vp.vertical_code=p.vertical_code);

commit;