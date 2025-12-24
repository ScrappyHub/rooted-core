begin;

-- =========================================================
-- STORAGE OBJECT POLICIES BY BUCKET (v1)
-- Bucket-level gating only:
--   - anon read if bucket_policy.anon_read = true
--   - authenticated read if bucket_policy.auth_read = true
--   - authenticated write if bucket_policy.auth_write = true
-- =========================================================

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