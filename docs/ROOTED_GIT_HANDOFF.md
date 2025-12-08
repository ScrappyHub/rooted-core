🌱 ROOTED — GIT COMPREHENSIVE HANDOFF (PLATFORM LAW)

Authority Level: Platform Engineering Law (below Governance Index, above individual vertical docs)
Applies To: All repos that implement ROOTED (backend, frontend, infra)

This file is governed by:

/governance/ROOTED_GOVERNANCE_INDEX.md

/governance/ROOTED_STOP_LAYER.md

/governance/ROOTED_PLATFORM_CONSTITUTION.md

/governance/ROOTED_CORE_SYSTEM_GOVERNANCE.md

/governance/ROOTED_VERTICAL_ACCESS_CONTRACT.md

/governance/ROOTED_FRONTEND_PLATFORM_CONTRACT.md

/governance/ROOTED_ADMIN_GOVERNANCE.md

/governance/ROOTED_KIDS_MODE_GOVERNANCE.md

/governance/ROOTED_SANCTUARY_NONPROFIT_LAW.md

/governance/ROOTED_ACCESS_POWER_LAW.md

/governance/ROOTED_DATA_SOVEREIGNTY_LAW.md

/governance/ROOTED_COMMUNITY_TRUST_LAW.md

Implementation references (non-law, but must obey law):

/governance/ROOTED_SECURITY.md

/governance/ROOTED_SECURITY_DISCOVERY_CONTRACT.md

/governance/ROOTED_MODERATION_SYSTEM.md

/governance/ROOTED_NOTIFICATIONS.md

/governance/ROOTED_MASTER_DEBUG_TOOLKIT.md

/governance/ROOTED_PRE_LAUNCH_ABUSE_TEST_MATRIX.md

/governance/ROOTED_TAXONOMY_CANONICAL.md

/docs/ROOTED_FRONTEND_SYSTEM_CONTRACT.md

/docs/ROOTED_FULL_SYSTEM_DEBUG_GUIDE.md

If any PR, commit, migration, UI feature, or AI output conflicts with this file:
➡ This file wins.

No exceptions.

From here forward, all work is:

Audit

Polish

Wiring

Hardening

The core is already architected.

0. How to Use This Doc

This document is the canonical engineering handoff for anyone touching ROOTED:

You (Alec)

Future devs

Designers

Advisors

AI assistants

It explains:

What ROOTED currently is

The shared core across all verticals

Vertical boundaries (who does what, where)

Governance you must not break

Backend status (Supabase + RLS + views + RPCs)

Frontend expectations (auth, routing, feature flags)

Seasonal / weather / kids / sanctuaries

Backend hardening order

If you’re new:

Read §1–2 to understand the platform.

Read §3–5 before touching auth, roles, or tiers.

Read §6–8 before touching vertical logic.

Use §11 AI Prompt whenever you pull in an assistant.

1. What ROOTED Actually Is (2025 Canonical Snapshot)

ROOTED is a governed, multi-vertical civic platform built on one core:

Verticals (v1 set):

Community

Education

Construction

Experiences

Arts & Culture

It combines:

🌱 Community discovery & trust (non-commercial public layer)

🧾 Institutional & vendor procurement (quotes, bids, bulk sourcing in specific verticals)

🧒 Kids Mode (strict, non-commercial education layer)

🗺️ Landmarks & seasonal intelligence (maps, seasons, cultural overlays)

📊 Analytics & governance (RLS, feature flags, debug & audit trails)

Single identity. Multiple verticals. One law.

No vertical is allowed to invent its own separate identity system.

2. Shared Core Systems (All Verticals)

These systems are horizontal and shared by every vertical. They are defined in ROOTED_CORE_SYSTEM_GOVERNANCE.md and must not be re-invented.

2.1 Identity & Access (Global)

auth.users

public.user_tiers

user_id → auth.users.id

role (community_member, vendor, institution, admin, etc.)

tier (free, premium, premium_plus)

feature_flags (JSONB)

account_status (active, suspended, locked, pending_deletion, etc.)

Account governance:

public.user_admin_actions — admin audit log

public.account_deletion_requests — deletion pipeline

