-- =========================================================
-- ROOTED HARDENING v2:
-- Gate sensitive writes if password rotation required
-- Targets: rfqs, bids, bulk_offers, providers, institutions (ONLY if it's a TABLE)
-- =========================================================

-- Helper: true if named object is a real table/partitioned table
-- (inline logic; no new functions needed)

-- RFQS
drop policy if exists rfqs_deny_write_if_password_rotation_required_v1 on public.rfqs;
create policy rfqs_deny_write_if_password_rotation_required_v1
on public.rfqs
as restrictive
for all
to authenticated
using (is_admin() or not public.password_rotation_required(auth.uid()))
with check (is_admin() or not public.password_rotation_required(auth.uid()));

-- BIDS
drop policy if exists bids_deny_write_if_password_rotation_required_v1 on public.bids;
create policy bids_deny_write_if_password_rotation_required_v1
on public.bids
as restrictive
for all
to authenticated
using (is_admin() or not public.password_rotation_required(auth.uid()))
with check (is_admin() or not public.password_rotation_required(auth.uid()));

-- BULK_OFFERS
drop policy if exists bulk_offers_deny_write_if_password_rotation_required_v1 on public.bulk_offers;
create policy bulk_offers_deny_write_if_password_rotation_required_v1
on public.bulk_offers
as restrictive
for all
to authenticated
using (is_admin() or not public.password_rotation_required(auth.uid()))
with check (is_admin() or not public.password_rotation_required(auth.uid()));

-- PROVIDERS
drop policy if exists providers_deny_write_if_password_rotation_required_v1 on public.providers;
create policy providers_deny_write_if_password_rotation_required_v1
on public.providers
as restrictive
for all
to authenticated
using (is_admin() or not public.password_rotation_required(auth.uid()))
with check (is_admin() or not public.password_rotation_required(auth.uid()));

-- INSTITUTIONS (ONLY if it is a TABLE)
do $$
declare
  _reg regclass;
  _kind "char";
begin
  _reg := to_regclass('public.institutions');
  if _reg is null then
    raise notice 'public.institutions does not exist; skipping policy';
    return;
  end if;

  select c.relkind into _kind
  from pg_class c
  where c.oid = _reg;

  if _kind not in ('r','p') then
    raise notice 'public.institutions is not a table (relkind=%); skipping policy', _kind;
    return;
  end if;

  execute 'drop policy if exists institutions_deny_write_if_password_rotation_required_v1 on public.institutions;';
  execute $sql$
    create policy institutions_deny_write_if_password_rotation_required_v1
    on public.institutions
    as restrictive
    for all
    to authenticated
    using (is_admin() or not public.password_rotation_required(auth.uid()))
    with check (is_admin() or not public.password_rotation_required(auth.uid()));
  $sql$;

  raise notice 'institutions password-rotation gate policy applied';
end $$;
