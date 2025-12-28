BEGIN;

DROP POLICY IF EXISTS rfqs_deny_write_if_password_rotation_required_v1
ON public.rfqs;

CREATE POLICY rfqs_deny_write_if_password_rotation_required_v1
ON public.rfqs
AS RESTRICTIVE
FOR ALL
TO authenticated
USING (
  is_admin()
  OR NOT public.password_rotation_required(auth.uid())
)
WITH CHECK (
  is_admin()
  OR NOT public.password_rotation_required(auth.uid())
);

COMMIT;