optional / future: user_security or user_tiers.has_2fa flag

Admin helpers:

public.is_admin()

public.admin_user_accounts (VIEW)

public.admin_get_user_accounts() (RPC, security definer)

2.2 Providers & Media

Core provider layer:

providers (vendors, institutions, nonprofits, sanctuaries, etc.)

provider_media

vendor_media

badges, provider_badges

Media buckets:

rooted-public-media

rooted-protected-media

Rules are enforced by RLS; frontend must not bypass them.

2.3 Procurement & Markets

Canonical procurement tables:

rfqs

bids

bulk_offers

bulk_offer_analytics

These power:

Education / institutional quote + payment flows

Construction RFQ → bid markets

Construction bulk materials markets

Community does not host RFQ/Bid/Bulk markets.
Experiences & Arts & Culture do not introduce new B2B markets; they reuse existing vendor/institution tiers for booking & discovery only.

2.4 Messaging

conversations

conversation_participants

messages

Constrained by:

RLS (participants only)

Admin Governance (moderation tools)

Kids Mode (no B2B messaging for kids)

2.5 Events, Volunteering, Landmarks

events

event_registrations

landmarks

Used differently in each vertical, but same tables:

Community: public events, seasonal happenings, volunteer opportunities

Education: field trips, educational programs

Construction: project meetings / safety sessions if configured

Experiences: guided activities, tours, adventures

Arts & Culture: shows, exhibits, performances

Landmarks are educational, non-commercial. See Community Trust + Sanctuary law.

2.6 Feed & Social

feed_items

feed_comments

feed_likes

RLS must:

Lock writes to authenticated users

Restrict edits/deletes to authors or admin

Never allow anonymous or unaudited mass posting

Community uploads are globally gated (see §7.4).

2.7 Analytics & Conditions

Analytics tables:

vendor_analytics_daily

vendor_analytics_basic_daily

vendor_analytics_advanced_daily

bulk_offer_analytics

Weather / conditions layer:

weather_snapshots

vertical_conditions_v1 (VIEW) — aggregated “conditions” per vertical/region

Used for top-nav “Conditions” widgets in:

Community (Local Conditions)

Education (Trip Conditions)

Construction (Jobsite Conditions)

Experiences (Trail/Activity Conditions)

Arts & Culture (Show/Travel Conditions)

Frontend calls vertical_conditions_v1; edge functions / cron populate weather_snapshots. UI must not talk to external weather APIs directly.

2.8 Config / KV

kv_store_f009e61d — internal configs (locked)

app_settings — global feature flags (e.g. community_uploads_enabled, kids_pilot_enabled, etc.)

Access via functions, not raw writes from the UI.

3. Non-Negotiable Governance Rules (Global)
3.1 Absolute “DO NOT” List

❌ Do NOT re-architect roles or tiers

❌ Do NOT disable RLS on any table

❌ Do NOT create new tables/columns silently

❌ Do NOT bypass Kids Mode law

❌ Do NOT auto-enable holidays or cultural sets (they require opt-in)

❌ Do NOT infer or sort by protected traits (race, religion, orientation, etc.)

❌ Do NOT monetize landmarks

❌ Do NOT introduce political messaging features

❌ Do NOT let vendors/institutions bypass premium_plus via UI-only checks

❌ Do NOT bypass user_tiers.account_status or feature_flags

❌ Do NOT bypass opt-in / opt-out or deletion flows

❌ Do NOT expose community member profiles publicly

❌ Do NOT move sanctuaries into other verticals (they stay under Community law)

❌ Do NOT force users to create separate accounts per vertical

3.2 Allowed Work

✅ Audit / debug

✅ Polish UI/UX (but never weaken governance)

✅ Wire backend views/RPCs into UI

✅ Add RLS policies or refine them

✅ Add views / functions / edge functions / cron jobs

✅ Add NEW tables/columns only if clearly marked NEW in PR / migration name

✅ Extend admin/debug tooling within the existing governance model

4. Roles, Tiers, Feature Flags & Vertical Access

Everything below summarizes ROOTED_CORE_SYSTEM_GOVERNANCE.md and ROOTED_VERTICAL_ACCESS_CONTRACT.md.
If there is conflict → those files win.

