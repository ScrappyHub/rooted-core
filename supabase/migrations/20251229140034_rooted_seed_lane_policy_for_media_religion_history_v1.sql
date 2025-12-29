begin;

-- Ensure tables exist
create table if not exists public.lane_codes (
  lane_code text primary key,
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

-- Ensure lane codes exist
insert into public.lane_codes (lane_code, label, description)
select x.lane_code, x.label, x.description
from (values
  ('discovery','Discovery','Discovery surfaces, search/browse/listing visibility rules.'),
  ('events','Events','Event listings + publishing + host gating.'),
  ('registration','Registration','Registration flows and compliance gates.'),
  ('commerce_listings','Commerce Listings','Listings/catalog/marketplace publishing lane.'),
  ('payments','Payments','Payment processing lane.'),
  ('streaming_music','Streaming Music','Music streaming/library lane.'),
  ('streaming_video','Streaming Video','Video streaming/library lane.')
) x(lane_code,label,description)
where not exists (select 1 from public.lane_codes lc where lc.lane_code=x.lane_code);

-- Seed lane rows (idempotent)
insert into public.vertical_lane_policy (vertical_code, lane_code, enabled, requires_entitlement_code, requires_moderation, requires_age_gate, notes)
select v.vertical_code, v.lane_code, v.enabled, v.req_ent, v.req_mod, v.req_age, v.notes
from (values
  ('MUSIC_CREATORS',      'discovery',       true,  null,        true,  false, 'Creators discovery moderated.'),
  ('MUSIC_CREATORS',      'registration',    true,  'registration', true, true,  'Creator registration gate.'),
  ('MUSIC_CREATORS',      'payments',        true,  'premium',    true,  false, 'Creator monetization gate.'),

  ('STREAMING_MUSIC',     'streaming_music', true,  null,        true,  false, 'Streaming music lane enabled.'),
  ('STREAMING_MUSIC',     'payments',        true,  'premium',   true,  false, 'Streaming payments gate.'),

  ('STREAMING_MEDIA',     'streaming_video', true,  null,        true,  false, 'Video lane under broad Streaming Media.'),
  ('STREAMING_MEDIA',     'payments',        true,  'premium',   true,  false, 'Streaming payments gate.'),

  ('RELIGION_SPIRITUALITY','discovery',      true,  null,        true,  false, 'Moderated discovery.'),
  ('RELIGION_SPIRITUALITY','events',         true,  null,        true,  false, 'Moderated events.'),
  ('FORGOTTEN_HISTORY',   'discovery',       true,  null,        true,  false, 'Moderated discovery.'),
  ('FORGOTTEN_HISTORY',   'events',          true,  null,        true,  false, 'Moderated events.')
) v(vertical_code,lane_code,enabled,req_ent,req_mod,req_age,notes)
where not exists (
  select 1 from public.vertical_lane_policy vlp
  where vlp.vertical_code=v.vertical_code and vlp.lane_code=v.lane_code
);

commit;