# ROOTED — NOTIFICATIONS SYSTEM (CANONICAL)

Status: ✅ Canonical  
Scope: All ROOTED verticals  
Applies To: Moderation, Admin Actions, Applications, System Events  

This document defines the **single, auditable, multi-channel notifications system** for ROOTED.

All moderation approvals, rejections, application decisions, and system governance actions flow through this system.

Related Canonical Docs:
- ADMIN_AUTH_MODEL.md
- MODERATION_SYSTEM.md
- ROOTED_DEBUG_TOOLKIT_CORE.md
- ROOTED_PLATFORM_CONSTITUTION.md (reference copy)

---

## 1. Purpose

The Notifications System provides:

- ✅ In-app notifications (current)
- ✅ Push delivery (APNs + FCM ready)
- ✅ Future email expansion (opt-in only)

It guarantees:

- Auditability
- User delivery control via opt-in
- Kids Mode safety
- Sanctuary & nonprofit protection
- Admin traceability

No moderation, approval, rejection, suspension, or governance action is considered complete without a corresponding notification record.

---

## 2. Core Tables

### 2.1 `public.notifications`

Canonical Fields:

- `id` (uuid, PK)
- `user_id` (uuid → auth.users.id)
- `type` (text)
- `title` (text)
- `body` (text)
- `data` (jsonb)
- `delivery_channel` (text → `in_app | push | email`)
- `delivered` (boolean)
- `delivered_at` (timestamp)
- `created_at` (timestamp)

RLS Requirements:

- ✅ Users may read only their own notifications
- ✅ Admins may audit all notifications
- ✅ Service-role may update `delivered` fields only

---

### 2.2 `public.user_devices`

Used for push delivery.

Fields:

- `id`
- `user_id`
- `platform` (`ios | android | web`)
- `device_token`
- `created_at`

RLS:

- ✅ Users may insert/update their own devices
- ✅ Admins + service-role may read all devices
- ❌ No public reads

---

## 3. Moderation Notifications

### 3.1 Approval

Triggered by:

`public.notify_submission_approved(...)`

Creates:

- `type = 'submission_approved'`
- `delivery_channel = 'push'`
- `delivered = false`

The worker later assigns:

`delivered = true`, `delivered_at = now()`

---

### 3.2 Rejection

Triggered by:

`public.notify_submission_rejected(...)`

Creates:

- `type = 'submission_rejected'`
- `body` includes rejection reason
- `delivered = false`

---

## 4. Vendor & Institution Application Notifications

| Action | Notification Type |
|--------|-------------------|
| Vendor Approved | `vendor_application_approved` |
| Vendor Rejected | `vendor_application_rejected` |
| Institution Approved | `institution_application_approved` |
| Institution Rejected | `institution_application_rejected` |

All use **one unified notifications table**.

---

## 5. Push Worker Delivery Flow

1. Worker queries:

```sql
SELECT * 
FROM public.notifications
WHERE delivered = false 
AND delivery_channel = 'push';
Worker fetches:

public.user_devices

Sends via:

APNs (Apple)

FCM (Android)

Updates:

sql
Copy code
delivered = true,
delivered_at = now()
6. Security Guarantees
✅ Notifications never expose admin identity publicly

✅ No notification can be spoofed from the frontend

✅ All moderation messages are system-authored

✅ Kids Mode never receives monetization notifications

✅ Sanctuary entities never receive commercial notifications

7. Marketplace & Analytics RLS Audit (Required)
For all commercial and analytics tables:

bids

bulk_offers

bulk_offer_analytics

vendor_analytics_*

ENFORCE:

❌ No USING (true) policies

✅ Provider ownership enforcement:
owner_user_id = auth.uid()

✅ Feature flag enforcement:
public.has_feature(auth.uid(), 'can_use_*')

8. Canonical Status
This system is required for:

✅ Moderation (events, landmarks, applications)

✅ Admin governance

✅ Account enforcement

✅ Seasonal and safety messaging

If any feature bypasses notifications → it violates platform law.
