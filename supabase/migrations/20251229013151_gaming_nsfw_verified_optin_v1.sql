-- ROOTED: ENFORCE-DO-CLOSE-DELIMITER-STEP-1S (canonical)
-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: REPAIR-DO-DELIMITERS-AND-SEMICOLONS-STEP-1P2 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-CANONICAL-STEP-1O (canonical)
begin;

-- Consents:
--  - adult_verified : must exist and be ON (your stronger verification, not "birthday")
--  - nsfw_opt_in    : must exist and be ON (explicit user choice)
-- Both required to ever surface NSFW.

create or replace function public._consent_is_on(p_status text)
returns boolean
language sql
stable
as begin;

alter table public.gamer_accounts enable row level security;
alter table public.gamer_profiles_public enable row level security;
alter table public.gamer_private_stats enable row level security;

-- Public can read public gamer profiles (no user_id stored here).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_read_v1'
  ) then
    create policy gamer_profiles_public_read_v1
    on public.gamer_profiles_public
    for select
    using (true);
  end if;
end;
$$;

-- Owner can manage their gamer profile row.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_owner_write_v1'
  ) then
    create policy gamer_profiles_public_owner_write_v1
    on public.gamer_profiles_public
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end;
$$;

-- Gamer accounts: only owner can select/update/insert.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_accounts' and policyname='gamer_accounts_owner_manage_v1'
  ) then
    create policy gamer_accounts_owner_manage_v1
    on public.gamer_accounts
    for all
    using (user_id = auth.uid())
    with check (user_id = auth.uid());
  end if;
end;
$$;

-- Private stats: only owner.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_private_stats' and policyname='gamer_private_stats_owner_manage_v1'
  ) then
    create policy gamer_private_stats_owner_manage_v1
    on public.gamer_private_stats
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end;
$$;

commit;
  select lower(p_status) in ('on','granted','accepted','true','enabled','verified','approved');
begin;

alter table public.gamer_accounts enable row level security;
alter table public.gamer_profiles_public enable row level security;
alter table public.gamer_private_stats enable row level security;

-- Public can read public gamer profiles (no user_id stored here).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_read_v1'
  ) then
    create policy gamer_profiles_public_read_v1
    on public.gamer_profiles_public
    for select
    using (true);
  end if;
end;
$$;

-- Owner can manage their gamer profile row.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_owner_write_v1'
  ) then
    create policy gamer_profiles_public_owner_write_v1
    on public.gamer_profiles_public
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end;
$$;

-- Gamer accounts: only owner can select/update/insert.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_accounts' and policyname='gamer_accounts_owner_manage_v1'
  ) then
    create policy gamer_accounts_owner_manage_v1
    on public.gamer_accounts
    for all
    using (user_id = auth.uid())
    with check (user_id = auth.uid());
  end if;
end;
$$;

-- Private stats: only owner.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_private_stats' and policyname='gamer_private_stats_owner_manage_v1'
  ) then
    create policy gamer_private_stats_owner_manage_v1
    on public.gamer_private_stats
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end;
$$;

commit;;

create or replace function public.nsfw_opt_in_enabled(p_user_id uuid)
returns boolean
language sql
stable
as begin;

alter table public.gamer_accounts enable row level security;
alter table public.gamer_profiles_public enable row level security;
alter table public.gamer_private_stats enable row level security;

-- Public can read public gamer profiles (no user_id stored here).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_read_v1'
  ) then
    create policy gamer_profiles_public_read_v1
    on public.gamer_profiles_public
    for select
    using (true);
  end if;
end;
$$;

-- Owner can manage their gamer profile row.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_owner_write_v1'
  ) then
    create policy gamer_profiles_public_owner_write_v1
    on public.gamer_profiles_public
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end;
$$;

-- Gamer accounts: only owner can select/update/insert.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_accounts' and policyname='gamer_accounts_owner_manage_v1'
  ) then
    create policy gamer_accounts_owner_manage_v1
    on public.gamer_accounts
    for all
    using (user_id = auth.uid())
    with check (user_id = auth.uid());
  end if;
end;
$$;

-- Private stats: only owner.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_private_stats' and policyname='gamer_private_stats_owner_manage_v1'
  ) then
    create policy gamer_private_stats_owner_manage_v1
    on public.gamer_private_stats
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end;
$$;

