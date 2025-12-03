# ROOTED – Backend Discovery API Pseudocode (Canonical)

Status: ✅ Canonical  
Scope: All discovery endpoints that power ROOTED maps & carousels  

This file defines the **canonical backend behavior** for ROOTED discovery endpoints.

All implementations (Supabase SQL, Node, edge functions, etc.) MUST match this logic and the contracts in:

- `UI_BACKEND_DISCOVERY_CONTRACT.md`
- `DISCOVERY_RULES.md`
- `GEO_RULES.md`

---

## 1. Endpoint Shape

Canonical HTTP endpoint (example):

`GET /api/discovery`

**Expected query params:**

- `lat` – required (user latitude)
- `lng` – required (user longitude)
- `radius` – optional (backend enforces `<= 50` miles)
- `specialty` – optional (farms, bakeries, contractors, clinics, etc.)
- `limit` – optional (backend clamps between `6–8`)
- `verified_only` – optional, default `true`
- (implicit) user context from auth token:
  - role, tier, Kids Mode, sanctuary flags, etc.

---

## 2. Core Pseudocode

```pseudo
function handleDiscoveryRequest(request, user):

    # 1. Parse + validate inputs
    lat          = parseFloat(request.query.lat)
    lng          = parseFloat(request.query.lng)
    radiusReq    = parseInt(request.query.radius)
    limitReq     = parseInt(request.query.limit)
    specialty    = request.query.specialty
    verifiedOnly = request.query.verified_only ?? true

    if lat is null or lng is null:
        return error(400, "Location is required")

    # 2. Enforce GEO rules (see GEO_RULES.md)
    RADIUS_MAX = 50
    if radiusReq is null or radiusReq <= 0:
        radius = RADIUS_MAX
    else:
        radius = min(radiusReq, RADIUS_MAX)

    # 3. Enforce global result limits (6–8 only)
    MIN_RESULTS = 6
    MAX_RESULTS = 8

    if limitReq is null or limitReq < MIN_RESULTS:
        limit = MIN_RESULTS
    else if limitReq > MAX_RESULTS:
        limit = MAX_RESULTS
    else:
        limit = limitReq

    # 4. Build base provider query (no UI logic here)
    query = SELECT *
            FROM providers_public_view   # view that already enforces RLS
            WHERE distance_miles(lat, lng, provider_lat, provider_lng) <= radius
              AND is_active = true
              AND is_discoverable = true

    if specialty is not null:
        query = query AND provider_specialty = specialty

    if verifiedOnly == true:
        query = query AND is_verified = true

    # Kids Mode enforcement (safety layer)
    if user.isKidsMode == true:
        query = query
            AND kids_allowed = true
            AND commercial_activity_allowed = false

    # Sanctuary / nonprofit enforcement
    if user.role in ['guest', 'individual']:
        # still ok to see sanctuaries, but no commercial-only providers
        query = query AND NOT requires_commercial_access_only

    # 5. Apply rotation & fairness rules
    #    (fields assumed: last_shown_at, created_at, engagement_score, is_founding_vendor)
    query = query
        ORDER BY
            last_shown_at ASC,         # show providers who haven't been seen recently
            engagement_score DESC,     # small boost for active/engaged providers
            is_founding_vendor DESC,   # optional fair boost for founding partners
            created_at ASC,            # older vendors not permanently buried
            random()                   # random tiebreaker

    # 6. Fetch candidates with hard cap
    candidates = execute(query LIMIT MAX_RESULTS)

    # 7. Low-data fallback (fewer than MIN_RESULTS available)
    if count(candidates) < MIN_RESULTS:
        responseProviders = candidates
        lowDataZone = true
    else:
        responseProviders = first(limit, candidates)
        lowDataZone = false

    # 8. Update rotation metadata for returned providers
    now = current_timestamp()
    providerIds = map(responseProviders, p => p.id)

    UPDATE providers
      SET last_shown_at = now
      WHERE id IN (providerIds)

    # 9. Sanitize output (never leak internal fields)
    sanitized = []
    for provider in responseProviders:
        sanitized.push({
            id: provider.id,
            name: provider.name,
            specialty: provider.provider_specialty,
            geo: {
                city: provider.city,
                state: provider.state
            },
            distance_miles: distance_miles(lat, lng, provider_lat, provider_lng),
            badges: provider.badges_public,     # trust / safety signals only
            media: {
                hero_image_url: provider.hero_image_url
            }
        })

    return json({
        providers: sanitized,
        meta: {
            radius_miles: radius,
            limit: limit,
            total_returned: count(sanitized),
            low_data_zone: lowDataZone
        }
    })
3. Anti-Gaming Enforcement
Additional backend checks (conceptual):

pseudo
Copy code
function validateAntiGaming(user, request):

    # Radius spoofing
    if request.radius > 50:
        reject("Radius cannot exceed 50 miles")

    # Location spoofing (optional but recommended):
    # If IP region and lat/lng are wildly inconsistent:
    #   mark request for soft throttling or additional checks.

    # Duplicate provider accounts:
    # If multiple providers share same tax_id or legal_name:
    #   flag for manual review
    #   lower discovery priority in ranking

    # Paid permanent placement is NOT allowed here.
    # Any paid boosts must live in a separate, clearly-marked surface,
    # never in the core 6–8 discovery rows.
This logic must be consistent with:

DISCOVERY_RULES.md

UI_BACKEND_DISCOVERY_CONTRACT.md

4. Vertical Compatibility
This pseudocode applies to:

ROOTED Community (live)

Future verticals that reuse discovery (Construction, Healthcare, etc.)

If a vertical uses discovery rows, it inherits:

6–8 result contract

Fair rotation rules

Kids Mode and sanctuary enforcement

Anti-gaming protections

Any implementation that breaks these rules is a platform-breaking defect.

All production implementations must keep logic equivalent to this pseudocode,
even if the language, framework, or database technology changes in the future.
