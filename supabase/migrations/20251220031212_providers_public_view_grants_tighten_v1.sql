-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
begin;

do $$
begin
  if to_regclass('public.providers_public_v1') is null then
    raise exception 'providers_public_view_grants_tighten_v1: public.providers_public_v1 missing';
  end if;
end;
$$;

-- Revoke everything first (clean slate)
revoke all on table public.providers_public_v1 from anon;
revoke all on table public.providers_public_v1 from authenticated;

-- Grant SELECT only
grant select on public.providers_public_v1 to anon, authenticated;

commit;