4.1 user_tiers as Law

public.user_tiers columns (conceptually):

user_id

role — community_member, vendor, institution, admin, etc.

tier — free, premium, premium_plus

feature_flags — JSONB

account_status — active, suspended, locked, pending_deletion, etc.

possibly has_2fa or security_flags

This is the single source of truth for:

Power

Access

Vertical participation

Monetization rights

Safety gating (Kids Mode, sanctuary, etc.)

4.2 Vertical Access Flags

Feature flags control vertical access (examples):

{
  "vertical_community_access": true,
  "vertical_education_access": true,
  "vertical_construction_access": false,
  "vertical_experiences_access": false,
  "vertical_arts_culture_access": true
}


Discovery-only surfaces may be public (e.g. Community map), but:
dashboards / B2B tools / markets require the correct vertical flag(s).

4.3 Tier Inheritance (Important)

Across all verticals:

Free

Discovery + basic listing

Basic analytics (views, taps)

No marketplaces / bids / workforce

Premium

Everything Free has

Access to applicable markets (e.g. RFQs in Education, some Construction tools)

No advanced analytics or workforce pools

Premium Plus

Everything Premium + Free has

Advanced analytics

Full bid/bulk/workforce tools (where that vertical actually uses them)

Experiences & Arts & Culture do not invent their own separate tier ladders; they reuse this tier model and only unlock more nuanced discovery/booking views, not new procurement markets.

4.4 Sanctuary & Rescue Flags (Community Only)

Sanctuary / rescue entities only exist in Community as:

{
  "sanctuary_rescue": true,
  "commercial_access": "disabled",
  "provider_premium_allowed": false,
  "provider_premium_plus_allowed": false,
  "bid_market_access": false,
  "bulk_procurement_access": false
}


✅ Volunteer & education events

✅ Community discovery

❌ No commerce, bids, bulk, or paid placements

No other vertical may treat them as commercial providers.

4.5 2FA Enforcement

Admin & institutions with powerful dashboards must:

Have has_2fa = true (or equivalent security flag)

Be blocked both in frontend routing and backend RPCs if 2FA is missing

Frontend uses handlePostLoginRouting (see Frontend Contract).
Backend enforces with RLS / security definer RPCs.

5. Vertical Overview (Boundaries & Markets)
5.1 Community (Non-Commercial Public Layer)

What it is:

Public community directory

Farms, markets, sanctuaries, local institutions

Seasonal & holiday discovery (with consent)

Landmarks & educational overlays

Markets:

❌ No RFQs

❌ No bids

❌ No B2B bulk markets

✅ Vendor discovery

✅ Volunteer opportunities

✅ Kids education view (when enabled)

Sanctuaries live only here, under Sanctuary Nonprofit Law.

5.2 Education (Field Trips & Learning Experiences)

What it is:

Discovery for schools, universities, youth programs, etc.

Managed field trips and learning experiences

Quote, booking, and payment flows for educational experiences

B2I / B2Institution marketplace for institutions and vetted vendors

Markets:

✅ Education RFQ / quote flows (institutions request, vendors respond)

✅ Payment flows for educational experiences (never through Kids Mode)

✅ Institutional dashboards (Premium / Premium Plus)

Kids Mode:

Can browse safe educational content / locations

Cannot trigger booking, quote, or payment flows

5.3 Construction (B2B Infrastructure & Trade System)

What it is (from your canonical prompt):

B2B construction and infrastructure coordination

Verified contractor discovery

RFQ → bid marketplace

Bulk materials marketplace

Workforce & subcontractor pools (Premium Plus)

Safety, compliance, and risk overlays

Markets:

✅ RFQ → Bid markets (Premium & Premium Plus, role-specific)

✅ Bulk materials markets (Premium Plus)

✅ Workforce / subcontractor pools (Premium Plus)

Public users:

Can see verified contractors & projects

Cannot access markets or workforce tools

Kids Mode (Construction):

Education-only previews of projects/trades

No RFQs, bids, messaging, or workforce screens

5.4 Experiences (Guided Activities & Adventures)

