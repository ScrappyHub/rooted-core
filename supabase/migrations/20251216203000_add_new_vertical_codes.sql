-- 20251216203000_add_new_vertical_codes.sql
-- Canonical-safe: add new vertical codes without inventing new specialty_types codes.
-- FK: canonical_verticals.default_specialty -> specialty_types.code
-- We use existing ROOTED_PLATFORM_CANONICAL as a safe placeholder default_specialty.
-- You can later remap default_specialty once the specialty taxonomy is canonically authored.

BEGIN;

-- Disable ONLY the read-only trigger
ALTER TABLE public.canonical_verticals DISABLE TRIGGER canonical_verticals_read_only;

-- Add new vertical codes (append-only)
INSERT INTO public.canonical_verticals (vertical_code, label, description, sort_order, default_specialty)
VALUES
  (
    'WELLNESS_FAMILY_SENIORS',
    'Wellness, Family & Seniors',
    'Family services + senior supports + caregiver navigation. Discovery-first. No markets by default.',
    9000,
    'ROOTED_PLATFORM_CANONICAL'
  ),
  (
    'FITNESS_ACTIVE_LIVING',
    'Fitness & Active Living',
    'Fitness providers, facilities, and activity discovery. Events/registration surfaces allowed. No markets by default.',
    9010,
    'ROOTED_PLATFORM_CANONICAL'
  ),
  (
    'SPORTS_COMMUNITY',
    'Community Sports',
    'Teams, leagues, schedules, facilities, registration-style flows. Civic-hidden participant handling. No markets by default.',
    9020,
    'ROOTED_PLATFORM_CANONICAL'
  ),
  (
    'LOCAL_BUSINESS_DISCOVERY',
    'Local Business Discovery',
    'Local commerce discovery (no marketplaces by default).',
    9030,
    'ROOTED_PLATFORM_CANONICAL'
  ),
  (
    'CELEBRATIONS_EVENTS',
    'Celebrations & Party Services',
    'Celebrations services + public events discovery (no marketplaces by default).',
    9040,
    'ROOTED_PLATFORM_CANONICAL'
  )
ON CONFLICT (vertical_code) DO NOTHING;

-- Optional label refinement for existing EMERGENCY_RESPONSE row (code stays the same)
UPDATE public.canonical_verticals
SET label = 'Emergency & Disaster Response'
WHERE vertical_code = 'EMERGENCY_RESPONSE'
  AND label IS DISTINCT FROM 'Emergency & Disaster Response';

-- Re-enable trigger
ALTER TABLE public.canonical_verticals ENABLE TRIGGER canonical_verticals_read_only;

COMMIT;
