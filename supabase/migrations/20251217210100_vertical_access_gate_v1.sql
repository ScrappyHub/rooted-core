@"
-- 20251217210100_vertical_access_gate_v1.sql
-- Central gate: “is this user allowed to access this vertical at all?”
-- Depends on public.current_user_role() existing.

begin;

create or replace function public.can_access_vertical(p_vertical_code text)
returns boolean
language sql
stable
as \$\$
  select exists (
    select 1
    from public.vertical_policy vp
    where vp.vertical_code = p_vertical_code
      and auth.uid() is not null
      and public.current_user_role() = any(vp.allowed_roles)
      and (
        vp.is_internal_only = false
        or vp.is_internal_only = true
      )
  );
\$\$;

commit;
"@ | Set-Content -Encoding UTF8 .\supabase\migrations\20251217210100_vertical_access_gate_v1.sql
