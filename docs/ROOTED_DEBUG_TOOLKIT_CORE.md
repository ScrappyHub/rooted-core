ROOTED — Arts & Culture Vertical

SYSTEM_ARCHITECTURE.md

1. Purpose & Scope

The Arts & Culture vertical extends the ROOTED Core to map, govern, and sustain:

Cultural venues (museums, galleries, theaters, libraries, cultural centers)

Independent artists and collectives

Public art and cultural landmarks

Classes, workshops, performances, and festivals

Community-led cultural experiences and programs

This vertical:

Uses ROOTED Core identity, roles, governance, Kids Mode, messaging, events, and analytics.

Does NOT modify or bypass any Core doctrine, RLS, or governance rules.

Focuses on discovery, cultural access, and civic enrichment, not exploitative monetization.

The goal: make a regional cultural nervous system that helps communities discover, attend, support, and preserve arts & culture in a safe, governed, and inclusive way.

2. Alignment with ROOTED Core

Core dependencies (read-only or governed extension only):

auth & identity → users, roles, regions

user_tiers → role + tier (guest, individual, vendor, institution, admin)

providers / institutions → extended with Arts & Culture metadata

events / event_registrations

messaging (governed by vertical + Core rules)

media (photo, video, gallery settings)

landmarks

seasonal_intelligence & cultural overlays

kids_mode global enforcement

analytics (clicks, impressions, engagement, attendance)

Non-negotiable Core doctrines respected:

No vertical may change or weaken RBAC.

No vertical may bypass Kids Mode.

No vertical may monetize protected civic assets (e.g., public libraries, monuments) in violation of Core rules.

All cultural content must be audit-able (who published, who approved, what changed, when).

The Arts & Culture vertical is treated as a module plugged into the Core, providing:

Vertical-specific metadata, rules, and flows

Vertical-specific discovery and curation logic

Vertical-specific risk profiles and audit views

3. Roles in Arts & Culture (Within ROOTED Core Roles)

No new global roles are introduced. Instead, the vertical defines subtypes / capabilities under existing roles.

3.1 guest

Can browse public Arts & Culture discovery map and listings (with regional limits).

Can view public events, landmark info, and public art.

No messaging, no bookings, no reviews, no uploads.

3.2 individual (community member)

Can:

Save favorites

Register for public events/classes (where allowed)

Follow venues/artists (if enabled)

Submit suggestions for community spots (pending moderation)

Cannot:

Create official provider profiles

Impersonate institutions or vendors

Override age- or content-gates in Kids Mode

3.3 vendor (Arts & Culture Provider subtype)

Vendor is reused for:

Independent artists / creators

Galleries

Theaters and performance venues

Arts education providers

Private studios / classes

Vendor capabilities (subject to tier and vertical-specific rules):

Manage their Arts & Culture profile (bio, media, offerings, calendar).

List events, classes, exhibits, ticketed experiences.

Respond to institutional RFQs related to programming / performances (if/when connected to procurement flows).

See analytics: discovery, clicks, saves, attendance (within vertical-safe boundaries).

3.4 institution

Institution subtype here includes:

Public libraries

Museums

Schools / universities (for cultural programs)

Municipal arts offices

Community centers

Cultural non-profits

Institution capabilities:

Host and manage institution-led events, exhibits, classes.

Coordinate institutional partnerships with vendors (artists, venues).

Request proposals for cultural programming (e.g., residency, performance series) → uses shared procurement patterns with construction but adapted to programming rather than infrastructure.

Access institutional analytics dashboards (attendance, engagement, reach).

Some institution types (e.g., public libraries, municipal arts councils) must be flagged as protected civic assets — monetization rules are restricted per Core doctrine.

3.5 admin (platform / regional / audit)

Admin responsibilities for Arts & Culture:

Approve / verify cultural providers and institutions.

Manage dispute resolution around content, credit, and misrepresentation.

Enforce policy on:

Cultural sensitivity

Hate content

Exploitative or inappropriate events (especially around minors).

Run audits on:

Content changes

Featured placements

Flagged or reported content

Landmark integrity (fake/low-quality submissions).

Admins do not get “god mode” outside governed tools. All actions are logged via audit mechanisms.

4. High-Level Domain Model (Conceptual)

Note: This is conceptual architecture, not the SQL schema. Database details live in DATABASE_ENTITY_MODEL.md.

Core vertical entities:

CULTURAL_PROVIDER (extension of vendor/institution)

Types: artist, gallery, museum, library, theater, cultural_center, festival_organizer, etc.

Attributes:

