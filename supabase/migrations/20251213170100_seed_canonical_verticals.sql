-- ROOTED: DO-BLOCK-NORMALIZE-V1 (canonical)
-- ROOTED: AUTO-FIX-DO-CLOSER-MISMATCH-STEP-1M (canonical)
-- 20251213170100_seed_canonical_verticals.sql
-- ROOTED CORE: Seed canonical_verticals (migration-only; safe if table not yet created)

begin;

-- migration-only bypass (transaction-local)
select set_config('rooted.migration_bypass', 'on', true);

do $$
begin
  if to_regclass('public.canonical_verticals') is null then
    -- table doesn't exist yet in this local rebuild order; skip safely
    return;
  end if;

  insert into public.canonical_verticals
    (vertical_code, label, description, sort_order, default_specialty)
  values
    ('agriculture', 'Agriculture', 'ROOTED Agriculture (live vertical). Local food, farms, markets, seasonal discovery, events, landmarks.', 10, 'farm'),
    ('community_services', 'Community Services', 'Neighborhood orgs, mutual aid, local services, and volunteer coordination for ROOTED Community.', 20, 'community_service'),
    ('education', 'Education', 'Learning experiences, field trips, institutions, and kids-safe discovery surfaces (Kids Mode governed; pilot OFF until enabled).', 30, 'education_program'),
    ('environment', 'Environment', 'Land, parks, conservation, stewardship, and environmental discovery and education.', 40, 'nature'),
    ('arts_culture', 'Arts & Culture', 'Venues, galleries, exhibits, performances, cultural centers, and events discovery.', 50, 'arts_culture'),
    ('experiences', 'Experiences', 'Curated guided activities and adventures (safety-first; no new procurement markets).', 60, 'experience'),
    ('construction', 'Construction', 'B2B construction discovery and governed procurement workflows (RFQs/bids/bulk per tier).', 70, 'general_contractor'),
    ('manufacturing', 'Manufacturing', 'Makers, fabrication, and local manufacturing discovery (governed; markets/tier rules enforced by core).', 80, 'manufacturer'),
    ('mental_health', 'Mental Health', 'Non-clinical mental health resources and support services discovery (safety-first, non-profiling).', 90, 'mental_health_resource'),
    ('science_maker', 'Science + Maker', 'Science learning, maker spaces, labs, STEM programming, and community innovation hubs.', 100, 'maker_space'),
    ('land_resources', 'Land Resources', 'Land use resources, trails, public spaces, stewardship programs, and related services.', 110, 'land_resource'),
    ('regional_intel', 'Regional Intelligence', 'Regional discovery overlays, alerts, non-personalized civic intelligence, and fair exposure tooling.', 120, 'regional_intel'),
    ('meta_infrastructure', 'Meta Infrastructure', 'Platform-level infrastructure surfaces visible in the product (conditions, seasonal/cultural layers, system overlays).', 130, 'infrastructure')
  on conflict (vertical_code) do update
  set
    label = excluded.label,
    description = excluded.description,
    sort_order = excluded.sort_order,
    default_specialty = excluded.default_specialty;
end;
$$;

commit;