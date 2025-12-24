-- ==========================================
-- ROOTED: password_rotation_required() v1
-- Purpose:
--   Unblock RLS policies that reference public.password_rotation_required(uuid)
-- Notes:
--   Replace stub logic with real enforcement once the backing state is wired.
-- ==========================================

create or replace function public.password_rotation_required(p_user_id uuid)
returns boolean
language sql
stable
as $$
  select false;
$$;

comment on function public.password_rotation_required(uuid) is
'ROOTED: returns true when a user must rotate password before writes. Stubbed false until wired.';
