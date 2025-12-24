BEGIN;

-- Drop first to avoid duplicates if you partially created it earlier
DROP POLICY IF EXISTS rfqs_deny_write_if_password_rotation_required_v1 ON public.rfqs;

-- Canonical: deny ALL writes (INSERT/UPDATE/DELETE) for authenticated when rotation is required
-- Admin bypasses.
CREATE POLICY rfqs_deny_write_if_password_rotation_required_v1
ON public.rfqs
AS RESTRICTIVE
FOR ALL
TO authenticated
USING (
  is_admin() OR NOT public.password_rotation_required(auth.uid())
)
WITH CHECK (
  is_admin() OR NOT public.password_rotation_required(auth.uid())
);

COMMIT;