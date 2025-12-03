# ROOTED — ADMIN AUTHORIZATION MODEL (CANONICAL)

Status: ✅ Locked  
Scope: All ROOTED verticals (Core backend)  

This document defines the **canonical authority boundaries** for all admin operations across ROOTED.

No admin power is inferred. **All authority is explicitly granted and audited.**

---

## 1. Role Source of Truth

All user authority is derived from:

`public.user_tiers`

**Fields (canonical):**

- `user_id`
- `role` → `guest | individual | vendor | institution | admin`
- `tier`
- `feature_flags` (jsonb)
- `account_status`

Other tables (e.g. `providers`) may reflect power *effects*, but **only** `public.user_tiers` defines who is an admin.

---

## 2. Canonical Admin Check

```sql
create or replace function public.is_admin()
returns boolean
language sql
security definer
as $$
  select exists (
    select 1
    from public.user_tiers
    where user_id = auth.uid()
      and role = 'admin'
      and account_status = 'active'
  );
$$;
Rules:

This function is the only valid check for admin identity.

All admin RPCs and admin-only views MUST call public.is_admin() at the top.

RLS policies MAY additionally reference admin status, but they must never contradict this function.

3. Admin RPC Surface (Frontend-Exposed)
The only admin RPCs that may be exposed to the frontend are:

public.admin_get_user_accounts

public.admin_set_role_tier

public.admin_set_account_status

public.admin_update_feature_flags

public.admin_moderate_submission

Each exposed admin RPC:

✅ Uses SECURITY DEFINER

✅ Calls public.is_admin() as the first statement

✅ Writes to public.user_admin_actions for any account-level change

✅ For moderation, chains into notification helpers in the Notifications System

No other function may be exposed as an admin RPC without being added to this list and documented here.

4. Admin Moderation Authority
Canonical moderation RPC:

public.admin_moderate_submission(moderation_id uuid, new_status text, reason text)

Rules:

Requires public.is_admin() = true

Applies to all entities registered in public.moderation_queue:

event

landmark

vendor_application

institution_application

(future) feed_item, experience, etc.

Updates:

Underlying entity’s moderation_status

public.moderation_queue.status, reviewed_at, reviewed_by, reason

Chains into Notifications System:

submission_approved

submission_rejected

No other path may set an entity’s moderation_status = 'approved'.

5. Admin Account Control
Admins can:

Suspend accounts (account_status = 'suspended')

Restore accounts (account_status = 'active')

Initiate account deletion pipeline (where implemented)

Review deletion requests

View all moderation history for entities

View all vendor & institution applications

Rules:

All account-level changes MUST be made through admin RPCs documented here.

All account-level changes MUST write a row into public.user_admin_actions including:

actor_user_id (admin)

target_user_id

action_type

metadata

created_at

Raw UPDATE / DELETE against public.user_tiers, auth.users, or application tables is forbidden outside emergency/manual maintenance using service-role credentials.

Deletion doctrine:

Admins initiate deletion via the canonical deletion pipeline.

Direct hard deletes of users or providers from UI/clients are not allowed.

6. Vendor & Institution Applications
Application tables:

public.vendor_applications

public.institution_applications

Rules:

All applications begin with moderation_status = 'pending'.

All applications must create a row in public.moderation_queue with:

entity_type = 'vendor_application' | 'institution_application'

entity_id = application.id

submitted_by = auth.uid()

status = 'pending'

Applications are never auto-approved.

Only admins can:

Approve/reject applications via public.admin_moderate_submission(...).

Change moderation_status on application tables (via RLS + RPC).

Every decision:

Updates the application row’s moderation_status.

Updates the matching moderation_queue row (status, reviewed_at, reviewed_by, reason).

Sends a notification via Notifications System:

vendor_application_approved

vendor_application_rejected

institution_application_approved

institution_application_rejected

7. Application Upload Security
Uploads attached to applications (licenses, insurance, documents):

Are stored in private buckets only.

Are linked to the submitting user and application row.

Are protected by RLS:

Submitter can read their own uploads.

Admins can read for review.

Public/other users cannot access them.

Cannot be modified after submission except via explicit admin flows (e.g. “request resubmission”).

8. Internal Maintenance Overrides
Internal helpers (examples):

_admin_moderate_submission_internal

_admin_grant_default_badges_for_provider_internal

Any function starting with _admin_ or _debug_

Rules:

🚫 MUST NOT be exposed as RPCs in Supabase “Exposed Functions”.

✅ MAY be called by:

Other admin RPCs

Service-role scripts

Direct SQL during incident response and data repair

These helpers may bypass public.is_admin() only because they are never callable from clients.

9. Zero-Trust Enforcement
The ROOTED Admin Model enforces:

✅ Explicit authority (no “implicit admin”)

✅ No role escalation via UI or direct table updates

✅ No inherited privileges from other roles

✅ Audit-first operations via public.user_admin_actions

✅ Service-role and internal function isolation

✅ Strict separation between:

Public clients (anon/auth)

Admin console usage

Service-role maintenance

10. Canonical Status
This Admin Authorization Model is IMMUTABLE and CANONICAL across all ROOTED verticals.

If any future code, migration, or AI suggestion conflicts with this document:

This document and public.is_admin() win.