Core provider fields (name, description, location, contact)

Cultural tags (disciplines, styles, communities served)

Accessibility metadata (ADA, sensory-friendly, language support)

Youth-safety flags (family-friendly, 18+ restricted, etc.)

CULTURAL_PROGRAM

Classes, workshops, recurring series, educational programs.

Linked to one or more CULTURAL_PROVIDER entities.

Has schedule, capacity, age ranges, pricing metadata (where allowed), and modality (in-person / hybrid / virtual).

CULTURAL_EVENT

Single or multi-day events: exhibitions, performances, screenings, festivals.

Uses Core events table with Arts & Culture-specific metadata overlays:

genre, discipline, audience, family-friendly flags, etc.

CULTURAL_LANDMARK

Extension of Core landmarks:

public art, murals, monuments, historic buildings with cultural value, cultural trails.

Includes Kids Mode safety classification and content gating.

CULTURAL_TRAIL / ITINERARY

Curated routes (e.g., “Downtown mural walk”, “Black history landmarks tour”).

Composed of ordered references to CULTURAL_LANDMARK and CULTURAL_EVENT nodes.

May have Kids Mode version / filter.

CULTURAL_RESOURCE

Non-event, non-location resources: digital archives, educational guides, toolkits.

Modeled as curated content linked to providers or institutions.

Obeys media & Kids Mode rules.

5. Core Modules (Vertical-Specific)
5.1 Discovery & Maps

Arts & Culture Map Layer

Overlay on Core map, filterable by:

Type: venues, artists, public art, events, trails.

Audience: kids & families, teens, adults, 18+ only (not surfaced in Kids Mode).

Accessibility: ADA, sensory-friendly, interpreter availability, etc.

Seasonal intelligence:

Highlights relevant events (e.g., summer festivals) without religious enforcement.

Cultural overlays are opt-in; no forced religious framing.

Search & Browse

Search by location, discipline, date range, audience, provider type.

Ability to surface curated “Collections” (e.g., “Local Indigenous artists”, “Latino arts month”).

5.2 Programs & Events

Program management:

Providers / institutions define recurring or term-based programs.

Registration flows share patterns with existing event registrations.

Clear age ranges, difficulty levels, and pre-requisites (if any).

Event lifecycle:

Draft → review (if required) → published.

Options for:

Free events

Suggested donation (if allowed)

Ticketed events (payment flows governed by Core, if/when enabled; no ad-hoc side channels).

5.3 Kids Mode Integration

Automatic filtering of:

18+ venues/events

Sensitive or explicit content

Kids Mode view:

Emphasizes:

Libraries, family-friendly museums, educational workshops.

Landmarks and trails safe for families.

Strict guardrails:

No public messaging.

No community reviews by minors.

No in-app purchases or monetization targeting kids.

5.4 Messaging & Collaboration (Governed)

One-to-one / controlled channels:

Institution ↔ provider (for programs, events, partnerships).

Community members may send inquiries to providers only through governed forms, not open DMs.

All messaging subject to:

Vertical policies for arts & culture.

Existing Core messaging constraints (no bypassing).

5.5 Analytics

Provider / institution dashboards:

Event views, registrations, attendance patterns.

Map clicks and trail completions.

Audience engagement segmented by family vs general.

Admin / regional dashboards:

Heatmaps of cultural deserts vs dense areas.

Program diversity (age groups, disciplines, communities served).

Trend tracking: seasonal peaks, underserved neighborhoods.

Analytics are descriptive and operational, not for invasive tracking.

6. Seasonal & Cultural Overlays (Vertical Logic)

Seasonal Intelligence:

Surfaces:

Summer programs, winter indoor activities, festival seasons.

School-year aligned programs for youth.

Avoids:

Embedding religious assumptions into default discovery.

Supports:

“Opt-in” cultural observance overlays (e.g., specific holidays) for users who want them.

Cultural Overlays:

Tag-based, consent-based UI treatments:

Heritage months (e.g., Black History, Hispanic Heritage) as curated experiences.

Languages, communities, and cultures represented by explicit tags.

Admin tooling:

Define and manage these overlays as configuration, not hard-coded per region.

7. Governance, Safety, and Compliance

Verification & Trust:

Cultural providers/institutions may receive badges:

Verified venue

Verified educator

Municipal/official designation

Badge issuance always:

Admin-reviewed

Audit-logged (who verified, when, based on what evidence).

Content Rules:

Prohibited:

Hate speech, extremist propaganda, incitement to violence.

Content targeting minors with inappropriate themes.

Flagging & review flows:

