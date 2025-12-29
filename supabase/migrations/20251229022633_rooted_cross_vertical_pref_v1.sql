begin;

create or replace function public._consent_is_off(p_status text)
returns boolean
language sql
stable
as $$
  select coalesce(lower(p_status) in ('revoked','denied','withdrawn','off','false','disabled'), false);
$$;

-- Default ON when no row exists. OFF only when an OFF-like status exists.
create or replace function public.cross_vertical_discovery_enabled(p_user_id uuid)
returns boolean
language sql
stable
as $$
  select not exists (
    select 1
    from public.user_consents uc
    where uc.user_id = p_user_id
      and uc.consent_type = 'cross_vertical_discovery'
      and public._consent_is_off(uc.status) = true
  );
$$;

create or replace function public.current_user_cross_vertical_discovery_enabled()
returns boolean
language sql
stable
as $$
  select public.cross_vertical_discovery_enabled(auth.uid());
$$;

commit;