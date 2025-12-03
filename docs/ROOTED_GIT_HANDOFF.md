# ROOTED — GIT COMPREHENSIVE HANDOFF (PLATFORM LAW)

This file is governed by:

- ROOTED_PLATFORM_CONSTITUTION.md
- ROOTED_CORE_ARCHITECTURE.md
- ADMIN_AUTH_MODEL.md
- MODERATION_SYSTEM.md
- NOTIFICATIONS_SYSTEM.md
- ROOTED_DEBUG_TOOLKIT_CORE.md

If any PR, commit, migration, UI feature, or AI output conflicts with this file:
→ **This file wins.**

No exceptions.

---

All work from here is:
- Audit
- Polish
- Wiring
- Hardening

---

## 0. How to Use This Doc

This document is the canonical handoff for anyone touching this repo:
- You (Alec)
- Other devs
- Designers
- Advisors
- AI assistants

It defines:

- What ROOTED already is
- Which parts are shared across all verticals
- What’s allowed vs not allowed
- Backend status (Supabase + RLS)
- Frontend logic (Figma/Make → React/TS)
- Account governance, opt-in / opt-out, and deletion flow
- Seasonal + featured discovery logic
- The exact order in which to finish backend hardening

If you’re new here:

1. Read sections **1–3** to understand the platform.
2. Read **4–7** before touching any backend logic.
3. Use the AI prompt in **§10** whenever you bring in an assistant.

---

## 1. ROOTED – What This Platform Actually Is

ROOTED is a governed multi-vertical platform for:

- Community
- Vendors
- Institutions
- Future verticals (Construction, Arts & Culture, Environment, Healthcare*, etc.)

It is BOTH:

- A **public-facing local directory**
- A **dual B2B bulk + bid marketplace** for institutional procurement
- A **community + seasonal/cultural intelligence layer** (feeds, kids, events, landmarks)

Everything runs through **one governed core**:

- Supabase (Auth + Postgres + Storage)
- Role + tier system
- Feature flags
- Account governance (admin controls, opt-in/opt-out, deletion)
- Seasonal & holiday intelligence
- Kids Mode safety
- Procurement & experiences
- Mapping + landmarks
- Analytics

> **No one is allowed to re-architect this core.**

---

## 2. ROOTED Core – Shared Systems (All Verticals)

The following systems are **horizontal** and shared by **ALL verticals**:

### 2.1 Identity & Access

- `auth.users`
- `public.user_tiers` (roles, tiers, feature_flags, account_status)
- Account governance layer:
  - `public.user_admin_actions` (admin audit log)
  - `public.account_deletion_requests` (deletion pipeline)
- Admin helpers / views:
  - `public.admin_user_accounts` (VIEW)
  - `public.admin_get_user_accounts()` (RPC)
  - `public.is_admin()` (check function)

### 2.2 Providers & Media

- `providers` (shared base for vendors, institutions, orgs, nonprofits, sanctuaries)
- `provider_media`
- `vendor_media`

Buckets:

- `rooted-public-media`
- `rooted-protected-media`

### 2.3 Procurement

- `rfqs`
- `bids`
- `bulk_offers`
- `bulk_offer_analytics`

### 2.4 Messaging

- `conversations`
- `conversation_participants`
- `messages`

### 2.5 Events, Volunteering, Landmarks

- `events`
- `event_registrations`
- `landmarks`

### 2.6 Feed & Social

- `feed_items`
- `feed_comments`
- `feed_likes`

### 2.7 Analytics

- `vendor_analytics_daily`
- `vendor_analytics_basic_daily`
- `vendor_analytics_advanced_daily`
- `bulk_offer_analytics`

### 2.8 Config / KV

- `kv_store_f009e61d` (locked, internal configs)
- `app_settings` (for global feature flags like `community_uploads`)

> All current and future verticals inherit this governed foundation.  
> Verticals are **modules**. The core is **law**.

---

## 3. Non-Negotiable Governance Rules

These rules apply to **any work in this repo**.

### 3.1 Absolute “Do Not” List

