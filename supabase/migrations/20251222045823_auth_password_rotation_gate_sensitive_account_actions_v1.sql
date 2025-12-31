-- ROOTED: AUTO-FIX-DO-OPENERS-STEP-1J2C (canonical)
BEGIN;

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $do$
BEGIN
  -- account_deletion_requests
  BEGIN
    CREATE POLICY pwdrot_gate_v1
    ON public.account_deletion_requests
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;

  -- user_consents
  BEGIN
    CREATE POLICY pwdrot_gate_v1
    ON public.user_consents
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;

  -- user_devices
  BEGIN
    CREATE POLICY pwdrot_gate_v1
    ON public.user_devices
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;

  -- vendor_applications (user submits)
  BEGIN
    CREATE POLICY pwdrot_gate_v1
    ON public.vendor_applications
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;

  -- institution_applications (user submits)
  BEGIN
    CREATE POLICY pwdrot_gate_v1
    ON public.institution_applications
    AS RESTRICTIVE
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR NOT public.password_rotation_required(auth.uid()))
    WITH CHECK (public.is_admin() OR NOT public.password_rotation_required(auth.uid()));
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;

END;
$do$;

COMMIT;