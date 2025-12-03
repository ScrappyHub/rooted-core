### `docs/MODERATION_SYSTEM.md`

```md
# ✅ ROOTED — MODERATION SYSTEM (CANONICAL)

Status: ✅ Canonical  
Scope: All public-facing submissions across all ROOTED verticals  

Purpose:  
The Moderation System provides a governed, auditable, admin-controlled approval/denial pipeline for all public-facing content and applications across ROOTED.

Nothing that touches the **public map, directory, feed, discovery, or Kids surfaces** is allowed to skip this system.

Related docs:

- `ADMIN_AUTH_MODEL.md`
- `DISCOVERY_RULES.md`
- `GEO_RULES.md`
- `NOTIFICATIONS_SYSTEM.md`
- `ROOTED_PLATFORM_CONSTITUTION.md` (reference copy in this repo)
- Platform-level: `ROOTED_PRE-LAUNCH_ABUSE_TEST_MATRIX.md`

---

## 1. Scope

The Moderation System currently applies to:

- Events
- Landmarks
- Vendor applications
- Institution applications

Future extensions:

- Feed items / community uploads
- Experiences and vertical-specific submissions

Rule:

> No submission becomes publicly visible without passing through moderation.

Kids Mode surfaces are additionally filtered before moderation via kids-safe flags and discovery rules. At ROOTED Community launch, **Kids Mode UI is PILOT OFF**, but Moderation rules are written for the future Education / Kids verticals.

---

## 2. Core Tables

### 2.1 `public.moderation_queue`

Single source of truth for all pending and historical moderation actions.

Canonical fields:

- `id` (uuid, PK)
- `entity_type` (text)  
  → `event | landmark | vendor_application | institution_application | feed_item` (future) | other types
- `entity_id` (uuid)  
  → FK to specific entity table
- `submitted_by` (uuid → `auth.users.id`)
- `status` (text)  
  → `pending | approved | rejected | auto_approved`
- `reason` (text, nullable)  
  → rejection / context notes
- `reviewed_at` (timestamp, nullable)
- `reviewed_by` (uuid → `auth.users.id`, nullable)
- `created_at` (timestamp)

All moderation behavior keys off this table.

### 2.2 Entity Columns

Entities that require moderation MUST have:

- `moderation_status` (text)  
  → `pending | approved | rejected | auto_approved`

Examples:

- `events.moderation_status`
- `landmarks.moderation_status`
- `vendor_applications.moderation_status`
- `institution_applications.moderation_status`
- (future) `feed_items.moderation_status`

Public-facing queries MUST check both:

- `moderation_status = 'approved'`
- `account_status` / `feature_flags` where relevant  
  (see `ADMIN_AUTH_MODEL.md` and role/tier docs)

---

## 3. Canonical Approval Flow (Events & Landmarks)

### 3.1 Submission

When a user submits an event or landmark:

- Entity row is created with:
  - `moderation_status = 'pending'`
  - Any kids-safe / category flags set by submitter (if available)
- A row is inserted into `public.moderation_queue` with:
  - `entity_type = 'event'` or `'landmark'`
  - `entity_id = <entity UUID>`
  - `submitted_by = auth.uid()`
  - `status = 'pending'`

### 3.2 Admin Review

Admins see pending items via:

- Admin UI → “Moderation / Queue”
- Backend: `SELECT` from `public.moderation_queue WHERE status = 'pending'`

They can inspect:

- Event/landmark details
- Submitter
- Kids-safe flags
- Vertical / category tags
- Provider / application context

### 3.3 Approval (Admin Only)

```sql
select public.admin_moderate_submission(
  '<MODERATION_UUID>',
  'approved',
  'Looks good'
);
This function:

Validates public.is_admin() (role = admin, account_status = 'active').

Updates underlying entity:

moderation_status = 'approved'

Updates public.moderation_queue:

status = 'approved'

reviewed_at = now()

reviewed_by = auth.uid()

reason = 'Looks good' (or custom text)

Chains into Notifications System:

Calls public.notify_submission_approved(...)

Inserts a row into public.notifications

3.4 Public Visibility
ALL public queries for events & landmarks MUST include:

sql
Copy code
WHERE moderation_status = 'approved'
Kids Mode surfaces (when enabled) add:

sql
Copy code
AND is_kids_safe = true
Guarantees:

No unreviewed content appears.

Kids Mode sees only pre-approved, flagged-safe content.

4. Canonical Rejection Flow (Events & Landmarks)
Rejection uses the same RPC:

sql
Copy code
select public.admin_moderate_submission(
  '<MODERATION_UUID>',
  'rejected',
  'Not appropriate'
);
This:

Validates public.is_admin().

Updates entity: moderation_status = 'rejected'.

Updates queue: status = 'rejected', reviewed_at, reviewed_by, reason.

Sends notification via public.notify_submission_rejected(...).

Rejected content:

Never appears in public discovery.

May be visible to admins and (optionally) the submitter in private views.