What it is:

Curated guided experiences (rafting, climbing, farm stays, etc.)

Trust & safety-driven activities tied back to Community / Education/Construction providers

Experience creation only by trusted providers / community members (e.g., 5+ volunteer events)

Markets:

❌ No new B2B RFQ/bulk markets invented here

✅ Uses existing vendor/institution tiers to gate who can host experiences

✅ Booking and inquiry flows tied to vendors/institutions

Kids Mode sees education-flavored experiences only, no pricing/booking.

5.5 Arts & Culture (Venues, Galleries, Performances)

What it is:

Discovery of venues, galleries, theaters, cultural centers, etc.

Layered events calendar (shows, exhibits, performances)

Ties to Event + Landmarks + Community trust & seasonal intelligence

Markets:

❌ No new B2B bid/bulk markets

✅ Uses existing vendor/institution tiers for event hosting, analytics, etc.

✅ Ticket links may redirect to external systems where allowed, respecting trust & non-profiling laws

Kids Mode:

Culture / arts education slices only

No ticketing, pricing, or memberships inside Kids UI.

6. Frontend Expectations (Summary Only)

Full law lives in: /governance/ROOTED_FRONTEND_PLATFORM_CONTRACT.md.

Key expectations:

Use one canonical helper handlePostLoginRouting

Calls auth.getUser() + rpc('get_my_role_and_tier')

Enforces 2FA for admin + institutions

Routes by role, tier, feature_flags.is_kids_mode

Use canonical views for discovery:

providers_discovery_v1

seasonal_featured_providers_v1

vertical_conditions_v1

kids-safe views (e.g. kids_*_v1)

Use feature_flags + subscription_status to gate tools:

can_use_bulk_marketplace

can_use_bid_marketplace

can_view_basic_analytics

can_view_advanced_analytics

vertical access flags

subscription_status in ('active', 'trialing')

Frontend must never:

Query raw core tables for power decisions (providers, rfqs, bids, etc.)

Talk to Stripe directly

Implement its own role/tier rules that contradict the backend

7. Discovery, Badges, Uploads, Sanctuaries, Kids
7.1 Vendor Discovery Badges

Used to power category filters + social proof:

badges (badge_type = 'vendor_specialty')

provider_badges (links providers to badges)

Examples:

FARM, MARKET, BAKERY, ORCHARD, FOOD_TRUCK, etc.

These:

Power filters and labeling

Do not override RLS or governance.

7.2 Institution Tags (Classification Only)

Institutions use classification tags (not commercial specialties):

Community Services

Schools & Universities

Youth Programs

Government & Municipal Agencies

Nonprofits

Correctional / restricted facilities

Sanctuary / Rescue (subject to sanctuary law)

Stored as:

badges (badge_type = 'institution_tag')

provider_badges

Used for filters and compliance overlays, not for preferential ranking.

7.3 Sanctuary / Rescue (Community Only, Non-Commercial)

Per Sanctuary law:

Entity type = Nonprofit sanctuary / rescue

Access:

✅ Volunteer events

✅ Educational events

✅ Community discovery

❌ Premium or premium_plus provider tools

❌ Bids, RFQs, bulk markets

❌ Ads, paid placement

Feature flags enforce commercial_access = 'disabled'.

7.4 Community Uploads (Global Safety Gate)

Schema exists, but:

community_uploads_enabled() (via app_settings) gates writes

RLS on upload tables requires community_uploads_enabled() = true

Currently:

❌ No public, unsupervised community uploads

✅ Admin seeding allowed

✅ Read-only viewing where safe

❌ Kids Mode cannot upload or manage spots

This remains a safety hibernated feature until explicitly re-enabled under governance.

7.5 Kids Mode (Cross-Vertical Summary)

Kids Mode is a non-commercial sandbox:

No pricing, booking, fundraising, RFQs, bids, or bulk markets

No B2B messaging

Age bands (3–6, 7–9, 10–13, 13–17) only change content framing, not rules

Tightly aligned to /governance/ROOTED_KIDS_MODE_GOVERNANCE.md

8. Seasonal Intelligence & Weather
8.1 Seasonal Intelligence

