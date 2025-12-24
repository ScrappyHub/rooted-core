begin;

-- =========================================================
-- STORAGE.OBJECTS POLICY CLEANUP -> BUCKET REGISTRY (v2)
-- Goal: Make bucket registry the ONLY access gate.
-- Drops legacy/supabase default policies that overlap.
-- =========================================================

-- Drop known legacy policies (safe if missing)
drop policy if exists "Public read for rooted-public-media" on storage.objects;
drop policy if exists "public can read rooted-public-media" on storage.objects;

drop policy if exists "Authenticated can upload to rooted-public-media" on storage.objects;
drop policy if exists "vendors_and_admins_upload_public_media" on storage.objects;

drop policy if exists "owners_update_own_public_media" on storage.objects;
drop policy if exists "owners_delete_own_public_media" on storage.objects;

drop policy if exists "Owner or admin can read private media"   on storage.objects;
drop policy if exists "Owner or admin can insert private media" on storage.objects;
drop policy if exists "Owner or admin can update private media" on storage.objects;
drop policy if exists "Owner or admin can delete private media" on storage.objects;

drop policy if exists "owner_or_admin_read_private_media"   on storage.objects;
drop policy if exists "owner_or_admin_insert_private_media" on storage.objects;
drop policy if exists "owner_or_admin_update_private_media" on storage.objects;
drop policy if exists "owner_or_admin_delete_private_media" on storage.objects;

-- Recreate bucket-registry policies (idempotent)
drop policy if exists rooted_storage_objects_anon_read_v1 on storage.objects;
drop policy if exists rooted_storage_objects_auth_read_v1 on storage.objects;
drop policy if exists rooted_storage_objects_auth_insert_v1 on storage.objects;
drop policy if exists rooted_storage_objects_auth_update_v1 on storage.objects;
drop policy if exists rooted_storage_objects_auth_delete_v1 on storage.objects;

create policy rooted_storage_objects_anon_read_v1
on storage.objects
for select
to anon
using (
  exists (
    select 1
    from public.storage_bucket_policies p
    where p.bucket_id = storage.objects.bucket_id
      and p.anon_read = true
  )
);

create policy rooted_storage_objects_auth_read_v1
on storage.objects
for select
to authenticated
using (
  exists (
    select 1
    from public.storage_bucket_policies p
    where p.bucket_id = storage.objects.bucket_id
      and p.auth_read = true
  )
);

create policy rooted_storage_objects_auth_insert_v1
on storage.objects
for insert
to authenticated
with check (
  exists (
    select 1
    from public.storage_bucket_policies p
    where p.bucket_id = storage.objects.bucket_id
      and p.auth_write = true
  )
);

create policy rooted_storage_objects_auth_update_v1
on storage.objects
for update
to authenticated
using (
  exists (
    select 1
    from public.storage_bucket_policies p
    where p.bucket_id = storage.objects.bucket_id
      and p.auth_write = true
  )
)
with check (
  exists (
    select 1
    from public.storage_bucket_policies p
    where p.bucket_id = storage.objects.bucket_id
      and p.auth_write = true
  )
);

create policy rooted_storage_objects_auth_delete_v1
on storage.objects
for delete
to authenticated
using (
  exists (
    select 1
    from public.storage_bucket_policies p
    where p.bucket_id = storage.objects.bucket_id
      and p.auth_write = true
  )
);

commit;