Any user can report an event, provider, or landmark.

Admin queue with triage priority (kids-related items first).

Protected Civic Assets:

Libraries, monuments, and other defined civic landmarks:

Can be featured.

Cannot be turned into paywalled or ad-driven experiences against Core rules.

Donations or support flows must follow civic-compliant patterns and never misrepresent ownership.

Auditability:

Any change to:

Landmarks

Trails

Institution profiles

Official programs/events

Must be traceable:

Actor, timestamp, old vs new values, reason (where provided).

8. Failure Modes & Safety Defaults (High-Level)

If seasonal intelligence fails → degrade gracefully to neutral chronological discovery (no weird empty screens).

If Kids Mode classification fails for a piece of content → default to hidden from Kids Mode views until reviewed.

If a provider is flagged for severe violation:

Auto-hide their upcoming events from Kids Mode.

Escalate to admin for full account status review.

If municipal integrations (e.g., official event feeds) fail:

Preserve last known good data with staleness indicators.

Do not silently invent or approximate civic information.

9. Out of Scope (for Arts & Culture Vertical)

No healthcare, emergency, disaster, or workforce logic beyond acknowledging that future verticals may link to cultural programs (e.g., workforce training in arts) — but their production rules are frozen and defined elsewhere.

No experimental ticketing or payment systems that bypass Core-approved, audited flows.

No dark-pattern monetization of cultural or civic content.

10. Implementation Notes (Non-DB)

All vertical screens reuse existing CORE patterns:

Map component

Event card patterns

Provider profile layouts

Analytics components

Arts & Culture UI may apply styling themes (color, iconography) but never redefines access logic in the frontend.

All vertical-specific logic is:

Explicit

Configuration-driven where possible (e.g., provider types, cultural overlays)

Backed by Core RBAC and policies.

If you want, the next file after this is DATABASE_ENTITY_MODEL.md for Arts & Culture, where we turn this conceptual architecture into concrete tables, relationships, and notes about RLS integration.

You said:
good for next ones
ChatGPT said:

Perfect — moving to the next canonical file for this vertical.

ROOTED — Arts & Culture Vertical

DATABASE_ENTITY_MODEL.md

This file defines only vertical-specific entities and extensions.
All authentication, roles, core messaging, media, events, landmarks, analytics, and Kids Mode enforcement remain under ROOTED Core ownership.

No Core tables are modified. Only extensions and joins are introduced.

1. Design Principles

✅ Vertical is additive, never destructive to Core

✅ All records are:

Region-scoped

Role-governed

Audit-logged

✅ All Kids Mode–relevant fields are:

Explicit

Fail-closed (hidden by default on classification failure)

✅ All discovery-facing entities support:

Seasonal overlays

Cultural overlays

Accessibility metadata

2. Core References Used (Read-Only)

These already exist in ROOTED Core:

auth.users

public.user_tiers

public.providers

public.institutions

public.events

public.event_registrations

public.landmarks

public.provider_media

public.messages

public.feed_items

public.analytics_*

public.regions

Arts & Culture only references these via foreign keys.

3. Primary Vertical Tables
3.1 cultural_providers

Vertical extension layer for vendors & institutions participating in Arts & Culture.

Field	Type	Notes
id	UUID (PK)	
provider_id	UUID (FK → providers.id OR institutions.id)	Entity owner
provider_type	ENUM	artist, gallery, museum, library, theater, cultural_center, festival_org, educator
discipline_tags	TEXT[]	Painting, music, theater, dance, film, etc.
community_tags	TEXT[]	Cultural identity representation
accessibility_tags	TEXT[]	ADA, sensory-friendly, ASL, multilingual
youth_safety_class	ENUM	kids_safe, teen_ok, 18_plus_restricted
verified_status	BOOLEAN	Admin-issued
verification_badge_id	UUID (nullable)	Links to badge if verified
region_id	UUID	Required
created_at	TIMESTAMP	
updated_at	TIMESTAMP	
3.2 cultural_programs

Recurring or educational offerings (classes, workshops, series).

Field	Type	Notes
id	UUID (PK)	
cultural_provider_id	UUID (FK)	
title	TEXT	
description	TEXT	
program_type	ENUM	class, workshop, series, residency, open_studio
age_min	INT	
age_max	INT	
capacity	INT	Nullable
price_type	ENUM	free, donation, paid
schedule_type	ENUM	single, recurring, term_based
seasonal_tags	TEXT[]	Spring, Summer, Fall, Winter
kids_mode_visible	BOOLEAN	Must be TRUE to appear in Kids Mode
region_id	UUID	
created_at	TIMESTAMP	
updated_at	TIMESTAMP	
3.3 cultural_events

