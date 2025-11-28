# ROOTED – Global GEO Rules (Platform-Wide)

## Purpose

This document defines the single source of truth for how location, distance,
fair exposure, and geographic filtering work across ALL ROOTED verticals.

These rules apply to:
- ROOTED Community
- ROOTED Construction
- ROOTED Healthcare
- Any future ROOTED vertical

No vertical is allowed to override these rules unless explicitly approved at the core level.

---

## 1. Primary GEO Rule (Fair Exposure Boundary)

All discovery, vendor display, provider cards, and search results MUST follow:

- ✅ Maximum radius: **50 miles**
- ✅ Center point:
  - User’s live location OR
  - User’s manually selected home location
- ✅ Results outside 50 miles are NEVER shown in discovery by default.

This ensures:
- Fair competition
- Local economic protection
- No large vendors overpowering small local vendors
- True community-first ranking

---

## 2. Global Discovery Result Limits (UI + Backend Coupling)

For ANY discovery surface that shows providers:

- ✅ Minimum shown: **6 vendors**
- ✅ Maximum shown: **8 vendors**
- ❌ Never fewer than 6 unless fewer than 6 exist within 50 miles
- ❌ Never more than 8 in a single row or discovery section

This rule applies to:
- Home discovery rows
- Category discovery sections
- Vertical-specific discovery
- Featured vendor rows
- Community highlights

This prevents:
- Infinite scroll bias
- Algorithmic favoritism
- Pay-to-dominate abuse
- UI overcrowding

---

## 3. Specialty Filtering Behavior (UI Contract Rule)

When a user presses specialty filter buttons (e.g.):

- Farms
- Bakeries
- Butchers
- Contractors
- Clinics
- Providers
- Specialists

The system MUST:
- ✅ Keep the **6–8 card rule**
- ✅ Keep the **50-mile GEO boundary**
- ✅ Only change the **specialty filter parameter**
- ❌ Must NOT load unlimited cards
- ❌ Must NOT expand the radius
- ❌ Must NOT show global results

Filters refine — they DO NOT expand reach.

---

## 4. Rotation & Fair Exposure Enforcement

To ensure fair visibility over time:

- Vendors/providers inside the 50-mile radius MUST rotate exposure across sessions
- No provider may appear in the same top discovery row permanently
- Rotation factors MAY include:
  - Last appearance timestamp
  - Profile activity
  - Community engagement
  - Verification status
- Rotation may NOT include:
  - Pure payment priority
  - Bid manipulation
  - Algorithm-only favoritism

This ensures:
- Small vendors get visibility
- New vendors are discoverable
- Large vendors cannot dominate

---

## 5. Fallback Behavior (Low Data Zones)

If fewer than 6 vendors exist within 50 miles:

- ✅ Show all available vendors
- ✅ Display system note: “Showing all available local providers”
- ❌ Do not automatically expand radius without user consent

User must manually expand radius if they choose.

---

## 6. Vertical Enforcement Clause

Every vertical MUST inherit and obey these rules:

- Community discovery
- Construction contractor discovery
- Healthcare provider discovery
- Institutional discovery
- Emergency provider discovery

If a vertical requires **temporary exception**:
- It must be explicitly scope-limited
- It must be documented in rooted-core
- It must auto-expire

---

## 7. Backend API Contract (Forward Interface)

All discovery-related APIs must eventually conform to:

/api/discovery
?lat=
&lng=
&radius=50
&specialty=
&limit=8

yaml
Copy code

The backend is REQUIRED to enforce:
- Radius hard caps
- Result count caps
- Rotation eligibility
- Verification filters

UI is NOT allowed to override these limits.

---

## 8. Anti-Gaming Rule

The following behaviors are explicitly disallowed:

- Artificial account duplication to boost discovery
- Paid permanent placement in discovery
- Radius spoofing to escape local limits
- Algorithm manipulation to suppress competitors

Violations trigger:
- Automatic suppression
- Audit review
- Possible permanent removal

---

## ✅ Final Authority Clause

This document is:

- The **authoritative GEO law of ROOTED**
- The **binding contract** between UI, backend, and all verticals
- The **permanent safeguard for fairness at scale**

Any violation of this document is considered a **platform-breaking defect**.
