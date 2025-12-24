BEGIN;

-- Canonical hardening: function must be total (never NULL) and stable.
CREATE OR REPLACE FUNCTION public.password_rotation_required(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
  SELECT COALESCE(
    (
      SELECT (ppr.must_rotate_by IS NOT NULL) AND (ppr.must_rotate_by <= now())
      FROM public.provider_password_rotation_v1 ppr
      WHERE ppr.user_id = p_user_id
      ORDER BY ppr.must_rotate_by DESC
      LIMIT 1
    ),
    false
  );
$fn$;

COMMENT ON FUNCTION public.password_rotation_required(uuid)
IS 'Returns true when a user must rotate credentials now (must_rotate_by <= now()). Used by restrictive RLS gates to deny writes.';

COMMIT;