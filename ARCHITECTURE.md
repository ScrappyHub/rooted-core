# ROOTED Core Architecture — Version 1

ROOTED Core is the **single Supabase-backed backend** that powers all live ROOTED products.

It enforces:
- Governance law
- Role & tier access
- Discovery controls
- Moderation
- Billing
- Kids Mode enforcement (at the data layer)
- Sanctuary & nonprofit restrictions

At present, ROOTED Core powers exactly **one** production vertical:

> ✅ ROOTED Community — local food, vendors, events, landmarks

All other verticals reuse this same core when/if they are activated.

---

## 1. Core Architecture Layers

### 1.1 Identity & Governance Layer
- `auth.users`
- `public.user_tiers`
- `feature_flags`
- `account_status`
- Admin RPCs with audit logging

This layer controls:
- Roles
- Tiers
- Feature access
- Suspensions
- Admin permissions
- Power boundaries

---

### 1.2 Provider & Institution Layer
- `providers`
- `provider_media`
- `badges`
- `compliance_overlays`

Supports:
- Vendors
- Institutions
- Nonprofits & sanctuaries
- Trust indicators
- Youth safety flags
- Discovery eligibility

---

### 1.3 Discovery & GEO Layer
- Discovery views
- Distance & radius filtering
- Rotation logic
- Seasonal overlay logic
- Landmark overlays

This layer is governed by:

→ `UI_BACKEND_DISCOVERY_CONTRACT.md`  
→ `DISCOVERY_RULES.md`  
→ `GEO_RULES.md`

---

### 1.4 Events & Experiences Layer
- Events
- Volunteer opportunities
- Kid-safe tagging
- Moderation state
- Calendar ordering
- Seasonal experience locking

---

### 1.5 Moderation & Safety Layer
- `moderation_queue`
- `moderation_status`
- Admin approval RPCs
- Rejection reasons
- Visibility gating

Nothing becomes public without passing this layer.

---

### 1.6 Messaging Layer
- Conversations
- Participants
- Messages
- Role-gated access
- No Kids Mode access

---

### 1.7 Billing & Monetization Layer
- Stripe integration
- Subscriptions
- Tier enforcement
- Feature unlocking
- Abuse monitoring

Governed by:

→ `BILLING_ARCHITECTURE.md`  
→ `BILLING_ABUSE_TEST_MATRIX.md`

---

### 1.8 Notifications Layer
- System notifications
- Event updates
- Moderation updates
- Billing alerts
- Admin actions

---

## 2. Canonical Law Inheritance

ROOTED Core is an **enforcement layer**, not a law-definition layer.

All legal authority originates in:

→ `rooted-platform/governance/`  
→ `ROOTED_PLATFORM_CONSTITUTION.md`

ROOTED Core:

✅ Implements law  
❌ Does NOT create law  
❌ Does NOT override law  
❌ Does NOT invent power  

---

## 3. Vertical Reuse Model

All verticals reuse:

- The same identity tables  
- The same provider tables  
- The same events system  
- The same moderation engine  
- The same billing layer  
- The same Kids Mode enforcement  
- The same NGO / sanctuary protections  

Verticals are **configuration overlays**, not parallel systems.

---

## 4. Chain of Authority

1. ROOTED Platform Constitution  
2. Platform Governance Laws  
3. ROOTED Core RLS + RPCs  
4. Application UI  

UI **cannot override** Core.  
Core **cannot override** Platform Law.

---

## 5. Production Status

- ✅ ROOTED Community → Live
- 🚧 All others → Non-production, docs only

This architecture is considered **LOCKED for V1 Stability**.
