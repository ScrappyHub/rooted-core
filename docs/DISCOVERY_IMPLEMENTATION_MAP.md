# ROOTED – Discovery Implementation Map (UI ↔ API ↔ DB)

## Purpose

This document maps exactly how discovery rules are implemented across:
- UI Components
- Backend APIs
- Database Queries

This prevents logic drift and guarantees enforcement at every layer.

---

## 1. Backend API Enforcement

All discovery endpoints MUST enforce:

- radius = 50 miles (hard cap)
- limit = 6–8 only (no override)
- rotation = required
- verification filters = required

Canonical discovery endpoint:

/api/discovery
?lat=
&lng=
&radius=50
&specialty=
&limit=8

Backend MUST:
- Reject radius > 50
- Reject limit > 8
- Apply rotation before returning results
- Apply visibility + verification filters

---

## 2. Database Query Rules

Discovery queries MUST:

- Filter by geodistance ≤ 50 miles
- Exclude suppressed / unverified providers when required
- Apply rotation seed via:
  - last_seen
  - engagement_score
  - verification_level

No raw unrestricted SELECT queries allowed for discovery.

---

## 3. UI Component Contract

All verticals MUST use a shared component pattern:

- CuratedDiscoveryRow
- Receives data ONLY from /api/discovery
- Renders exactly 6–8 cards returned
- Does NOT:
  - paginate
  - reshuffle
  - override order
  - expand radius

---

## 4. Filter Button Behavior

Filter buttons ONLY update:

- specialty parameter

They MUST NOT:
- change radius
- change limit
- change rotation
- change ranking

---

## 5. Vertical Inheritance

This implementation map applies to:

- ROOTED Community
- ROOTED Construction
- ROOTED Healthcare
- Emergency response
- Future verticals

Violation = critical platform defect.

---

## Final Authority

This document is the executable interpretation of:

- GEO_RULES.md
- DISCOVERY_RULES.md (all verticals)
- UI_BACKEND_DISCOVERY_CONTRACT.md
