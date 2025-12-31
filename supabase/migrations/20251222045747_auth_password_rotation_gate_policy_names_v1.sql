-- ROOTED: AUTO-FIX-DO-OPENERS-STEP-1J2C (canonical)
BEGIN;

-- Normalize truncated policy names to a canonical short name: pwdrot_gate_v1
-- Safe: uses dynamic SQL to drop whichever policy exists on each table.

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $do$
DECLARE
  t text;
  existing text;
  tables text[] := ARRAY[
    'events',
    'event_registrations',
    'conversations',
    'conversation_participants',
    'live_feed_posts',
    'feed_items',
    'feed_likes',
    'provider_media',
    'vendor_media',
    'community_spot_submissions',
    'community_nature_spots',
    'community_programs',
    'experiences',
    'experience_requests',
    'location_checkins'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    -- find any existing gate policy on this table (including truncated variants)
    SELECT policyname
      INTO existing
    FROM pg_policies
    WHERE schemaname='public'
      AND tablename=t
      AND policyname ILIKE '%deny_write_if_password_rotation_required%'
    LIMIT 1;

    IF existing IS NOT NULL THEN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', existing, t);
    END IF;

    -- also drop our canonical name if present (idempotent)
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', 'pwdrot_gate_v1', t);

    -- recreate canonical short policy name
    EXECUTE format($sql$
      CREATE POLICY %I
      ON public.%I
      AS RESTRICTIVE
      FOR ALL
      TO authenticated
      USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
      WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
    $sql$, 'pwdrot_gate_v1', t);

    existing := NULL;
  END LOOP;
END;
$do$;

COMMIT;