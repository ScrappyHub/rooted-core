# ROOTED – Discovery Implementation Map (UI ↔ API ↔ DB)

Status: ✅ Canonical  
Scope: All discovery surfaces in ROOTED Core  

This document maps **how discovery rules are implemented end-to-end** across:

- UI components
- Backend APIs
- Database queries / views

It prevents logic drift and guarantees that **GEO_RULES**, **DISCOVERY_RULES**, and the **UI_BACKEND_DISCOVERY_CONTRACT** are all enforced together.

Related docs:

- `DISCOVERY_RULES.md`
- `GEO_RULES.md`
- `UI_BACKEND_DISCOVERY_CONTRACT.md` (rooted-core root)
- `DISCOVERY_BACKEND_PSEUDOCODE.md`

---

## 1. Backend API Enforcement

All discovery endpoints MUST enforce:

- `radius <= 50` miles (hard cap, see `GEO_RULES.md`)
- `limit` between **6–8** (no override, see `DISCOVERY_RULES.md`)
- Rotation rules (see `DISCOVERY_BACKEND_PSEUDOCODE.md`)
- Verification / visibility filters (platform trust layer)

Canonical discovery endpoint shape:

```text
GET /api/discovery
  ?lat=<required>
  &lng=<required>
  &radius=50        # optional, backend clamps to ≤ 50
  &specialty=<code> # optional, from specialty_types.code
  &limit=8          # optional, backend clamps to 6–8
Backend MUST:

Reject / clamp radius > 50

Clamp limit to [6, 8]

Apply rotation before returning results

Apply visibility + verification filters inside the query, not in UI

2. Database Query Rules
Discovery SQL (tables or views) MUST:

Filter by geodistance ≤ 50 miles from the supplied point

Exclude:

Suspended providers

Soft-deleted providers

Providers failing trust / verification filters where required

Apply rotation seed via some combination of:

last_shown_at

engagement_score

created_at

randomized tie-breaker (random())

Forbidden:

Raw SELECT * FROM providers for discovery surfaces

Queries that ignore moderation_status = 'approved' (see MODERATION_SYSTEM.md)

Queries that bypass sanctuary / kids / municipal discovery rules

All discovery queries should be implemented via views or RPCs defined in this repo, not handwritten ad-hoc SQL in each client.

3. UI Component Contract
All verticals MUST use a shared component pattern, for example:

CuratedDiscoveryRow / CuratedVendorSection

Characteristics:

Receives its data only from /api/discovery (or the canonical discovery RPC/view).

Renders exactly the 6–8 cards returned.

Does not:

Paginate within a single discovery row

Reshuffle or re-order cards

Override the backend limit

Auto-expand radius

If the backend returns fewer than 6 providers:

Component shows all returned cards.

Component displays a “low data zone” helper text (per UX spec).

UI must treat backend as source of truth for:

Count

Order

Radius

Curation

4. Filter Button Behavior
Filter controls (chips / buttons / tabs) may only update:

specialty (e.g., FARM, BAKERY, GENERAL_CONTRACTOR)

Optional lightweight filters explicitly allowed by DISCOVERY_RULES.md

They MUST NOT:

Change radius beyond what backend already enforces

Change result limit

Disable rotation or fairness rules

Change ranking weights

Pattern:

User taps “Farms” → call /api/discovery with specialty=FARM

User taps “Bakeries” → specialty=BAKERY

Everything else (radius, limit, rotation) remains unchanged.

5. Vertical Inheritance
This implementation map applies to every vertical that uses provider discovery:

✅ ROOTED Community

✅ ROOTED Construction (future)

✅ ROOTED Healthcare (future, non-clinical)

✅ Emergency / disaster & workforce verticals (future)

✅ Any future vertical that wants discovery rows

Using discovery at all means inheriting:

GEO_RULES.md

DISCOVERY_RULES.md

UI_BACKEND_DISCOVERY_CONTRACT.md

This DISCOVERY_IMPLEMENTATION_MAP.md

Violation = critical platform defect.

6. Final Authority
This document is the executable wiring diagram for discovery:

GEO_RULES.md → defines the radius + locality law

DISCOVERY_RULES.md → defines fairness, caps, and curation doctrine

UI_BACKEND_DISCOVERY_CONTRACT.md → defines the UI contract (6–8 cards, no pay-to-win)

DISCOVERY_BACKEND_PSEUDOCODE.md → defines the backend algorithm

If any implementation in UI, API, or DB conflicts with these:

These four discovery documents, together, win.
