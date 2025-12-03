# ✅ ROOTED — NOTIFICATIONS SYSTEM (CANONICAL)

Status: ✅ Canonical  
Scope: All moderation, account governance, and system-triggered notifications  
Applies To: ROOTED Core (all verticals)  

The Notifications System provides **auditable, multi-channel delivery** for all governed platform events.

It currently supports:

- ✅ In-app delivery (primary)
- ✅ Push delivery (APNs + FCM ready)
- 🟠 Email delivery (future expansion, opt-in only)

All **moderation approvals, rejections, and admin account actions** flow through this system.

Related docs:

- `ADMIN_AUTH_MODEL.md`
- `MODERATION_SYSTEM.md`
- `ROOTED_PLATFORM_CONSTITUTION.md`
- `ROOTED_DEBUG_TOOLKIT_CORE.md`

---

## 1. Design Principles

The Notifications System is:

- ✅ Audit-first
- ✅ Delivery-channel agnostic
- ✅ Admin-triggered for governance actions
- ✅ User-scoped via RLS
- ✅ Compatible with Kids Mode suppression rules
- ✅ Non-commercial (no marketing spam by default)

It is **not**:

- ❌ A real-time chat system
- ❌ A marketing broadcast engine by default
- ❌ A social engagement driver

---

## 2. Core Tables

### 2.1 `public.notifications`

**Canonical Fields:**

- `id` (uuid, PK)
- `user_id` (uuid → `auth.users.id`)
- `type` (text)
- `title` (text)
- `body` (text)
- `data` (jsonb)
- `delivery_channel` (text → `in_app | push | email`)
- `delivered` (boolean)
- `delivered_at` (timestamp)
- `created_at` (timestamp)

This table is the **single source of truth for notification state**.

---

### 2.2 `public.user_devices`

Used only for **push delivery targeting**.

Canonical Fields:

- `id` (uuid, PK)
- `user_id` (uuid → `auth.users.id`)
- `platform` (`ios | android | web`)
- `device_token`
- `created_at`

Devices are **never exposed publicly** and are only used by the delivery worker.

---

## 3. Moderation Approval Notifications

Triggered by:

```sql
public.notify_submission_approved(...)
Creates a notification row with:

type = 'submission_approved'

delivery_channel = 'push'

delivered = false

data includes:

entity_type

entity_id

approved_by

Delivery Worker later sends via:

APNs (iOS)

FCM (Android / Web)

4. Moderation Rejection Notifications
Triggered by:

sql
Copy code
public.notify_submission_rejected(...)
Creates:

type = 'submission_rejected'

Includes rejection reason in body and data.reason

delivered = false

Worker delivers via push / in-app

5. Vendor & Institution Application Notifications
Action	Notification Type
Vendor Application Approved	vendor_application_approved
Vendor Application Rejected	vendor_application_rejected
Institution Approved	institution_application_approved
Institution Rejected	institution_application_rejected

All use the same public.notifications table and delivery pipeline.

These are always triggered from:

sql
Copy code
public.admin_moderate_submission(...)
Never directly from UI.

6. Worker Delivery Flow (Push)
Delivery workers (Edge / cron / background jobs) follow this exact pattern:

Fetch all undelivered push notifications:

sql
Copy code
select *
from public.notifications
where delivered = false
  and delivery_channel = 'push';
For each row:

Lookup user devices in public.user_devices

Send via:

APNs (iOS)

FCM (Android/Web)

On successful send:

sql
Copy code
update public.notifications
set delivered = true, delivered_at = now()
where id = '<NOTIFICATION_ID>';
No retries are infinite. Failure logic is handled in the worker, not the DB.

7. Security & RLS (REQUIRED)
7.1 User Access
✅ Users may only read their own notifications:

sql
Copy code
user_id = auth.uid()
✅ No user may delete arbitrary notifications.

✅ No user may mark notifications as delivered.

7.2 Admin Access
Admins may:

Audit notification delivery

Diagnose failures

Re-send (future tool)

Admin identity is governed by:

sql
Copy code
public.is_admin()
as defined in ADMIN_AUTH_MODEL.md.

7.3 Service Role Access
Only service role / worker role may:

Mark delivered = true

Insert system-level notification records

8. Kids Mode Restrictions
When Kids Mode is active:

❌ No marketing, pricing, or sales notifications

✅ Only safety, education, or guardian-approved system messages

✅ No push notifications for:

Bids

Bulk offers

Vendor marketing

Paid promotions

✅ Moderation notifications still deliver to the parent account only

Kids Mode message suppression must happen at UI + worker layer, not only DB.

9. Marketplace & Analytics RLS Audit (Required Companion)
For all of the following:

bids

bulk_offers

bulk_offer_analytics

vendor_analytics_*

You MUST ensure there are no legacy policies that:

Use USING (true) for authenticated users

Ignore ownership (owner_user_id)

Ignore feature_flags

Ignore subscription_tier

Each table must enforce at least ONE policy checking:

Provider ownership

AND the correct feature flag via:

sql
Copy code
public.has_feature(auth.uid(), '<FEATURE_NAME>')
This is required to prevent:

False notifications

Unauthorized analytics reads

Marketplace leakage

10. Auditing & Debug Integration
Notifications integrate directly with:

public.moderation_queue

public.user_admin_actions

public.notifications

Primary debug queries live in:

ROOTED_DEBUG_TOOLKIT_CORE.md
(Section: Moderation & Notifications)

11. Canonical Status
This file is CANONICAL across all ROOTED verticals.

If any future vertical attempts to:

Bypass notifications

Trigger moderation without notification

Silence admin actions

→ That vertical is invalid by design until corrected.

If a future script, worker, PR, or AI recommendation conflicts with this doc:

NOTIFICATIONS_SYSTEM.md wins.
