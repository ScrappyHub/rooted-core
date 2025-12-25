-- 20251216241161_fix_vertical_specialties_view_column_order_v1.sql
-- Fix: CREATE OR REPLACE VIEW cannot reorder/rename existing columns.
-- Keep existing column order (vertical_code, specialty_code, is_default),
-- then append specialty_label at the end.

begin;

create or replace view public.vertical_specialties_v1 as
select
  vcs.vertical_code,
  vcs.specialty_code,
  vcs.is_default,
  st.label as specialty_label
from public.vertical_canonical_specialties vcs
left join public.specialty_types st
  on st.code = vcs.specialty_code;

commit;