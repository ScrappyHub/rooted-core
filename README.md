# ROOTED Core — Backend & Governance Enforcement

ROOTED Core is the **single Supabase-backed backend** that powers all live ROOTED products.

Today it serves exactly one production vertical:

> ✅ **ROOTED Community** — local food, vendors, events, landmarks

All future verticals (Construction, Healthcare, Emergency, Workforce, etc.) will **reuse this same core** when/if they go live.

This repository contains:

- Database schema & migrations
- Row Level Security (RLS) policies
- Views, RPCs, and helper functions
- Billing & Stripe integration architecture
- Discovery, GEO, moderation, and notifications systems
- Canonical backend debug and QA docs

It does **not** contain front-end application code.

---

## 🛡 Governance Boundaries

This repository:

- Does **NOT** define new roles, tiers, or political/ethical laws  
- Does **NOT** change Kids Mode doctrine, sanctuary protection, or data-sovereignty law  
- Does **NOT** override the ROOTED Platform Constitution

All **governance and access law** lives in the **platform brain** repo:

> `rooted-platform` (ROOTED Platform / governance, law, and roadmap)

ROOTED Core is an **implementation repo**:

- It implements schema, RLS, and RPCs **according to** the laws in `rooted-platform`
- It may evolve technically (new tables, policies, functions), but  
  it may **never** contradict platform governance

Any change that attempts to bypass ROOTED governance is **invalid by design** and must be reverted.

---

## ✅ Live Production Vertical

This backend currently powers the **only live user-facing product**:

> **ROOTED Community** — directory, maps, vendors, events, landmarks

All other ROOTED vertical repositories (Construction, Healthcare, Emergency, Workforce, etc.) are:

- Planning and governance docs only  
- Not active products  
- Not launch promises or public announcements

This backend must always obey platform governance defined in:

- `rooted-platform/docs/` — platform-wide law and roadmap  
- `rooted-core/docs/` — backend implementation rules (moderation, discovery, billing, notifications, etc.)

Front-end apps (for example the `rooted-community` UI repo) are required to match **both**:

1. Platform governance (`rooted-platform`)  
2. Backend contracts and views defined here in `rooted-core`

---

## 📁 Repository Structure (High-Level)

- `/supabase` or equivalent  
  - Database schema & migrations  
  - Policy and function definitions  

- `/docs`  
  - `ADMIN_AUTH_MODEL.md` — how admin access and auth work  
  - `BILLING_ARCHITECTURE.md` — Stripe and billing flows  
  - `BILLING_ABUSE_TEST_MATRIX.md` — pre-launch abuse tests for billing  
  - `DISCOVERY_RULES.md` + `GEO_RULES.md` — global discovery & GEO contracts  
  - `MODERATION_SYSTEM.md` — canonical moderation pipeline  
  - `NOTIFICATIONS_SYSTEM.md` — notifications & delivery workers  
  - `ROOTED_COMMUNITY_UI_QA.md` — Community UI QA link-back reference  
  - `ROOTED_DEBUG_TOOLKIT_CORE.md` — backend debug toolkit  
  - `ROOTED_PLATFORM_CONSTITUTION.md` (reference copy)  
  - `STRIPE_INTEGRATION_CHECKLIST.md` — Stripe wiring safety checklist  

- Root files  
  - `.env.example` — required env vars for local dev  
  - `ARCHITECTURE.md` — core backend architecture overview  
  - `SECURITY.md` — security posture and expectations  
  - `UI_BACKEND_DISCOVERY_CONTRACT.md` — UI ↔ backend discovery contract (canonical)

(Exact file list may evolve, but anything in `/docs` is considered **canonical implementation guidance**.)

---

## 🔒 Rules for Contributors & AI

Any work in this repo must follow these hard rules:

- ❌ Do **not** invent new roles, tiers, or power classes  
- ❌ Do **not** disable or weaken RLS  
- ❌ Do **not** bypass moderation, Kids Mode, or sanctuary restrictions  
- ❌ Do **not** add new market types (RFQ classes, ad systems, etc.) without explicit platform-repo law

- ✅ You **may**:
  - Add or refine views and RPCs that enforce existing law  
  - Add new abuse tests, debug tooling, and QA scripts  
  - Harden billing, notifications, GEO, and discovery implementations  
  - Improve performance and observability (logs, metrics)  

All structural or legal changes must originate in:

> `rooted-platform/governance/`

and then be implemented here with matching schema, RLS, and RPCs.

---

## 🧭 Source of Truth

Think of the ROOTED repos as:

- `rooted-platform` → **Constitution & law** (what is allowed)  
- `rooted-core` → **Backend enforcement** (how law is enforced in DB + APIs)  
- `rooted-community` → **Live UI** (how users see and interact with Community)

If these disagree:

1. Platform governance (`rooted-platform`) wins over everything.  
2. Backend enforcement (`rooted-core`) wins over UI behavior.  

This README exists to keep that chain of authority crystal clear.
