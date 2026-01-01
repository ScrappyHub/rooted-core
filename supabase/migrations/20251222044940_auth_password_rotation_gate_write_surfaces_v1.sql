-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: AUTO-FIX-DO-OPENERS-STEP-1J2C (canonical)
BEGIN;

-- ============================================================
-- Password rotation write gate (authenticated)
-- Canonical pattern:
--   RESTRICTIVE policy that blocks all writes when rotation is required
--   Admin bypass allowed
-- ============================================================

-- Helper macro: repeat block via DO to avoid duplicate_object failures
-- NOTE: Postgres has no CREATE POLICY IF NOT EXISTS.

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $do$
BEGIN
  -- events
  BEGIN
    CREATE POLICY events_deny_write_if_password_rotation_required_v1
    ON public.events
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
  $do$;

  -- event_registrations
  BEGIN
    CREATE POLICY event_registrations_deny_write_if_password_rotation_required_v1
    ON public.event_registrations
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- conversations
  BEGIN
    CREATE POLICY conversations_deny_write_if_password_rotation_required_v1
    ON public.conversations
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- conversation_participants
  BEGIN
    CREATE POLICY conversation_participants_deny_write_if_password_rotation_required_v1
    ON public.conversation_participants
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- live_feed_posts
  BEGIN
    CREATE POLICY live_feed_posts_deny_write_if_password_rotation_required_v1
    ON public.live_feed_posts
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- feed_items
  BEGIN
    CREATE POLICY feed_items_deny_write_if_password_rotation_required_v1
    ON public.feed_items
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- feed_likes
  BEGIN
    CREATE POLICY feed_likes_deny_write_if_password_rotation_required_v1
    ON public.feed_likes
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- provider_media
  BEGIN
    CREATE POLICY provider_media_deny_write_if_password_rotation_required_v1
    ON public.provider_media
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- vendor_media
  BEGIN
    CREATE POLICY vendor_media_deny_write_if_password_rotation_required_v1
    ON public.vendor_media
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- community_spot_submissions
  BEGIN
    CREATE POLICY community_spot_submissions_deny_write_if_password_rotation_required_v1
    ON public.community_spot_submissions
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- community_nature_spots
  BEGIN
    CREATE POLICY community_nature_spots_deny_write_if_password_rotation_required_v1
    ON public.community_nature_spots
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- community_programs
  BEGIN
    CREATE POLICY community_programs_deny_write_if_password_rotation_required_v1
    ON public.community_programs
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- experiences
  BEGIN
    CREATE POLICY experiences_deny_write_if_password_rotation_required_v1
    ON public.experiences
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- experience_requests
  BEGIN
    CREATE POLICY experience_requests_deny_write_if_password_rotation_required_v1
    ON public.experience_requests
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  -- location_checkins
  BEGIN
    CREATE POLICY location_checkins_deny_write_if_password_rotation_required_v1
    ON public.location_checkins
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

END;
$do$;

COMMIT;