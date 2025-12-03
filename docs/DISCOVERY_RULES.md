# ROOTED – Discovery & Curation Rules (Canonical)

Status: ✅ Canonical  
Scope: All discovery & card-based provider surfaces  

This document defines how ROOTED shows vendors and entities anywhere in the platform so that backend logic and UI **always behave the same**.

Core idea:

> Show a **small, fair, geo-bounded set** of vendors with rotation – not an endless, biased list.

Applies to:

- ROOTED Community (farms, bakeries, butchers, markets, etc.)
- Future Construction vertical (contractors, subs, specialists)
- Future Healthcare vertical (non-clinical clinics, programs, providers)
- Any vertical or page that shows “cards” of providers.

Related docs:

- `GEO_RULES.md`
- `DISCOVERY_IMPLEMENTATION_MAP.md`
- `UI_BACKEND_DISCOVERY_CONTRACT.md`
- `DISCOVERY_BACKEND_PSEUDOCODE.md`
- `MODERATION_SYSTEM.md` (for `moderation_status = 'approved'`)

---

## 1. Global Discovery Rule

For every discovery *row* or *section* that shows providers:

1. Show **6–8 curated vendors** (never more than 8 in a single row/section).
2. Vendors must be **within 50 miles** of the user’s location (see `GEO_RULES.md`).
3. Order by a fair, transparent sequence:

   1. Curation / editorial priority (e.g., `curated_rank`, badges)
   2. Quality (rating, reliability, safety, completion)
   3. Distance (closer first, within the 50-mile window)
   4. Rotation factors (`last_shown_at`, engagement)
   5. Random tie-breaking

4. If there are fewer than 6 curated vendors in range, backfill with active local vendors in the same specialty, but still cap at 8.
5. All discovery UIs must call the same **shared backend view/RPC** – no page may invent its own discovery SQL.

---

## 2. Filters & Buttons (UI Behavior)

On any discovery screen with filters (chips/tabs/buttons):

- **Default “All” view**:
  - Mixed curated vendors for the area.
- When the user chooses a filter (e.g. “Farms”, “Bakeries”, “Butchers”):
  - Call the same discovery endpoint with `specialty = selected filter`.
  - Keep:
    - Radius: 50 miles (max)
    - Limit: 6–8 cards
    - Rotation and fairness rules

Examples:

- “Featured Near You” → `specialty` omitted.
- “Farms Near You” → `specialty = FARM`.
- “Bakeries Near You” → `specialty = BAKERY`.

Behavior MUST be consistent across web and mobile.

Filters **refine** – they do NOT expand reach.

---

## 3. Backend Contract (High-Level)

Canonical API (conceptual):

```text
GET /api/vendors/curated
  ?lat=<required>
  &lng=<required>
  &radiusMiles=50      # optional; backend clamps to ≤ 50
  &specialty=<code>    # optional
  &limit=8             # optional; backend clamps to 6–8
Required behaviors:

Only return active and approved vendors:

providers.is_active = true

providers.moderation_status = 'approved' or via public view

Filter vendors to within 50 miles of (lat, lng).

If specialty is provided, filter by that specialty_types.code.

Sort according to the fairness rules above.

Return at most limit (capped between 6–8).

4. Frontend Pattern
Example shared components:

CuratedVendorSection

CuratedDiscoveryRow

These components must:

Always call the canonical discovery endpoint or RPC.

Pass:

User location

Optional specialty

Radius = 50 (or omitted so backend defaults)

limit = 8

Render a maximum of 6–8 cards for that section.

Render filter chips above the cards and re-call the same endpoint when filters change.

No page should ever fetch or display “all vendors” for discovery.

5. Low-Data Zones
If fewer than 6 vendors exist within 50 miles:

✅ Show all available vendors (even if only 1–5).

✅ Display UX note, e.g.: “Showing all available local providers.”

❌ Do not auto-expand radius behind the scenes.

If the user wants a wider search, it must be a manual action (e.g. “expand search radius” control), and even then GEO_RULES.md governs the maximum.

6. Non-Negotiables
No discovery row may show more than 8 cards.

No discovery surface may ignore:

GEO boundary

Moderation status

Sanctuary / kids / municipal discovery rules

The 50-mile rule and 6–8 card layout are platform law, not just “a UI choice”.

Paid permanent placement is not allowed in these rows. Any future paid promotion must live in a clearly separated surface.

Any deviation from these rules is a platform-breaking defect and must be treated as such in QA and abuse testing.

7. Canonical Status
This file is the discovery doctrine that binds:

UI builders

API authors

DB engineers

Future vertical teams

If any new feature, vertical, or AI suggestion conflicts with these rules:

DISCOVERY_RULES.md + GEO_RULES.md + UI_BACKEND_DISCOVERY_CONTRACT.md win.