5. Vendor & Institution Application Moderation
Vendor and Institution onboarding uses the same pipeline.

5.1 Application Submission
On submit:

Row created in:

public.vendor_applications or

public.institution_applications

moderation_status = 'pending'

Entry created in public.moderation_queue:

entity_type = 'vendor_application' | 'institution_application'

entity_id = application.id

status = 'pending'

submitted_by = auth.uid()

5.2 Approval
Admin approves via public.admin_moderate_submission(...):

Application row:

moderation_status = 'approved'

Provider is created and wired:

Insert into public.providers

provider_type = 'vendor' | 'institution'

owner_user_id = applicant

Vendor/Institution activation rules follow:

public.user_tiers

feature_flags

account_status

public.moderation_queue updated:

status = 'approved', reviewed_at, reviewed_by

Notification:

*_application_approved

5.3 Rejection
Admin rejection:

Application:

moderation_status = 'rejected'

No provider is created.

Queue updated:

status = 'rejected', reason stored.

Notification:

*_application_rejected

Rule:

Applications are never auto-approved. They always enter moderation_queue.

6. Internal SQL Override (Maintenance Only)
Emergency internal helper:

sql
Copy code
select public._admin_moderate_submission_internal(
  '<MODERATION_UUID>',
  '<new_status>',
  '<reason>'
);
Characteristics:

May bypass public.is_admin() because it is not exposed to clients.

Intended for:

Incident response

Data recovery

Hotfixes via SQL editor

Rules:

🚫 Never exposed as an RPC.

🚫 Never called from frontend/mobile.

✅ Only used manually by founder / root-level ops with service-role keys.

Pattern: any function prefixed with _admin_ or _debug_ is considered internal-only.

7. Security Guarantees
The Moderation System guarantees:

✅ Only admins can approve/reject via admin_moderate_submission.

✅ All actions are auditable via:

public.moderation_queue

public.user_admin_actions (for account changes)

public.notifications

✅ No public bypass paths exist:

All discovery queries respect moderation_status = 'approved'.

✅ RLS remains enforced:

Non-admins see only their own submissions where applicable.

✅ Kids Mode content:

Filtered by is_kids_safe.

Shows no unmoderated entities.

Is not exposed at all while Kids Mode is in PILOT OFF.

✅ Sanctuary / rescue / nonprofits:

May post volunteer/education events.

Are mission-only (no commercial marketplace tools or ads).

Still pass through moderation.

✅ Municipal / civic entities:

May exist in schema/backend for later verticals.

Are discovery-off in ROOTED Community by default.

Must go through moderation when surfaced in future verticals.

8. Vertical Compatibility
The Moderation System is vertical-agnostic and applies to:

✅ ROOTED Community

✅ ROOTED Construction

✅ ROOTED Arts & Culture

✅ ROOTED Education / Kids

✅ ROOTED Experiences

✅ Future verticals

Any new public-facing submission type MUST:

Include moderation_status on its table.

Insert a row into public.moderation_queue on submission.

Use public.admin_moderate_submission(...) as its approval/denial gate.

Respect moderation_status = 'approved' in all discovery queries.

9. Admin Moderation & Governance Integration
Admin identity is defined solely in public.user_tiers and the helper in ADMIN_AUTH_MODEL.md:

role = 'admin'

account_status = 'active'

public.is_admin() returns true

Exposed admin RPCs (see ADMIN_AUTH_MODEL.md):

public.admin_get_user_accounts

public.admin_set_role_tier

public.admin_set_account_status

public.admin_update_feature_flags

public.admin_moderate_submission

(Optional) public.admin_resend_notification

Each exposed admin RPC:

✅ Uses SECURITY DEFINER

✅ Calls public.is_admin() at the top

✅ Writes to public.user_admin_actions for account-level changes

✅ For moderation:

Logs to moderation_queue

Chains into Notification helpers

Internal helpers (_admin_*, _debug_*) are:

🚫 Not exposed as RPCs

✅ Used only by outer admin RPCs or service-role contexts

10. Community Uploads & Safety (Current Doctrine)
Community uploads (e.g., user-submitted community spots) follow:

Schema-level support may exist.

Feature-level behavior is globally gated behind a core setting / feature flag:

e.g. community_uploads_enabled = false at launch.

Launch default:

Community uploads disabled for ROOTED Community.

Kids Mode never has community upload flows.

Municipal/civic uploads are discovery-off until their vertical launches.

When enabled in the future, all community uploads MUST:

Enter moderation_queue.

Require admin approval.

Be excluded from Kids Mode unless explicitly marked kids-safe.

11. Canonical Status
This file is CANONICAL and platform-wide:

Defines how all public submissions move from pending → approved/rejected.

Defines the only legal approval mechanism:

public.admin_moderate_submission(...)

Defines the relationship between:

Moderation

Admin governance

Notifications

Discovery

Kids Mode

Sanctuary / nonprofit protection

Municipal discovery hibernation

If any future code, vertical, or AI suggestion conflicts with this Moderation System:

The Moderation System wins.
