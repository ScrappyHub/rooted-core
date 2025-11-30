# ROOTED Core – Debug Toolkit

This doc is the **canonical reference** for debugging ROOTED’s core platform
(Supabase, auth, roles, RLS, media, GEO, analytics).

If a vertical is acting weird, start here.

---

## 1. Scope

Core covers:

- `user_tiers` + `feature_flags`
- Auth & session lookup
- RLS / policies on shared tables
- Media & storage (public vs protected)
- GEO & discovery rules
- Basic analytics plumbing

Vertical-specific bugs (Community, Construction, etc.) should still check
core first, then move to their own debug docs.

---

## 2. Quick Top-Down Checklist

Run these **in order** when something feels off:

1. **Who am I logged in as?**
   - Check `user_tiers` for this user.
   - Confirm `role` and `tier` are what you think they are.

2. **Is RLS blocking it?**
   - Look for RLS errors in Supabase logs.
   - Try the same query via Supabase “Run as user” if needed.

3. **Is the feature actually built in this vertical?**
   - If it references future verticals (healthcare, disaster, etc.),
     verify there’s real DB + UI wiring, not just docs.

4. **Is GEO/discovery hiding it?**
   - Confirm provider/landmark/event is marked “discoverable” and within
     radius / filters.

5. **Is media/storage blocking it?**
   - Check the bucket, object path, and storage policies.

6. **Is this just UI state?**
   - Refresh, log out/in, clear local storage; make sure feature flags
     aren’t stuck.

---

## 3. Auth & `user_tiers` Debug

### 3.1 Tables

- `auth.users` (Supabase)
- `user_tiers`
- Any `feature_flags` table or JSON column you use

### 3.2 Steps

1. Find test users in `auth.users`.
2. For each, ensure **exactly one** row in `user_tiers`:
   - `role` ∈ `['community','vendor','institution','admin']`
   - `tier` ∈ `['free','premium','premium_plus']`
3. In the app, log in as each and confirm:
   - Routing matches (`/community/...` vs `/vendor/...` etc.).
   - Premium-only UI doesn’t appear for free tier.

**If it fails:**

- Missing `user_tiers` row
- Wrong `role` / `tier`
- Front-end role routing using stale/incorrect logic

---

## 4. RLS & Permissions

### 4.1 Tables to sanity check

- `providers`
- `provider_media` / vendor media
- `conversations`, `conversation_participants`, `messages`
- `events`, `event_registrations`
- Analytics tables

### 4.2 Test pattern

For each table:

1. Use a **test vendor** account:
   - Try `SELECT`, `INSERT`, `UPDATE`, `DELETE` where appropriate.
   - Confirm vendor can only see/edit **their** rows.

2. Use a **test institution** account:
   - Confirm they can see what they should (e.g., their RFQs) and not
     other institutions’ private data.

3. Use an **admin** account:
   - Confirm they see everything that’s required for operations.

**Red flags:**

- “RLS: new row violates row-level policy” on actions that should be allowed.
- A non-admin seeing another user’s private rows.

---

## 5. Storage / Media

Buckets:

- `rooted-public-media`
- `rooted-protected-media`

### 5.1 Debug steps

1. Upload media in the app as:
   - Vendor
   - Institution

2. Confirm:
   - Successful upload (no 403/401).
   - Public media is viewable without auth when intended.
   - Protected media **does not** load in an incognito/private window.

3. If broken:
   - Check storage bucket policies in Supabase.
   - Check object key path (e.g., `vendors/{id}/...`) matches RLS rules.

---

## 6. GEO & Discovery

Core rule: **all discovery behavior follows the GEO docs in `rooted-core/docs/GEO_RULES.md`**.

### 6.1 Debug steps

1. In Community UI, open a “discover” map/list view.
2. Change:
   - Radius
   - Category
   - Any seasonal or “featured” filters
3. Confirm:
   - Only curated/allowed providers show.
   - Municipal / backend-only layers never show for normal users.

If a municipality or backend-only entity appears → data tagging + GEO rule bug.

---

## 7. Analytics Plumbing (High-Level)

Right now, analytics are **lightweight** in production.

### 7.1 Confirm:

- Events (clicks/views) write into the correct tables.
- Aggregation or materialized views are in place if already created.

If no data appears:
- Check that front-end is actually sending events.
- Check that RLS permits inserts from the client.

Full ETL / advanced analytics are future work; treat anything labeled
“advanced analytics” as **not guaranteed** until wiring is complete.

---

## 8. When In Doubt

If you can’t tell if something is:

- A core bug
- A vertical bug
- Or an unbuilt feature

Log a bug with:

- User role/tier
- Vertical + screen
- Exact action
- Expected vs actual

…and tag it as `core-unknown` until triaged.


1️⃣ SAFE READ-ONLY INSPECTORS (Admin Panel “Debug Dashboards”)

These should be the first tab(s) in your Admin Panel. They’re for understanding, not changing.

1.1 User Overview — “Users & Accounts”

Back end:

Uses your existing view: public.admin_user_accounts

Or RPC: public.admin_get_user_accounts()

Shows per user:

user_id

email

role

tier

account_status

feature_flags

deletion_status (from account_deletion_requests)

