# ROOTED — MODERATION SYSTEM (CANONICAL) 

## 1. Purpose

The Moderation System provides a **governed, auditable, admin-controlled approval and denial pipeline** for all public-facing content and applications across ROOTED.

This applies to:

* Events
* Landmarks
* Feed items (future extension)
* Vendor applications
* Institution applications
* Any future vertical submissions

No submission becomes publicly visible without passing through this system.

---

## 2. Core Tables

### `moderation_queue`

The single source of truth for all pending and historical moderation actions.

**Core Fields (Canonical):**

* `id` (uuid)
* `entity_type` (text) → `event | landmark | vendor_application | institution_application | feed_item | future`
* `entity_id` (uuid)
* `submitted_by` (uuid → auth.users.id)
* `status` (text) → `pending | approved | rejected | auto_approved`
* `reason` (text, nullable)
* `reviewed_at` (timestamp)
* `reviewed_by` (uuid → auth.users.id)
* `created_at` (timestamp)

All moderation behavior keys off this table.

---

## 3. Canonical Approval Flow (Events & Landmarks)

### Step 1 — Submission

When a user submits an event or landmark:

* Entity is created with `moderation_status = 'pending'`
* A record is inserted into `moderation_queue`

### Step 2 — Admin Review

Admins review pending items via the Admin UI or RPC.

### Step 3 — Approval (Admin Only)

```sql
select public.admin_moderate_submission(
  moderation_id,
  'approved',
  'Looks good'
);
```

This performs:

* Updates the underlying entity `moderation_status = 'approved'`
* Updates `moderation_queue.status = 'approved'`
* Writes `reviewed_at` and `reviewed_by`
* Automatically generates a notification

### Step 4 — Public Visibility

All public queries MUST include:

```sql
where moderation_status = 'approved'
```

This guarantees no unreviewed content ever appears in production.

---

## 4. Canonical Rejection Flow (Events & Landmarks)

```sql
select public.admin_moderate_submission(
  moderation_id,
  'rejected',
  'Not appropriate'
);
```

This performs:

* Updates entity `moderation_status = 'rejected'`
* Updates `moderation_queue.status = 'rejected'`
* Stores the rejection reason
* Fires `notify_submission_rejected()`

---

## 5. Vendor & Institution Application Moderation

Vendor and Institution onboarding **also flows through the same system**.

### Application Submission

* Application row created in `vendor_applications` or `institution_applications`
* `moderation_status = 'pending'`
* Entry created in `moderation_queue`

### Approval

* Vendor/Institution is activated
* Provider record created
* Notification sent

### Rejection

* Application marked rejected
* Provider access is never granted
* Rejection notification sent

---

## 6. Internal SQL Override (Maintenance Only)

A protected internal function exists for emergency manual fixes:

```sql
select public._admin_moderate_submission_internal(...);
```

This function bypasses admin checks and exists strictly for:

* Incident response
* Recovery operations

It MUST never be exposed through the app.

---

## 7. Security Guarantees

* ✅ Only Admins can approve or reject
* ✅ All actions are auditable
* ✅ No public bypass paths exist
* ✅ RLS remains enforced
* ✅ Kids Mode content is automatically filtered upstream

---

## 8. Vertical Compatibility

This system is **vertical-agnostic** and applies automatically to:

* Community
* Construction
* Arts & Culture
* Education
* Experiences
* Future Vertical Modules

## 9. Admin moderation

Admin identity is defined purely in public.user_tiers:

role = 'admin'

account_status = 'active'

Admin RPCs exposed to the frontend are limited to:

admin_get_user_accounts

admin_set_role_tier

admin_set_account_status

admin_update_feature_flags

admin_moderate_submission

Every exposed admin RPC:

✅ Uses SECURITY DEFINER

✅ Calls public.is_admin() at the top

✅ Writes to public.user_admin_actions (for account-level changes)

✅ For moderation, chains into notification helpers

Internal helpers like _admin_moderate_submission_internal are:

🚫 Not to be exposed via Supabase’s “Exposed Functions”

✅ Used only by:

Outer admin RPC

Service-role / direct SQL in emergencies

No admin SQL helper whose name starts with _admin_ or _debug_ may be exposed via the public RPC API.

---

This file is CANONICAL and applies platform-wide.
