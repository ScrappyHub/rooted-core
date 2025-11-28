# ROOTED – Discovery & Curation Rules

## Purpose

This document defines how ROOTED shows vendors and entities anywhere in the platform so that the backend logic and UI always behave the same.

Core idea:  
> Show a small, curated set of vendors with a fair, geo-based rotation – not an endless list.

This applies to:
- ROOTED Community (farms, bakeries, butchers, markets, etc.)
- Future Construction vertical (contractors, subs, specialists)
- Future Healthcare vertical (clinics, programs, providers)
- Any new vertical or discovery surface that shows “cards” of providers.

---

## Global Discovery Rule

For every discovery section that shows providers:

1. Show **6–8 curated vendors** (never more than 8 in a single row/section).
2. Vendors must be **within 50 miles** of the user’s current or chosen location.
3. Order by:
   1. Curation level / curated_rank  
   2. Quality (rating, reliability, safety, etc.)  
   3. Distance (closer first, within the 50-mile window)
4. If there are fewer than 6 curated vendors in range, backfill with active local vendors in the same specialty, still capped at 8.
5. All discovery UIs should use **one shared backend function** to fetch these vendors – no screen should invent its own logic.

---

## Filters & Buttons (UI Behavior)

On any screen where the user can filter (chips / tabs / buttons):

- Default view:  
  - Mixed curated vendors for the area (“All” filter).
- When the user taps a filter (e.g., “Farms”, “Bakeries”, “Butchers”):
  - Call the same **curated vendor** function, but with `specialty = selected filter`.
  - Still show only **6–8 cards**.
  - Still honor **50-mile radius**.

Examples:
- “Featured Near You” → no specialty, just curated list.
- “Farms Near You” → `specialty = farm`.
- “Bakeries Near You” → `specialty = bakery`.

This must be consistent across web and mobile.

---

## Backend Contract (High-Level)

Every vertical should eventually implement a shared API like:

`GET /api/vendors/curated`

Query parameters:
- `lat` – user latitude
- `lng` – user longitude
- `radiusMiles` (optional, default **50**)
- `specialty` (optional, e.g. `"farm"`, `"bakery"`, `"contractor"`)
- `limit` (optional, default **8**, max 8)

Required behaviors:
- Only return **active** vendors.
- Filter vendors to within `radiusMiles` of `lat/lng`.
- If `specialty` is provided, filter by that specialty.
- Sort by:
  - curated vendors first,
  - then highest quality,
  - then shortest distance.
- Return at most `limit` results.

---

## Frontend Pattern

Each UI section should use a reusable component, for example:

- `CuratedVendorSection` in ROOTED Community
- `CuratedContractorSection` in Construction

These components:
- Always call `/api/vendors/curated` with:
  - user location
  - optional specialty
  - `radiusMiles = 50`
  - `limit = 8`
- Render at most 2 rows of cards (6–8 cards total).
- Show filter buttons/chips above the cards.
- Refresh cards when filters change, using the **same** API.

---

## Non-Negotiables

- No page should bypass this and pull “all vendors” directly.
- No page should show more than 8 cards in a single curated section.
- The 50-mile rule and 6–8 card layout are **platform-level rules**, not “just a UI choice”.
