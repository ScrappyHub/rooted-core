begin;

-- =========================================================
-- GEO GUARDRAILS + RADIUS CLAMP (v1)
-- - no extensions required
-- - provides a safe haversine meter distance function
-- - provides a hard radius clamp (default 50 miles)
-- =========================================================

create or replace function public.geo_haversine_meters(
  lat1 double precision,
  lon1 double precision,
  lat2 double precision,
  lon2 double precision
)
returns double precision
language sql
immutable
as $$
  -- Earth radius ~ 6,371,000 meters
  select 6371000.0 * 2.0 * asin(
    sqrt(
      pow(sin(radians((lat2 - lat1) / 2.0)), 2) +
      cos(radians(lat1)) * cos(radians(lat2)) *
      pow(sin(radians((lon2 - lon1) / 2.0)), 2)
    )
  );
$$;

revoke all on function public.geo_haversine_meters(double precision,double precision,double precision,double precision) from anon;
revoke all on function public.geo_haversine_meters(double precision,double precision,double precision,double precision) from authenticated;
grant execute on function public.geo_haversine_meters(double precision,double precision,double precision,double precision) to service_role;

create or replace function public.geo_radius_clamp_meters(
  requested_meters integer,
  max_meters integer default 80467   -- 50 miles ÃƒÂ¢Ã¢â‚¬Â°Ã‹â€  80,467m
)
returns integer
language sql
immutable
as $$
  select greatest(0, least(coalesce(requested_meters, max_meters), max_meters));
$$;

revoke all on function public.geo_radius_clamp_meters(integer,integer) from anon;
grant execute on function public.geo_radius_clamp_meters(integer,integer) to authenticated;
grant execute on function public.geo_radius_clamp_meters(integer,integer) to service_role;

commit;