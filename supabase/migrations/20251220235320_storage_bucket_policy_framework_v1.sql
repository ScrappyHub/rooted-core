begin;

-- =========================================================
-- STORAGE BUCKET POLICY FRAMEWORK (v1)
-- Creates:
--   public.storage_bucket_policies (service_role managed)
--   public.storage_bucket_policy(bucket_id) (service_role only)
-- =========================================================

create table if not exists public.storage_bucket_policies (
  bucket_id text primary key,
  anon_read boolean not null default false,
  auth_read boolean not null default false,
  auth_write boolean not null default false,
  notes text null,
  updated_at timestamptz not null default now()
);

alter table public.storage_bucket_policies enable row level security;
alter table public.storage_bucket_policies force row level security;

drop policy if exists storage_bucket_policies_service_manage_v1 on public.storage_bucket_policies;
create policy storage_bucket_policies_service_manage_v1
on public.storage_bucket_policies
for all
to service_role
using (true)
with check (true);

revoke all on table public.storage_bucket_policies from anon;
revoke all on table public.storage_bucket_policies from authenticated;

create or replace function public.storage_bucket_policy(p_bucket_id text)
returns table (
  bucket_id text,
  anon_read boolean,
  auth_read boolean,
  auth_write boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    s.bucket_id,
    s.anon_read,
    s.auth_read,
    s.auth_write
  from public.storage_bucket_policies s
  where s.bucket_id = p_bucket_id
$$;

revoke all on function public.storage_bucket_policy(text) from anon;
revoke all on function public.storage_bucket_policy(text) from authenticated;
grant execute on function public.storage_bucket_policy(text) to service_role;

commit;