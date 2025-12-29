begin;

create or replace function public._consent_is_off(p_status text)
returns boolean
language sql
stable
as \$\$
  select lower(p_status) in ('revoked','denied','withdrawn','off','false','disabled');
\$\$;

create or replace function public.cross_vertical_discovery_enabled(p_user_id uuid)
returns boolean
language sql
stable
as \$\$
  select not exists (
    select 1 from public.user_consents uc
    where uc.user_id = p_user_id
      and uc.consent_type = 'cross_vertical_discovery'
      and public._consent_is_off(uc.status)
  );
\$\$;

create or replace function public.current_user_cross_vertical_discovery_enabled()
returns boolean
language sql
stable
as \$\$
  select public.cross_vertical_discovery_enabled(auth.uid());
\$\$;

commit;