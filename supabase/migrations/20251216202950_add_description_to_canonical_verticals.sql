-- 20251216202950_add_description_to_canonical_verticals.sql
-- ROOTED CORE: bridge column for later migrations expecting canonical_verticals.description

begin;

alter table public.canonical_verticals
  add column if not exists description text;

commit;