- ❌ Do NOT re-architect roles or tiers
- ❌ Do NOT disable RLS on any table
- ❌ Do NOT create new tables/columns silently
- ❌ Do NOT bypass Kids Mode logic
- ❌ Do NOT auto-enable holidays or cultural sets
- ❌ Do NOT infer religion, culture, or demographics
- ❌ Do NOT monetize landmarks
- ❌ Do NOT build political messaging features
- ❌ Do NOT let vendors/institutions bypass `premium_plus` gates via UI-only checks
- ❌ Do NOT bypass account governance (user_tiers, feature_flags, account_status)
- ❌ Do NOT bypass opt-in / opt-out or deletion flows
- ❌ Do NOT expose community member profiles publicly

### 3.2 Allowed Work

- ✅ Audit existing logic
- ✅ Polish UI/UX
- ✅ Wire existing backend → UI
- ✅ Add new policies (RLS)
- ✅ Add functions / views / edge functions / jobs
- ✅ Add NEW columns/tables **only if clearly marked** in PR / commit
- ✅ Extend debug & admin tooling inside the existing doctrine

---

## 4. Roles, Tiers, Feature Flags — AND Governance

### 4.1 `user_tiers` Table (Source of Truth)

Core columns:

- `user_id` (UUID → `auth.users.id`)
- `role` – one of:
  - `guest` (implicit via no auth)
  - `individual` / `community`
  - `vendor`
  - `institution`
  - `admin`
- `tier` – one of:
  - `free`
  - `premium`
  - `premium_plus`
- `feature_flags` (JSONB)
- `account_status` – e.g.:
  - `active`
  - `suspended`
  - `locked`
  - `pending_deletion`
- `created_at`, `updated_at`

> **This table is the single source of truth for:**
> - Access
> - Monetization
> - Vertical eligibility
> - Feature availability

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
Free vendor / institution: similar, but:

No bids

No advanced analytics

Possibly no bulk tools

Sanctuary / Rescue Feature Flags (Canonical Pattern)
For nonprofit sanctuary / rescue entities:

json
Copy code
{
  "sanctuary_rescue": "true",
  "commercial_access": "disabled",
  "provider_premium_allowed": "false",
  "provider_premium_plus_allowed": "false",
  "bid_market_access": "false",
  "bulk_procurement_access": "false"
}
4.3 Governance Rules from user_tiers
account_status != 'active' → the user is locked out platform-wide

role → determines all vertical permissions

tier → controls premium vs premium_plus tools

feature_flags → controls:

Vertical access (can_use_construction, can_use_arts_culture, etc.)

Sanctuary / rescue non-commercial state

Experimental/beta toggles

Opt-ins (marketing, overlays) until a dedicated user_consents system exists

Backend policies must respect feature_flags.
The DB is the final gate. UI is never trusted.

5. Frontend Logic (What the UI Must Respect)
5.1 Kids Mode
Kids Mode activates via explicit flow + parental governance:

Parental PIN required

Session timer

Age tiers:

3–6

7–9

10–13

13+

All Kids surfaces must:

Enforce isKidsSafe === true (from content / events / landmarks)

Hide pricing, booking, fundraising, institutions, sales CTAs

Never expose B2B messaging

Never surface community uploads

Dietary rules:

Apply ONLY to food, recipes, and food videos

Must NOT block animal education / farm science content

5.2 Seasonal + Holiday Intelligence
Season = always on (baseline mode)

Date-based

Controls palette, theming, subtle dynamics

Holidays = optional overlay

~11 cultural sets

~30+ holidays

Defaults: OFF for everyone

Activation requires ALL:

Date match

User opt-in

Business opt-in

Kids Mode opt-in (if active)

Kid-safe content

If any condition fails → fall back to seasonal baseline.

Seasonal Featured Providers (Canonical)
View: seasonal_featured_providers

Helper function: current_season(p_date date default current_date)

Used by:

Home “featured” carousels

Map vendor highlighting

Directory ordering

Season debug queries live in the Debug Toolkit (separate doc).

5.3 Experiences
Vendors:

Create experiences

Receive & respond to requests

Institutions:

Browse + request

Track statuses

Public individuals:

Browse only (no institutional booking)

Kids:

Education-only experiences

No pricing / no booking

5.4 Landmarks
Educational, non-commercial

Kids-safe flavor via is_kids_safe

Public discovery allowed

Can be linked to experiences

Never monetized

6. Account Governance, Opt-In/Out & Deletion
6.1 Admin Audit Log
public.user_admin_actions records every admin action:

admin_id

target_user_id

action_type

details (JSONB)

created_at

Required for:

Status changes

Role changes

