### `docs/GEO_RULES.md`

```md
# ROOTED – Global GEO Rules (Platform-Wide)

Status: ✅ Canonical  
Scope: All ROOTED verticals and discovery/search surfaces  

This document defines the single source of truth for **location, distance, fair exposure, and geographic filtering** across ALL ROOTED verticals.

Applies to:

- ROOTED Community
- ROOTED Construction
- ROOTED Healthcare (non-clinical)
- Future verticals (Emergency, Workforce, etc.)

Related docs:

- `DISCOVERY_RULES.md`
- `DISCOVERY_IMPLEMENTATION_MAP.md`
- `DISCOVERY_BACKEND_PSEUDOCODE.md`
- `UI_BACKEND_DISCOVERY_CONTRACT.md`

No vertical is allowed to override these rules without an explicit, time-boxed exception documented in **rooted-platform** and implemented in **rooted-core**.

---

## 1. Primary GEO Rule (Fair Exposure Boundary)

All discovery, vendor display, provider cards, and search results MUST follow:

- ✅ Maximum radius: **50 miles**
- ✅ Center point:
  - User’s live location **or**
  - User’s manually selected “home” / region
- ✅ Results outside 50 miles are **never** shown by default in discovery.

Goals:

- Fair competition between vendors
- Local economic protection
- Prevent large actors from overwhelming small local providers
- Reinforce community-first behavior

---

## 2. Global Discovery Result Limits

For ANY discovery surface that shows providers:

- ✅ Minimum intended: **6 vendors**
- ✅ Maximum: **8 vendors**
- ❌ Never fewer than 6 unless there are simply fewer than 6 in range
- ❌ Never more than 8 in a single row or discovery section

Applies to:

- Home discovery rows
- Category discovery sections
- Vertical-specific discovery areas
- Featured vendor rows
- Community highlight modules

This prevents:

- Infinite scroll bias
- Algorithmic “rabbit hole” experiences
- Pay-to-dominate behavior
- UI overcrowding

---

## 3. Specialty Filtering Behavior (UI Contract Rule)

When a user presses specialty filter buttons (e.g., “Farms”, “Bakeries”, “Contractors”, “Clinics”):

System MUST:

- ✅ Keep the **6–8 card rule**
- ✅ Keep the **50-mile GEO boundary**
- ✅ Only change the **specialty parameter** (or similarly narrow filter)

System MUST NOT:

- Expand radius implicitly
- Increase result count beyond 8
- Load global or cross-region results in discovery
- Remove rotation or fairness enforcement

Filters **narrow**, they never secretly expand reach.

---

## 4. Rotation & Fair Exposure Enforcement

To avoid static “top results” that never move:

- Vendors/providers inside the 50-mile radius MUST rotate appearance across sessions.
- No provider may appear in the top discovery slots permanently.

Rotation factors MAY include:

- `last_shown_at`
- Profile completeness / activity
- Community engagement signals
- Verification / trust status

Rotation MAY NOT be driven by:

- Pure payment priority
- Hidden bidding
- Unclear algorithmic favoritism

---

## 5. Low-Data Zones (Sparse Regions)

If fewer than 6 vendors exist within 50 miles:

- ✅ Show all available vendors.
- ✅ Show helper copy such as “Showing all available local providers.”
- ❌ Do not automatically expand radius.

If radius expansion is offered as a UX feature:

- It must be **explicit** and user-initiated.
- Even then, RADIUS_MAX remains governed by this file (or a clearly documented exception).

---

## 6. Vertical Enforcement Clause

Every vertical MUST inherit and obey these GEO rules:

- Community discovery (ROOTED Community)
- Contractor discovery (Construction)
- Healthcare provider discovery (non-clinical)
- Institutional discovery (schools, nonprofits, etc.)
- Emergency provider discovery (future)

If a vertical requires a **temporary exception** (e.g. rural regions):

- Exception must be documented in `rooted-platform` governance.
- Implementation must live in a dedicated, clearly named view/RPC.
- Exception must have an explicit sunset / review date.

---

## 7. Backend API Contract (Forward Interface)

All discovery-related APIs must align to, or converge on:

```text
GET /api/discovery
  ?lat=
  &lng=
  &radius=50
  &specialty=
  &limit=8
The backend is REQUIRED to enforce:

Radius hard caps

Result count caps

Rotation eligibility

Verification & moderation filters

UI is not permitted to override these caps.

8. Anti-Gaming Rule
Explicitly disallowed behaviors:

Creating duplicate provider accounts to increase discovery odds

Selling or accepting “permanent top spot” inside discovery rows

Radius spoofing (e.g., misrepresenting location to appear local)

Algorithm tweaks intended to suppress specific competitors

Violations trigger:

Automatic suppression where detectable

Human audit review

Possible permanent removal per platform governance

9. Final Authority Clause
This document is:

The authoritative GEO law of ROOTED

The binding contract between UI, backend, and all verticals

The permanent safeguard for fairness at scale

If any implementation, PR, or AI suggestion conflicts with this file:

GEO_RULES.md + DISCOVERY_RULES.md + DISCOVERY_IMPLEMENTATION_MAP.md win.
