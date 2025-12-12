# ROOTED — FULL SYSTEM DEBUG GUIDE (HONEST PASS)

Status: ✅ Canonical  
Scope: ROOTED Core + ROOTED Agriculture (LIVE vertical only)  
Authority Chain:
ROOTED_PLATFORM_CONSTITUTION.md  
→ ROOTED_GIT_HANDOFF.md  
→ ROOTED_DEBUG_TOOLKIT_CORE.md  
→ This File (UI + Live-System Debug Only)

This is the single **honest debug authority** for:

✅ Live  
✅ Fragile  
✅ Stable  
✅ Designed-only  
✅ Disabled by doctrine  

If any UI appears to exist but this guide says it is OFF → it is OFF.  
If a feature exists in schema but not in this file → it is NOT production-ready.

Marketing language is forbidden here.

---

## 0. How To Use This Guide

When debugging ROOTED:

1. Start at **Core Platform** (Supabase, auth, RLS)
2. Then debug **ROOTED Community** (the ONLY live vertical)
3. Then apply **Construction Hardening Checklist** (backend-only)
4. Treat **all other verticals as documentation only**

Never assume a feature exists because:
- A Figma design shows it
- A roadmap mentions it
- Another repo describes it

This document is the **truth of what can be debugged today**.

---

## 1. Debug Layers Overview

### 1.1 Core Platform (Authoritative)

- Supabase project
- `user_tiers`, `feature_flags`
- Providers, media, GEO, analytics
- RLS policies and security enforcement

### 1.2 Community Vertical (✅ LIVE)

- Directory (vendors / institutions / landmarks)
- Feeds (restricted)
- Events & volunteering
- Kids Mode (front-end enforced)
- Seasonal & holiday overlays (logic present, some wiring pending)
- Basic analytics surface

### 1.3 Construction Vertical (🏗 PRE-PRODUCTION)

- Schemas & workflows written
- Audit & hardening docs exist
- Backend only — **NO live UI**

### 1.4 Future Verticals (🧩 PLANNING ONLY)

- Healthcare
- Arts & Culture
- Education
- Environment
- Disaster, Emergency, Workforce, Utilities, etc.

Repos exist. Apps do NOT.

---

## 2. Global Debug Tools (What You Are Allowed to Use)

- Supabase Dashboard  
- Table Editor  
- SQL Editor  
- RLS Viewer  
- Browser Dev Tools  
- Mobile Responsive Tools  
- Feature Flag Toggles  
- Network Logs  
- Supabase Logs  

Edge logs & jobs = future, not yet active.

---

## 3. CORE PLATFORM — DEBUG CHECKLIST

### 3.1 Auth & `user_tiers`

Goal: Every signed-in user has **one correct row**.

Check:

- role ∈ vendor | institution | admin | individual
- tier ∈ free | premium | premium_plus
- feature_flags JSON exists

Confirm in UI:
- Correct dashboards
- No tier leakage

Failures mean:
- Bad row
- Or RLS block

---

### 3.2 RLS & Permissions (CRITICAL)

High-risk tables:

- providers
- provider_media, vendor_media
- rfqs, bids, bulk_offers
- conversations, messages
- events, event_registrations
- landmarks
- feed_items, feed_comments, feed_likes
- vendor_analytics_*

Test:

- SELECT
- INSERT
- UPDATE own
- DELETE where allowed

If user sees too much → RLS is too weak  
If insert fails → RLS working but needs precision

---

### 3.3 Media & Storage

Buckets:

- rooted-public-media
- rooted-protected-media

Check:

- Vendors can upload to own folders
- Public media viewable without login
- Protected media never opens in private tabs

---

### 3.4 GEO & Discovery

Check:

- Map filtering
- Featured providers intentional only
- No municipal back-end data leaking

If municipality appears → UI bug + mis-flagged record

---

## 4. COMMUNITY VERTICAL — UI & FLOW DEBUG

### 4.1 Directory

Search:

- Name
- Category
- Distance

Confirm:

- No duplicates
- No closed vendors
- No admin-only fields leaking

---

### 4.2 Feed

- Low-social emphasis
- No anonymous posts
- Kids Mode never sees full feed

If Kids Mode shows comments or engagement spam → violation

---

### 4.3 Events & Volunteering

- Kids-safe filtering works
- Prices hidden in Kids Mode
- Registration confirmations clear

---

### 4.4 Kids Mode (SAFETY-CONTROLLED)

Once enabled:

- ❌ No prices
- ❌ No RFQs
- ❌ No messaging
- ❌ No fundraising
- ❌ No posting

If commerce appears → **Critical Safety Violation**

---

### 4.5 Seasonal & Holiday UI

Holiday overlay requires ALL:

- Date match
- User opt-in
- Business opt-in
- Kids Mode safety

If holiday shows without consent → logic bug

---

### 4.6 Support / Contact

- Must be visible
- Must email successfully

---

## 5. CONSTRUCTION — BACKEND ONLY

No UI exists.

You may only debug:

- Schema accuracy
- RLS
- Audit checklist steps

---

## 6. FUTURE VERTICALS — DOC REVIEW ONLY

- No live apps
- Only review for:
  - Role conflicts
  - Discovery leaks
  - Safety issues

---

## 7. GLOBAL HONEST GAPS

🔴 Payments not fully live  
🔴 Analytics ETL not automated  
🟠 Messaging moderation incomplete  
🟠 Construction hardening incomplete  
✅ Core auth + roles stable  

---

## 8. WHEN STUFF BREAKS

1. Who am I logged in as?
2. Does `user_tiers` match?
3. Is RLS blocking me?
4. Is this allowed by:
   - Kids Mode?
   - Tier?
   - Feature flag?
5. Is this feature even built?

Then file bug:

Role  
Mode  
Page  
Expected  
Actual  