Arts & Culture overlay for Core events.

Field	Type	Notes
id	UUID (PK)	
event_id	UUID (FK → events.id)	Core-owned
cultural_provider_id	UUID (FK)	
genre_tags	TEXT[]	Music, theater, film, etc.
audience_type	ENUM	family, general, 18_plus
ticketing_mode	ENUM	free, donation, paid_core_only
kids_mode_visible	BOOLEAN	Hard gate
verified_flag	BOOLEAN	Admin-reviewed
region_id	UUID	
created_at	TIMESTAMP	
3.4 cultural_landmarks

Extension of Core landmarks for cultural relevance.

Field	Type	Notes
id	UUID (PK)	
landmark_id	UUID (FK → landmarks.id)	
cultural_type	ENUM	mural, monument, public_art, historic_site, cultural_district
period_tags	TEXT[]	Historical eras
community_tags	TEXT[]	Cultural identity
kids_mode_safe	BOOLEAN	
protected_civic_asset	BOOLEAN	Locks monetization
region_id	UUID	
created_at	TIMESTAMP	
3.5 cultural_trails

Ordered cultural experiences & walking routes.

Field	Type	Notes
id	UUID (PK)	
title	TEXT	
description	TEXT	
trail_type	ENUM	walking, driving, guided, self_guided
kids_mode_available	BOOLEAN	
seasonal_tags	TEXT[]	
region_id	UUID	
created_by	UUID	Admin or Institution
created_at	TIMESTAMP	
3.6 cultural_trail_nodes

Ordered join table for trail → landmarks/events.

Field	Type	Notes
id	UUID (PK)	
trail_id	UUID (FK → cultural_trails.id)	
node_type	ENUM	landmark, event
node_id	UUID	FK varies by type
sequence_index	INT	Order in trail
3.7 cultural_resources

Digital learning + archive assets.

Field	Type	Notes
id	UUID (PK)	
title	TEXT	
resource_type	ENUM	archive, lesson, guide, toolkit
description	TEXT	
linked_provider_id	UUID (nullable)	
linked_institution_id	UUID (nullable)	
kids_mode_visible	BOOLEAN	
media_id	UUID	Uses provider_media
region_id	UUID	
created_at	TIMESTAMP	
4. Institutional Programming (RFQ-Style)
4.1 cultural_program_requests

(Institution → Providers)

Field	Type	
id	UUID	
institution_id	UUID	
title	TEXT	
description	TEXT	
program_type	ENUM	
target_age_range	TEXT	
budget_range	TEXT	
submission_deadline	DATE	
seasonal_target	TEXT	
region_id	UUID	
created_at	TIMESTAMP	
4.2 cultural_program_proposals

(Providers → Institution)

Field	Type	
id	UUID	
request_id	UUID	
provider_id	UUID	
proposal_text	TEXT	
budget_proposal	TEXT	
status	ENUM	submitted, accepted, rejected
created_at	TIMESTAMP	
5. Youth & Safety Enforcement Fields

Every discoverable entity must support at least one of:

kids_mode_visible

youth_safety_class

audience_type

If missing or NULL → excluded from Kids Mode by default.

6. Verification & Badging

Verification always references:

cultural_providers.verified_status

verification_badge_id

Badge issuance is:

Admin-only

Logged under Core audit tables

Badge removal never deletes historic audit traces.

7. Regional & Discovery Indexing

All discoverable Arts & Culture tables must index:

region_id

Location or map reference via linked Core entities

seasonal_tags where applicable

kids_mode_visible for filtering

8. RLS Enforcement (Conceptual)

All Arts & Culture tables enforce at minimum:

✅ Public read = filtered by:

Region

Youth safety rules

Protected civic asset rules

✅ Provider write = only for:

Their own provider_id

✅ Institution write = only for:

Their own institution_id

✅ Admin full access = logged + auditable

Exact policies defined in:
👉 ROLE_PERMISSION_MATRIX.md

9. Explicitly Forbidden Data Patterns

❌ No anonymous cultural listings

❌ No dark demographic tracking

❌ No off-ledger payments

❌ No child-targeted monetization fields

❌ No provider-generated “verification” claims

10. Canonical Status

✅ Fully aligned to ROOTED Core
✅ No RBAC violations
✅ Kids Mode enforced at data level
✅ Civic asset protection enforced structurally
✅ Ready for RLS policy definition
✅ Legally safe for public cultural infrastructure use
