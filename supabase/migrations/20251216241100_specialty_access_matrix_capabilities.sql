begin;

insert into public.specialty_capabilities (capability_key, description, default_allowed)
values
  -- Providers / profiles
  ('PROVIDER_PROFILE_EDIT', 'May edit provider profile fields.', true),
  ('PROVIDER_MEDIA_MANAGE', 'May manage provider media/gallery.', true),

  -- Discovery + badges (NOT the same as editing profile)
  ('BADGE_REQUEST', 'May request badges / recognitions.', true),
  ('BADGE_ASSIGN_ADMIN_ONLY', 'Admin-only badge assignment actions.', false),

  -- Community feed posting
  ('FEED_POST_CREATE', 'May create feed posts.', false),
  ('FEED_POST_COMMENT', 'May comment on feed posts.', false),
  ('FEED_POST_REACT', 'May like/react to posts.', false),

  -- Messaging
  ('MESSAGE_SEND', 'May send messages in conversations they are in.', true),

  -- Events
  ('EVENT_CREATE', 'May create events (draft/submitted).', true),
  ('EVENT_UPDATE', 'May update events they own.', true),
  ('EVENT_DELETE', 'May delete events they own.', true),
  ('EVENT_PUBLISH', 'May publish events (status=published).', false),
  ('EVENT_VOLUNTEER', 'May create volunteer events.', true),
  ('EVENT_NON_VOLUNTEER', 'May create non-volunteer events.', true),

  -- Procurement (RFQs / bids / offers)
  ('RFQ_CREATE', 'May create RFQs.', false),
  ('BID_SUBMIT', 'May submit bids.', false),
  ('BULK_OFFER_CREATE', 'May create bulk offers.', false)

on conflict (capability_key) do update
  set description = excluded.description,
      default_allowed = excluded.default_allowed;

commit;
