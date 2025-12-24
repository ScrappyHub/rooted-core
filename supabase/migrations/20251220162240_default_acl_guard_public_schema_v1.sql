begin;

-- DEFAULT ACL AUDIT (public schema) (v1)
-- Non-blocking audit: lists unsafe supabase_admin default ACL entries if present.

select
  defaclobjtype,
  pg_get_userbyid(defaclrole) as owner,
  array_to_string(defaclacl, ',') as defaclacl
from pg_default_acl
where defaclnamespace = 'public'::regnamespace
  and defaclrole = 'supabase_admin'::regrole
order by defaclobjtype, defaclacl;

commit;