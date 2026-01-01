-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

do $$
begin
  if to_regclass('public.password_history') is null then
    raise exception 'service_role_policies_for_zero_policy_tables_v1: expected password_history missing';
  end if;
end;
$$;

-- password_history
drop policy if exists password_history_service_role_manage_v1 on public.password_history;
create policy password_history_service_role_manage_v1
on public.password_history for all to service_role
using (true) with check (true);

-- user_password_history
drop policy if exists user_password_history_service_role_manage_v1 on public.user_password_history;
create policy user_password_history_service_role_manage_v1
on public.user_password_history for all to service_role
using (true) with check (true);

-- user_tier_memberships
drop policy if exists user_tier_memberships_service_role_manage_v1 on public.user_tier_memberships;
create policy user_tier_memberships_service_role_manage_v1
on public.user_tier_memberships for all to service_role
using (true) with check (true);

-- kv_store_* tables (explicit list from your audit)
drop policy if exists kv_store_5bb94edf_service_role_manage_v1 on public.kv_store_5bb94edf;
create policy kv_store_5bb94edf_service_role_manage_v1
on public.kv_store_5bb94edf for all to service_role
using (true) with check (true);

drop policy if exists kv_store_80d2ab6d_service_role_manage_v1 on public.kv_store_80d2ab6d;
create policy kv_store_80d2ab6d_service_role_manage_v1
on public.kv_store_80d2ab6d for all to service_role
using (true) with check (true);

drop policy if exists kv_store_9ca868c2_service_role_manage_v1 on public.kv_store_9ca868c2;
create policy kv_store_9ca868c2_service_role_manage_v1
on public.kv_store_9ca868c2 for all to service_role
using (true) with check (true);

drop policy if exists kv_store_d3ca0863_service_role_manage_v1 on public.kv_store_d3ca0863;
create policy kv_store_d3ca0863_service_role_manage_v1
on public.kv_store_d3ca0863 for all to service_role
using (true) with check (true);

drop policy if exists kv_store_f009e61d_service_role_manage_v1 on public.kv_store_f009e61d;
create policy kv_store_f009e61d_service_role_manage_v1
on public.kv_store_f009e61d for all to service_role
using (true) with check (true);

drop policy if exists kv_store_fabed9c2_service_role_manage_v1 on public.kv_store_fabed9c2;
create policy kv_store_fabed9c2_service_role_manage_v1
on public.kv_store_fabed9c2 for all to service_role
using (true) with check (true);

commit;