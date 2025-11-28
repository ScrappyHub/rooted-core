Content to paste into DISCOVERY_BACKEND_PSEUDOCODE.md

Paste everything from here down into that new file ⬇️

# ROOTED – Backend Discovery API Pseudocode

This file defines the canonical backend behavior for ROOTED discovery endpoints.

All implementations (Supabase, Node, edge functions, etc.) MUST follow this logic.

---

## Endpoint Shape

**Canonical endpoint:**

`GET /api/discovery`

**Expected query params:**

- `lat` – required (user latitude)
- `lng` – required (user longitude)
- `radius` – optional, but backend forces 50 miles max
- `specialty` – optional (farms, bakeries, butchers, contractors, clinics, etc.)
- `limit` – optional, but backend forces 6–8 only
- `verified_only` – optional, default true

---

## Core Pseudocode

```pseudo
function handleDiscoveryRequest(request):

    # 1. Parse + validate inputs
    lat        = parseFloat(request.query.lat)
    lng        = parseFloat(request.query.lng)
    radiusReq  = parseInt(request.query.radius)   # user-supplied
    limitReq   = parseInt(request.query.limit)
    specialty  = request.query.specialty
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

    # 4. Build base query (no UI logic here)
    query = SELECT * FROM providers
            WHERE distance_miles(lat, lng, provider_lat, provider_lng) <= radius
              AND is_active = true

    if specialty is not null:
        query = query AND provider_specialty = specialty

    if verifiedOnly == true:
        query = query AND is_verified = true

    # 5. Apply rotation & fairness rules
    #    (fields assumed: last_shown_at, created_at, engagement_score)
    query = query
        ORDER BY
            last_shown_at ASC,         # show people who haven't been seen recently
            engagement_score DESC,     # small boost for active/engaged providers
            created_at ASC,            # older vendors not permanently buried
            random()                   # random tiebreaker

    # 6. Fetch candidates with hard cap
    candidates = execute(query LIMIT MAX_RESULTS)

    # 7. Low-data fallback (fewer than 6 available)
    if count(candidates) < MIN_RESULTS:
        # OK – we return whatever we have.
        # UI will show "Showing all available local providers"
        responseProviders = candidates
    else:
        # Normal case – obey requested/derived limit (6–8)
        responseProviders = first(limit, candidates)

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
            badges: provider.badges,               # verification, safety, etc.
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
            low_data_zone: count(candidates) < MIN_RESULTS
        }
    })

Anti-Gaming Enforcement

Backend MUST additionally:

function validateAntiGaming(user, request):

    # Radius spoofing
    if request.radius > 50:
        reject("Radius cannot exceed 50 miles")

    # Location spoofing – optional but recommended:
    # compare IP-based region vs declared lat/lng for extreme mismatch.

    # Duplicate provider accounts:
    # if multiple providers share same tax_id or legal_name:
    #   flag for review and reduce discovery priority.

    # Paid permanent placement is NOT allowed here.
    # Any paid boosts must live in a separate, clearly-marked surface,
    # never in the core 6–8 discovery rows.
All production implementations must keep logic equivalent to this pseudocode,
even if the database or language changes in the future.