Season = always on; Holidays = optional overlay.

Seasons adjust palette, tone, suggestions

Holidays require dual consent:

Time window match

User opt-in

Business opt-in

Kid-safe content (if Kids Mode is active)

Seasonal featured providers:

View: seasonal_featured_providers_v1

Function: current_season()

Used by:

Community home carousels

Discovery boosts

Non-biased, season-only boosts (no demographic targeting)

8.2 Weather & Vertical Conditions

Backend:

Edge function(s) update weather_snapshots from external API

View vertical_conditions_v1 joins latest weather + vertical logic:

vertical (community, education, construction, experiences, arts_culture)

summary

risk_level, risk_flags

seasonal_phase

guidance_text

Frontend:

Uses vertical_conditions_v1 ONLY (never raw weather APIs)

Shows top-nav widgets:

Community → Local Conditions

Education → Trip Conditions

Construction → Jobsite Conditions

Experiences → Trail/Activity Conditions

Arts & Culture → Travel/Show Conditions

No vertical may use weather to profile or exclude people.
It’s for safety & planning, not segmentation.

9. Account Governance, Opt-In / Out, Deletion
9.1 Admin Audit Log

user_admin_actions:

admin_id

target_user_id

action_type

details (JSONB)

created_at

Required for:

Role changes

Tier changes

Feature_flag updates

Account_status mutations

Vertical access grants

Sanctuary flag changes

No silent admin edits.

9.2 Admin Views & RPC

admin_user_accounts VIEW

admin_get_user_accounts() RPC

Used by:

Admin panel only

Rely on public.is_admin() checks

Never bypass RLS by querying raw tables from the UI.

9.3 Opt-In / Out

At ROOTED core:

Controls seasonal & holiday overlays

Controls marketing & notification channels

Controls vertical participation where appropriate

Backed by:

user_tiers.feature_flags

(Future) dedicated user_consents table

No vertical may introduce its own hidden opt-in/out logic that conflicts with core.

9.4 Deletion Pipeline

account_deletion_requests:

user_id

status (pending, in_progress, completed)

timestamps & details

On request:

Account enters restricted state (no new content, markets, or messaging)

Admin process:

pending → in_progress → completed

Behavior:

PII is anonymized as required

Provider/institution records are soft-detached but history preserved

Audit logs remain (legal trail)

No code may bypass this pipeline for “fast delete.”

10. Backend Hardening Roadmap (Order of Work)

Use this order whenever you’re tightening backend behavior.

STEP 1 — Lock user_tiers & Feature Flags

Ensure rows exist for:

vendor_free, vendor_premium, vendor_premium_plus

institution_free, institution_premium, institution_premium_plus

admin

community_member

Ensure feature_flags reflect:

can_use_bid_marketplace

can_use_bulk_marketplace

can_view_basic_analytics

can_view_advanced_analytics

vertical access flags

sanctuary_rescue, commercial_access where needed

is_kids_mode, has_2fa if present

RLS should reference flags, not hard-coded tiers, wherever possible.

STEP 2 — RFQs & Bids (Education + Construction)

Tables:

rfqs

bids

Checks:

Only institutions (and allowed roles) can create RFQs

Only eligible vendors (usually Premium/Premium Plus) can submit bids

Vendors see only their bids

Institutions see only bids for their RFQs

Admin sees everything via RLS/RPC, not bypass

No schema changes here, only policies.

STEP 3 — Bulk Offers & Bulk Analytics (Construction)

Tables:

bulk_offers

bulk_offer_analytics

Enforce:

Only eligible vendors (Construction Premium Plus) insert bulk_offers

bulk_offer_analytics writes via service_role / cron jobs only

Vendors see only their analytics; admin can see all

STEP 4 — Media (Camera, Docs, Video)

Tables:

provider_media

vendor_media

Buckets:

rooted-public-media

rooted-protected-media

RLS:

Insert: owner_user_id = auth.uid()

Update/Delete: owner or admin only

Select: public vs protected depends on provider status + role

STEP 5 — Events & Registrations

Tables:

events

event_registrations

RLS:

Events:

Vendors/Institutions/Admin insert

