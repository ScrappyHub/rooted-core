-- 20251216241160_extend_vertical_specialties_v1_with_label.sql
-- Fix: 20251216241200 expects vertical_specialties_v1 to include specialty_label.
-- Canonical: label comes from public.specialty_types.
-- This adds specialty_label to the view (additive change, remote-safe).

begin;

create or replace view public.vertical_specialties_v1 as
select
  vcs.vertical_code,
  vcs.specialty_code,
  st.label as specialty_label,
  vcs.is_default
from public.vertical_canonical_specialties vcs
left join public.specialty_types st
  on st.code = vcs.specialty_code;

commit;