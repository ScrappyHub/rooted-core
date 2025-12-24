BEGIN;

CREATE OR REPLACE FUNCTION public.password_rotation_required(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $fn$
  SELECT COALESCE((
    SELECT (ppr.must_rotate_by IS NOT NULL)
           AND (ppr.must_rotate_by <= now())
    FROM public.provider_password_rotation_v1 ppr
    WHERE ppr.user_id = p_user_id
    LIMIT 1
  ), false);
$fn$;

COMMIT;