commit;
  select
    exists (
      select 1 from public.user_consents c
      where c.user_id = p_user_id
        and c.consent_type = 'adult_verified'
        and public._consent_is_on(c.status)
    )
    and
    exists (
      select 1 from public.user_consents c
      where c.user_id = p_user_id
        and c.consent_type = 'nsfw_opt_in'
        and public._consent_is_on(c.status)
    );
begin;

alter table public.gamer_accounts enable row level security;
alter table public.gamer_profiles_public enable row level security;
alter table public.gamer_private_stats enable row level security;

-- Public can read public gamer profiles (no user_id stored here).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_read_v1'
  ) then
    create policy gamer_profiles_public_read_v1
    on public.gamer_profiles_public
    for select
    using (true);
  end if;
end;
$$;

-- Owner can manage their gamer profile row.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_owner_write_v1'
  ) then
    create policy gamer_profiles_public_owner_write_v1
    on public.gamer_profiles_public
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end;
$$;

-- Gamer accounts: only owner can select/update/insert.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_accounts' and policyname='gamer_accounts_owner_manage_v1'
  ) then
    create policy gamer_accounts_owner_manage_v1
    on public.gamer_accounts
    for all
    using (user_id = auth.uid())
    with check (user_id = auth.uid());
  end if;
end;
$$;

-- Private stats: only owner.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_private_stats' and policyname='gamer_private_stats_owner_manage_v1'
  ) then
    create policy gamer_private_stats_owner_manage_v1
    on public.gamer_private_stats
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end;
$$;

commit;;

-- This is what your gaming catalog views should use.
create or replace function public.nsfw_visible_for_current_user()
returns boolean
language sql
stable
as begin;

alter table public.gamer_accounts enable row level security;
alter table public.gamer_profiles_public enable row level security;
alter table public.gamer_private_stats enable row level security;

-- Public can read public gamer profiles (no user_id stored here).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_read_v1'
  ) then
    create policy gamer_profiles_public_read_v1
    on public.gamer_profiles_public
    for select
    using (true);
  end if;
end;
$$;

-- Owner can manage their gamer profile row.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_owner_write_v1'
  ) then
    create policy gamer_profiles_public_owner_write_v1
    on public.gamer_profiles_public
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end;
$$;

-- Gamer accounts: only owner can select/update/insert.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_accounts' and policyname='gamer_accounts_owner_manage_v1'
  ) then
    create policy gamer_accounts_owner_manage_v1
    on public.gamer_accounts
    for all
    using (user_id = auth.uid())
    with check (user_id = auth.uid());
  end if;
end;
$$;

-- Private stats: only owner.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_private_stats' and policyname='gamer_private_stats_owner_manage_v1'
  ) then
    create policy gamer_private_stats_owner_manage_v1
    on public.gamer_private_stats
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end;
$$;

commit;
  select public.nsfw_opt_in_enabled(auth.uid());
begin;

alter table public.gamer_accounts enable row level security;
alter table public.gamer_profiles_public enable row level security;
alter table public.gamer_private_stats enable row level security;

-- Public can read public gamer profiles (no user_id stored here).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_read_v1'
  ) then
    create policy gamer_profiles_public_read_v1
    on public.gamer_profiles_public
    for select
    using (true);
  end if;
end;
$$;

-- Owner can manage their gamer profile row.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_profiles_public' and policyname='gamer_profiles_public_owner_write_v1'
  ) then
    create policy gamer_profiles_public_owner_write_v1
    on public.gamer_profiles_public
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_profiles_public.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end;
$$;

-- Gamer accounts: only owner can select/update/insert.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_accounts' and policyname='gamer_accounts_owner_manage_v1'
  ) then
    create policy gamer_accounts_owner_manage_v1
    on public.gamer_accounts
    for all
    using (user_id = auth.uid())
    with check (user_id = auth.uid());
  end if;
end;
$$;

-- Private stats: only owner.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='gamer_private_stats' and policyname='gamer_private_stats_owner_manage_v1'
  ) then
    create policy gamer_private_stats_owner_manage_v1
    on public.gamer_private_stats
    for all
    using (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    )
    with check (
      exists (
        select 1 from public.gamer_accounts ga
        where ga.id = gamer_private_stats.gamer_id
          and ga.user_id = auth.uid()
      )
    );
  end if;
end;
$$;

commit;;

commit;