deletion_requested_at

Admin UI panel:

Search by email / user_id

Filters: role, tier, account_status, deletion_status

Clicking a user opens the User Detail Debug (next tool).

1.2 User Detail Snapshot — “User Debug View”

Back end (conceptual): one debug RPC like debug_user_snapshot(user_id) that aggregates:

auth.users

user_tiers

user_admin_actions (history)

account_deletion_requests

user_devices

latest notifications

latest moderation_queue items submitted_by this user

Admin UI:

Right-side drawer / page for a single user

Tabs:

Profile (email, created_at, last_sign_in)

Tier & Flags (role, tier, feature_flags, account_status)

Admin Actions Log

Deletion Requests

Devices

Recent Notifications

Submissions (events, landmarks, applications)

👉 Rule: This view is read-only. Mutations happen via the controlled tools below.

1.3 Moderation Queue Inspector — “Moderation → Queue”

Back end:

Direct SELECT from public.moderation_queue (with filters)

Join with:

events when entity_type='event'

landmarks when entity_type='landmark'

later vendor_applications / institution_applications

Shows per moderation item:

id

entity_type

entity_id

submitted_by

status

reason

created_at

reviewed_at

reviewed_by

Admin UI:

Filters by:

status: pending | approved | rejected

entity_type

submitted_by

Clicking an item:

shows underlying entity (event/landmark/application)

shows history & linked notifications

exposes Approve / Reject buttons (which call the admin RPC — see section 2.2)

1.4 Notifications Inspector — “Notifications → Queue & History”

Back end:

public.notifications

Views:

Queue: where delivered = false

History: recent notifications by user_id or by type

Admin UI:

Queue tab: see stuck notifications (for worker debugging)

History tab: check what a user was actually sent

Button “Resend” uses a controlled admin RPC (see 2.4).

1.5 Applications Inspector — “Onboarding → Applications” (for vendor/institution)

Once we add those tables, debug view should show:

vendor_applications

institution_applications

Joined with moderation_queue

Joined with auth.users (who submitted)

Panels:

Vendor Applications (Pending / Approved / Rejected)

Institution Applications (Pending / Approved / Rejected)

Approve / Reject uses the same moderation tools (2.2) and application-specific RPCs.

1.6 RLS & Backdoor Scanner — “Security → RLS Health”

Back end:

A debug query (read-only) that shows, per table:

Is RLS enabled?

Number of policies

So your admin panel can show:

Tables with RLS disabled → ⚠️ highlight

Tables with RLS enabled but no policies → ⚠️ highlight

This is your “backdoor detector” for data access.

(Admin UI only shows the state; fixes happen via migrations / SQL, not buttons.)

2️⃣ CONTROLLED ADMIN ACTIONS (Buttons that Actually Change Things)

These are the only mutation tools your Admin Panel should expose.

Each action → 1 RPC → 1 or more tables. All must:

Check is_admin()

Write an audit record to user_admin_actions / moderation_queue / etc.

2.1 Account Status Controls

RPCs (already defined):

admin_set_account_status(user_id, new_status)

admin_set_role_tier(user_id, new_role, new_tier)

admin_update_feature_flags(user_id, new_flags)

Admin UI:

From User Debug View:

Dropdown: account_status (active, suspended, deleted, etc.)

Dropdown: role & tier (only allowed combinations)

JSON editor or toggles for feature_flags

Every save:

Calls exact RPC

Logs into user_admin_actions

2.2 Moderation Actions (Approve / Reject)

RPC: admin_moderate_submission(moderation_id, new_status, decision_reason)

Approve: new_status = 'approved'

Reject: new_status = 'rejected'

This RPC:

Validates is_admin()

Updates entity moderation_status

Updates moderation_queue.status

Writes reviewed_at, reviewed_by, reason

Fires the appropriate notification via:

notify_submission_approved(...)

notify_submission_rejected(...)

Admin UI:

On Moderation Item:

Approve button (with confirmation)

Reject button (with required reason text)

2.3 Application Decisions (Vendor / Institution)

Once we wire applications:

RPCs (high-level design):

admin_decide_vendor_application(application_id, decision, reason)

admin_decide_institution_application(application_id, decision, reason)

Each will:

Approve:

Create / activate provider

Set onboarding flags

Mark application + moderation as approved

Send *_application_approved notification

Reject:

Mark application + moderation as rejected

Send *_application_rejected notification

Admin UI uses these under the hood from the Applications Inspector.

2.4 Notification Re-send / Requeue

RPC: e.g. admin_resend_notification(notification_id)

Behavior:

Only admin can call

Creates a new notification row based on the original

Does not edit original for audit trail

Worker picks up the new one

3️⃣ ROOT-LEVEL MAINTENANCE TOOLS (NO UI BUTTONS)

These exist for you in the SQL editor only, not for normal admins.

3.1 _admin_moderate_submission_internal(...)

Already defined.

No is_admin() check

Used for:

emergency fixes

debugging in SQL editor

Should never be called from frontend

3.2 Future Root Helpers (pattern)

Any future helper that bypasses normal checks should:

Be prefixed with _admin_ or _debug_

Live only in SQL and migrations

Never be added to Supabase “exposed function” list
