 ROOTED – GIT COMPREHENSIVE HANDOFF (v1)

> This repo is NOT a new build.  
> It is the live code + schema for the ROOTED platform, which is already architected.  
> All work from here is: **audit, polish, wiring, and hardening.**

---

## 0. How to Use This Doc

This document is the **canonical handoff** for anyone touching this repo:  
you, other devs, or AI assistants.

It defines:

- What ROOTED already is
- Which parts are shared across all verticals
- What’s allowed vs not allowed
- Backend status (Supabase + RLS)
- Frontend logic (Figma/Make → React/TS)
- The **exact order** in which to finish backend hardening

If you’re new here:

1. Read sections **1–3** to understand the platform.
2. Read **4–5** before touching any backend logic.
3. Use the AI prompt in **§8** whenever you bring in an assistant.

---

## 1. ROOTED – What This Platform Actually Is

ROOTED is a **governed multi-vertical platform** for:

- Community
- Vendors
- Institutions
- (Future) verticals like Construction and Healthcare

It is BOTH:

1. **A public-facing local directory**
2. **A dual B2B bulk + bid marketplace** for institutional procurement
3. **A community + seasonal/cultural intelligence layer** (feeds, kids, events, landmarks)

Everything runs through **one governed core**:

- Supabase (Auth + Postgres + Storage)
- Role + tier system
- Feature flags
- Seasonal & holiday intelligence
- Kids Mode safety
- Procurement and experiences
- Mapping + landmarks
- Analytics

No one is allowed to re-architect this core.

---

## 2. ROOTED Core – Shared Systems (All Verticals)

The following systems are **horizontal** and shared by ALL verticals:

- ✅ Supabase Auth
- ✅ Roles: `guest`, `individual`, `vendor`, `institution`, `admin`
- ✅ Tiers: `free`, `premium`, `premium_plus`
- ✅ `user_tiers` + `feature_flags` (jsonb)
- ✅ Providers (`providers` table) – vendors + institutions share the same base
- ✅ Media:
  - `provider_media`
  - `vendor_media`
  - Buckets:
    - `rooted-public-media`
    - `rooted-protected-media`
- ✅ Procurement:
  - `rfqs`
  - `bids`
  - `bulk_offers`
  - `bulk_offer_analytics`
- ✅ Messaging:
  - `conversations`
  - `conversation_participants`
  - `messages`
- ✅ Events + Volunteering:
  - `events`
  - `event_registrations`
- ✅ Landmarks (educational, non-commercial)
  - `landmarks`
- ✅ Feed & social:
  - `feed_items`
  - `feed_comments`
  - `feed_likes`
- ✅ Analytics:
  - `vendor_analytics_daily`
  - `vendor_analytics_basic_daily`
  - `vendor_analytics_advanced_daily`
- ✅ Account deletion flow:
  - `account_deletion_requests`
- ✅ System KV:
  - `kv_store_f009e61d` (locked, for internal configs)

All current and future verticals **inherit** this governed foundation.  
Verticals are modules. The core is law.

---

## 3. Non-Negotiable Governance Rules

These rules apply to any work in this repo:

### 3.1 Absolute “Do Not” List

- ❌ Do NOT re-architect roles or tiers
- ❌ Do NOT disable RLS on any table
- ❌ Do NOT create new tables/columns silently
- ❌ Do NOT bypass Kids Mode logic
- ❌ Do NOT auto-enable holidays or cultural sets
- ❌ Do NOT infer religion, culture, or demographics
- ❌ Do NOT monetize landmarks
- ❌ Do NOT build political messaging features
- ❌ Do NOT let vendors/institutions bypass premium_plus gates via UI-only checks

### 3.2 Allowed Work

- ✅ Audit existing logic
- ✅ Polish UI/UX
- ✅ Wire existing backend → UI
- ✅ Add **new policies** (RLS)
- ✅ Add functions / views / edge functions
- ✅ Add **NEW** columns/tables only if clearly marked in PR / commit message

---

## 4. Roles, Tiers, and Feature Flags (Single Source of Truth)

### 4.1 `user_tiers` Table

Core columns:

- `user_id` (UUID → `auth.users.id`)
- `role` – one of:
  - `vendor`
  - `institution`
  - `admin`
  - (possibly `individual` / `community`)
- `tier` – one of:
  - `free`
  - `premium`
  - `premium_plus`
- `feature_flags` (JSONB)
- `account_status` – e.g. `active`, `suspended`
- timestamps

### 4.2 Feature Flags (Examples)

**Vendor – Premium Plus:**

