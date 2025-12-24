BEGIN;

-- ============================================================
-- TEST HARNESS: force password rotation requirement
-- Service role OR admin only.
-- Uses password_history, which feeds provider_password_rotation_v1.
-- ============================================================

CREATE OR REPLACE FUNCTION public.service_force_password_rotation_required(
  p_user_id uuid,
  p_required boolean DEFAULT true
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
DECLARE
  v_role text;
BEGIN
  -- Supabase: service role commonly arrives via jwt claim "role"
  v_role := current_setting('request.jwt.claim.role', true);

  IF NOT (v_role = 'service_role' OR public.is_admin()) THEN
    RAISE EXCEPTION 'not authorized';
  END IF;

  INSERT INTO public.password_history (id, user_id, pw_fingerprint, rotated_at)
  VALUES (
    gen_random_uuid(),
    p_user_id,
    CASE WHEN p_required THEN '__force_rotation_required__' ELSE '__force_rotation_clear__' END,
    CASE WHEN p_required THEN (now() - interval '366 days') ELSE now() END
  );

END;
$fn$;

COMMENT ON FUNCTION public.service_force_password_rotation_required(uuid, boolean)
IS 'Service/admin-only harness. Inserts a sentinel password_history row so provider_password_rotation_v1 marks user rotation-required (or clears by inserting rotated_at=now()).';

COMMIT;