Public select: only status = 'published' and moderation_status = 'approved'

Owner/Admin update/delete

Registrations:

Authenticated users can register

Users see their own registrations

Hosts/Admin see registrations for their events

Kids Mode: uses kids-safe views only.

STEP 6 — Landmarks

Table:

landmarks

RLS:

Public select: is_published = true

Kids views: require is_kids_safe = true via kids-specific views

Vendors/Institutions/Admin insert + update

Never monetized; no pricing fields used in UI

STEP 7 — Messaging

Tables:

conversations

conversation_participants

messages

RLS:

Only participants see conversation + messages

Creation restricted to allowed roles (no Kids Mode B2B messaging)

Admin moderation via audited tools only.

STEP 8 — Feed (Items, Comments, Likes)

Tables:

feed_items

feed_comments

feed_likes

RLS:

Authenticated-only writes

Only author (or admin) can edit/delete their own comments/likes

Comments/likes must reference existing feed_items

Turn on & test RLS here if not already.

STEP 9 — Analytics ETL

Tables:

vendor_analytics_daily

vendor_analytics_basic_daily

vendor_analytics_advanced_daily

bulk_offer_analytics

Writes:

Service role / internal jobs only

Reads:

Vendors see their rows

Admin sees all

No UI writes to analytics.

STEP 10 — Weather & Vertical Conditions

Tables / Views:

weather_snapshots

vertical_conditions_v1

Edge jobs:

Call external weather API

Insert snapshots per vertical + region

Close previous valid_to ranges correctly

RLS:

Reads allowed for all roles (conditions are public)

Writes via service_role / cron only

Frontend uses vertical_conditions_v1 for all conditions widgets.

STEP 11 — Final RLS Table Pass

Before launch:

Enumerate all RLS-enabled tables

Confirm no sensitive table lacks RLS

For each sensitive table, explicitly define who can:

INSERT

SELECT

UPDATE

DELETE

Test:

vendor_free

vendor_premium

vendor_premium_plus

institution_free/premium/premium_plus

admin

community_member

kids_mode enabled/disabled

If behavior matches governance → Backend is LOCKED.
Remaining work = UI/UX/polish only.

11. Recommended AI Prompt for This Repo (Updated)

Any time you bring in an AI assistant for ROOTED, start with exactly this (you can tweak path names if you rename):

You are working inside my existing ROOTED codebase.
ROOTED is already architected and deployed to Supabase with a governed multi-vertical core (Community, Education, Construction, Experiences, Arts & Culture) and a Vite/React/TypeScript frontend.

You are NOT allowed to:

Rebuild roles or tiers

Disable RLS on any table

Add new tables/columns without clearly marking them NEW

Change Kids Mode rules

Change holiday/cultural consent rules

Bypass premium_plus or feature_flag constraints

Monetize landmarks or sanctuaries

Bypass user_tiers.account_status, feature_flags, or deletion pipeline

Expose community member profiles publicly

Create separate accounts per vertical (identity is global)

Invent Construction/Experiences/Arts markets that conflict with the vertical prompts

You MUST respect:

/governance/ROOTED_GOVERNANCE_INDEX.md

/governance/ROOTED_STOP_LAYER.md

/governance/ROOTED_CORE_SYSTEM_GOVERNANCE.md

/governance/ROOTED_VERTICAL_ACCESS_CONTRACT.md

/governance/ROOTED_FRONTEND_PLATFORM_CONTRACT.md

Kids Mode safety, sanctuary law, and data sovereignty

user_tiers + feature_flags as the source of truth

Canonical views for discovery (providers_discovery_v1, seasonal_featured_providers_v1, kids-safe views)

vertical_conditions_v1 for all weather/conditions widgets

Account governance, opt-in/opt-out, and deletion pipeline

You ARE allowed to:

Audit and polish existing logic

Add or refine RLS policies

Add edge functions, views, or jobs (clearly labeled)

Wire existing backend logic into UI components

Improve performance, naming, structure, and DX

Extend admin/debug tools that respect governance

Always tell me which HARDENING STEP (from ROOTED_GIT_HANDOFF.md) you are working on when you propose backend changes.