Tier changes

Feature flags updates

6.2 Admin User View & RPC
public.admin_user_accounts (VIEW)

user_id

email

role

tier

account_status

feature_flags

deletion request status

public.admin_get_user_accounts() (RPC)

Security definer

Uses public.is_admin() checks

Used by the Admin Panel — never query raw tables directly in UI.

6.3 Opt-In / Opt-Out (Core-Level)
Opt-in/out is now handled at ROOTED Core:

Governs:

Seasonal overlays

Cultural overlays

Marketing

Notification channels

Vertical participation (where appropriate)

Enforced via:

feature_flags

(Future) user_consents system

Discovery rules in Community / Construction / Arts & Culture

6.4 Account Deletion Pipeline
public.account_deletion_requests:

When user requests deletion:

status = 'pending', created_at set

Account is immediately restricted: no new content, messaging, or marketplace actions

Admin panel:

Approves / processes:

in_progress

completed

Deletion behavior:

PII anonymized where required

Provider/institution records soft-detached

Audit rows preserved

Legal chain-of-custody maintained

This pipeline is canonical, civic-grade, and cannot be bypassed.

7. Discovery, Badges & Community Safety
7.1 Vendor Discovery Badges (Specialty)
Vendors (businesses) get discovery badges that:

Power search

Power map filters

Drive featured placement

Show as social proof

Examples:

VENDOR_FARM

VENDOR_BAKERY

VENDOR_MARKET

VENDOR_ORCHARD

VENDOR_FOOD_TRUCK

VENDOR_FARM_STAND

etc. (see badge seed list)

These live in:

badges (badge_type = 'vendor_specialty')

provider_badges (link vendors → badges)

7.2 Institution Tags (Classification Only)
Institutions do not get discovery specialty badges. They get classification tags:

Community Service

Correctional Facilities

Government Agencies

Municipalities / Public Agencies

Nonprofits

Schools & Universities

Youth Programs

Sanctuary / Rescue (mission-only)

Stored as:

badges with badge_type = 'institution_tag'

Connected via provider_badges

Used for:

Map filters

Compliance overlays

Labeling in institution profiles

NOT used for discovery ranking or commercial promotion.

7.3 Sanctuary / Rescue Rules
Sanctuary / rescue entities are:

Entity type: nonprofit sanctuary / rescue

Access tier: Community + Volunteer only

Commercial access: Disabled

They:

✅ Can apply to ROOTED

✅ Can post volunteer events

✅ Can appear in community discovery

❌ Cannot use Provider Premium / Premium Plus

❌ Cannot access bids, bulk procurement, paid tools

Enforced via:

Institution tags

feature_flags with commercial_access = 'disabled'

7.4 Community Uploads (Disabled but Possible)
Community uploads exist in schema, but:

Global toggle: community_uploads_enabled() (backed by app_settings)

RLS on community upload tables:

FOR INSERT requires community_uploads_enabled() = true

For now:

❌ Public, non-admin community uploads are blocked

✅ Admin seeding allowed

✅ Read-only viewing allowed (where safe)

❌ Kids Mode never allowed to upload or manage spots

This is a safety-first hibernation until culture/experience loops are ready.

7.5 Social Proof & Privacy
Provider profiles (vendors, institutions, sanctuaries):

✅ Public

✅ Discovery-eligible

✅ Show impact metrics, badges, etc.

Community member profiles:

❌ Not public

✅ Private dashboard showing their own:

Volunteer history

Impact stats

Badges (if any)

❌ Never discoverable through search/map

Impact rollups:

Provider-level impact (public)

User-level impact (private)

8. Backend Hardening Roadmap (Supabase + SQL)
This is the order of operations for backend hardening.

STEP 1 — Lock user_tiers as Canon
Confirm rows exist for:

vendor_free, vendor_premium, vendor_premium_plus

institution_free, institution_premium_plus

admin

individual / community (if used)

Confirm feature_flags JSON matches intended behavior.

Ensure RLS for:

bids

bulk_offers

vendor_analytics_*

Uses checks like:

sql
Copy code
ut.feature_flags->>'can_use_bid_marketplace' = 'true'
STEP 2 — RFQs + Bids Sanity Check
Tables:

rfqs

bids

Confirm:

Only institutions/admin can INSERT into rfqs

Only premium_plus vendors can INSERT into bids

Vendors see only their bids

