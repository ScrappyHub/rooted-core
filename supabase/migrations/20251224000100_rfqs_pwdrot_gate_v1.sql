-- ==========================================
-- ROOTED: rfqs password-rotation write gate
-- Adds missing global policy: pwdrot_gate_v1
-- Matches pattern used on 21 other tables.
-- ==========================================

drop policy if exists pwdrot_gate_v1 on public.rfqs;

create policy pwdrot_gate_v1
on public.rfqs
as restrictive
for all
to authenticated
using (
  is_admin()
  or not public.password_rotation_required(auth.uid())
)
with check (
  is_admin()
  or not public.password_rotation_required(auth.uid())
);