```json
{
  "is_kids_mode": false,
  "can_use_bid_marketplace": true,
  "can_use_bulk_marketplace": true,
  "can_view_basic_analytics": true,
  "can_view_advanced_analytics": true
}
Vendor – Premium:

json
Copy code
{
  "is_kids_mode": false,
  "can_use_bid_marketplace": false,
  "can_use_bulk_marketplace": true,
  "can_view_basic_analytics": true,
  "can_view_advanced_analytics": false
}
Free vendor/institution: similar, but no bids, no advanced analytics.

Rule: Backend policies must respect feature_flags.
UI is not trusted. DB is the final gate.

5. Frontend Logic (What the UI Must Respect)
5.1 Kids Mode
Activates via explicit flow and parental approval

Parental PIN required

Session timer

Age tiers:

3–6

7–9

10–13

13+

All kids surfaces must:

Enforce isKidsSafe === true

Hide pricing, booking, fundraising, institutions, sales CTAs

Dietary rules:

Apply ONLY to food, recipes, food videos

Must NOT block animal education / farm science

5.2 Seasonal + Holiday Intelligence
Season = always on

Date-based

Controls base palette, theming, subtle animations

Holidays = optional overlay

11 cultural holiday sets

~30+ holidays

Defaults: off for everyone

Activation requires:

Date match

User opt-in

Business opt-in

Kids Mode opt-in (if active)

Kid-safe content

If any condition fails → fallback to seasonal baseline.

5.3 Experiences
Vendors:

Create experiences

Receive & respond to requests

Institutions:

Browse + request

Track statuses

Public individuals:

Browse only, no institutional booking

Kids:

Education-only experiences, no pricing/booking

5.4 Landmarks
Educational, non-commercial

Kids-safe version via is_kids_safe

Public discovery allowed

Can be linked to experiences

Never monetized

6. Backend Hardening Roadmap (Supabase + SQL)
This is the exact order for backend work from this point on.

STEP 1 — Lock user_tiers as the Canon
Confirm rows exist for:

vendor_free / vendor_premium / vendor_premium_plus

institution_free / institution_premium_plus

admin

individual/community (if used)

Confirm feature_flags JSON matches intended behavior.

Make sure RLS for:

bids

bulk_offers

vendor_analytics_*

uses checks like:

sql
Copy code
ut.feature_flags->>'can_use_bid_marketplace' = 'true'
STEP 2 — RFQs + Bids Sanity Check
Tables:

rfqs

bids

Confirm:

Only institutions/admin can insert RFQs

Only premium_plus vendors can insert bids

Vendor sees only their own bids

Institution sees bids tied to its RFQs

Admin sees everything

No schema changes. Adjust policies only if needed.

STEP 3 — Bulk Offers + Bulk Analytics
Tables:

bulk_offers

bulk_offer_analytics

Enforce:

Only vendors insert bulk_offers

Only premium_plus vendors see advanced analytics

bulk_offer_analytics:

Writes = service_role / edge function only

Reads = vendor-own or admin-all

STEP 4 — Media / Camera / Docs / Video
Tables:

provider_media

vendor_media

Buckets:

rooted-public-media

rooted-protected-media

Rules:

Insert:

owner_user_id = auth.uid()

Update/Delete:

Only owner OR admin

Select:

Public media visible for active providers

Protected media only where appropriate

Frontend must route uploads to the correct buckets and paths.

STEP 5 — Events & Volunteering
Tables:

events

event_registrations

RLS expectations:

Events:

Vendors/Institutions/Admin insert

Public select status = 'published'

Owner/Admin update/delete

Registrations:

Any authenticated user can register

Users see their own registrations

Event host + admin can see registrations for their events

STEP 6 — Landmarks
Table:

landmarks

Enforce:

Public select is_published = true

Kids surfaces add is_kids_safe = true

Vendors/Institutions/Admin insert

Owner/Admin update/delete

No monetization logic anywhere around landmarks

STEP 7 — Messaging
Tables:

conversations

conversation_participants

messages

Confirm:

Only participants can see a conversation and its messages

Creation limited to allowed roles (vendor, institution, possibly individual)

Kids Mode cannot access B2B messaging

Optional: Admin moderation access

STEP 8 — Feed (Items, Comments, Likes) HARDENING
Tables:

feed_items

feed_comments

feed_likes

Work:

Turn on RLS for feed_comments and feed_likes.

Add policies:

Authenticated-only writes

Only authors (or admin) can update/delete their own comments/likes

Comments/likes must be tied to existing feed_items

This closes anonymous or abusive write paths.

STEP 9 — Analytics ETL (Optional Post-Launch)
Tables:

vendor_analytics_daily

vendor_analytics_basic_daily

vendor_analytics_advanced_daily

bulk_offer_analytics

Work:

Add cron / edge jobs to populate these from usage events.

Writes must be restricted to service_role or dedicated internal roles.

Vendors never write their own analytics.

STEP 10 — Final DB Launch Checklist
Before soft launch:

List all RLS-enabled tables.

Confirm there are no sensitive tables with RLS off.

For each sensitive table, answer:

Who can INSERT?

Who can SELECT?

Who can UPDATE?

Who can DELETE?

Test manually with:

vendor_free

vendor_premium

vendor_premium_plus

institution

admin

If behavior matches expectations → Backend is LOCKED.
Remaining work = UI, UX, and polish.

7. Current Vertical Status (Reality Only)
✅ ROOTED Community – active, core UX + flows present

🏗️ ROOTED Construction – in development (logic + structure reuse)

🏥 ROOTED Healthcare (non-clinical) – in development (no patient data, no records)

All other verticals are ideas, not live or promised.

8. Recommended AI Prompt for This Repo
Whenever you open a new AI chat for this repo, start with this:

text
Copy code
You are working inside my existing ROOTED codebase.

ROOTED is already architected and deployed to Supabase + a Figma/Make → React/TS-based frontend.

You are NOT allowed to:
- Rebuild roles or tiers
- Disable RLS on any table
- Add new tables/columns without clearly marking them NEW
- Change Kids Mode rules
- Change holiday/cultural consent rules
- Bypass premium_plus constraints
- Monetize landmarks

You ARE allowed to:
- Audit and polish existing logic
- Add or refine RLS policies
- Add edge functions, views, or jobs
- Wire existing backend logic into UI components
- Help with performance, readability, and structure

Always respect:
- user_tiers + feature_flags as the source of truth
- Kids Mode restrictions
- Seasonal + holiday intelligence (season baseline, holidays dual-consent)
- Media bucket rules (rooted-public-media, rooted-protected-media)

Use the BACKEND HARDENING ROADMAP in ROOTED_GIT_HANDOFF.md and tell me which STEP you’re working on when you make changes.
End of ROOTED – GIT COMPREHENSIVE HANDOFF (v1)
This file should live at the root of the repo and be treated as platform law.
