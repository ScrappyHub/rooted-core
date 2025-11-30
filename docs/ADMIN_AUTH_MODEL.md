# ROOTED — ADMIN AUTHORIZATION MODEL (CANONICAL)

## 1. Purpose

This document defines the **canonical authority boundaries** for all admin operations across ROOTED.

No admin power is inferred. All authority is explicitly granted.

---

## 2. Role Source of Truth

All user authority is derived from:

`public.user_tiers`

**Fields:**

* `user_id`
* `role` → `guest | individual | vendor | institution | admin`
* `tier`
* `feature_flags` (jsonb)
* `account_status`

---

## 3. Canonical Admin Check

```sql
create or replace function public.is_admin()
returns boolean
language sql
as $$
  select exists (
    select 1 from public.user_tiers
    where user_id = auth.uid()
      and role = 'admin'
  );
$$;
```

This function is used by ALL admin RPCs.

---

## 4. Admin Moderation Authority

Protected RPC:

`admin_moderate_submission(...)`

Rules:

* Requires `is_admin() = true`
* Controls all moderation outcomes
* Generates notifications automatically

---

## 5. Admin Account Control

Admins can:

* Suspend accounts
* Restore accounts
* Force delete accounts
* Review deletion requests
* View all moderation history
* View all vendor & institution applications

All actions must write to:

`public.user_admin_actions`

for audit integrity.

---

## 6. Internal Maintenance Overrides

Internal functions:

* `_admin_moderate_submission_internal`

Rules:

* Only callable via SQL
* Never accessible from frontend
* Exists for emergency recovery and repair

---

## 7. Upload Security for Applications

Vendor and Institution application uploads:

* Are restricted via RLS
* Are attached to the submitting user
* Cannot be accessed publicly
* Cannot be modified after submission without admin unlock

---

## 8. Zero Trust Enforcement

ROOTED Admin Model enforces:

* ✅ Explicit authority
* ✅ No implicit elevation
* ✅ No inherited privileges
* ✅ Audit-first operations
* ✅ Service-role isolation

---

No admin SQL helper whose name starts with _admin_ or _debug_ may be exposed via the public RPC API.

This Admin Authorization Model is **IMMUTABLE and CANONICAL** across all ROOTED verticals.