Institutions see bids for their RFQs

Admin sees everything

No schema changes. Adjust policies only.

STEP 3 — Bulk Offers + Bulk Analytics
Tables:

bulk_offers

bulk_offer_analytics

Enforce:

Only vendors insert bulk_offers

Only premium_plus vendors see advanced analytics

bulk_offer_analytics:

Writes: service_role / edge function only

Reads: vendor-own or admin-all

STEP 4 — Media / Camera / Docs / Video
Tables:

provider_media

vendor_media

Buckets:

rooted-public-media

rooted-protected-media

Rules:

Insert: owner_user_id = auth.uid()

Update/Delete: only owner OR admin

Select:

Public media: visible for active providers

Protected: only via correct role/id checks

Frontend must:

Route uploads to correct buckets and folder patterns.

STEP 5 — Events & Volunteering
Tables:

events

event_registrations

RLS expectations:

Events:

Vendors/Institutions/Admin insert

Public select: status = 'published' (and moderation_status = 'approved')

Owner/Admin update/delete

Registrations:

Any authenticated user can register

Users see their own registrations

Host + admin can see registrations for their events

STEP 6 — Landmarks
Table:

landmarks

Enforce:

Public select: is_published = true

Kids surfaces: add is_kids_safe = true

Vendors/Institutions/Admin insert

Owner/Admin update/delete

No monetization logic around landmarks

STEP 7 — Messaging
Tables:

conversations

conversation_participants

messages

Confirm:

Only participants can see a conversation and its messages

Creation limited to allowed roles (vendor, institution, possible individual)

Kids Mode cannot access B2B messaging

Optional: admin moderation access via audited tools

STEP 8 — Feed (Items, Comments, Likes) HARDENING
Tables:

feed_items

feed_comments

feed_likes

Work:

Turn on RLS for feed_comments and feed_likes.

Policies:

Authenticated-only writes

Only authors (or admin) can update/delete their own comments/likes

Comments/likes must reference existing feed_items

Closes anonymous / abusive write paths.

STEP 9 — Analytics ETL (Post-Launch)
Tables:

vendor_analytics_daily

vendor_analytics_basic_daily

vendor_analytics_advanced_daily

bulk_offer_analytics

Work:

Add cron / edge jobs to populate from usage events.

Writes must be:

service_role

or dedicated internal role

Vendors never write their own analytics.

STEP 10 — Final DB Launch Checklist
Before soft launch:

List all RLS-enabled tables.

Confirm no sensitive tables have RLS off.

For each sensitive table, define:

Who can INSERT?

Who can SELECT?

Who can UPDATE?

Who can DELETE?

Test behavior for:

vendor_free

vendor_premium

vendor_premium_plus

institution

admin

If behavior matches expectations → Backend is LOCKED.
Remaining work = UI, UX, polish.

9. Current Vertical Status (Reality Only)
✅ ROOTED Community – active, core UX + flows present

🏗️ ROOTED Construction – in development (logic + structure reuse)

🏗️ ROOTED Arts & Culture – in canonical design + early wiring

🏥 ROOTED Healthcare (non-clinical) – conceptual only (no patient data, no records)

All other verticals in the roadmap are not live and must integrate with this core.

10. Recommended AI Prompt for This Repo
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
- Bypass account_status, feature_flags, or deletion pipeline
- Expose community member profiles publicly
- Bypass app-wide safety rules for Kids and Community

You ARE allowed to:
- Audit and polish existing logic
- Add or refine RLS policies
- Add edge functions, views, or jobs
- Wire existing backend logic into UI components
- Help with performance, readability, and structure
- Extend admin/debug tools that respect the governance model

Always respect:
- user_tiers + feature_flags as the source of truth
- Kids Mode restrictions
- Seasonal + holiday intelligence (season baseline, holidays dual-consent)
- Seasonal featured view (seasonal_featured_providers) for discovery
- Media bucket rules (rooted-public-media, rooted-protected-media)
- Account governance + opt-in/opt-out + deletion pipeline
- Safety constraints for sanctuaries, nonprofits, and community uploads

Use the BACKEND HARDENING ROADMAP in ROOTED_GIT_HANDOFF.md and tell me which STEP you’re working on when you make changes.
End of ROOTED – GIT COMPREHENSIVE HANDOFF
This file lives at the repo root and is treated as platform law.
