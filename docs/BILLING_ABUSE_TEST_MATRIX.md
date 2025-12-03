
---

### File: `docs/BILLING_ABUSE_TEST_MATRIX.md`

```md
# ROOTED — BILLING ABUSE TEST MATRIX (CANONICAL)

Status: ✅ Canonical  
Scope: All billing & subscription flows (vendors + institutions)  
Purpose: Validate fraud resistance, governance compliance, and child/sanctuary protection.

This matrix must be completed **before** enabling real Stripe billing in any vertical.

Related docs:

- `BILLING_ARCHITECTURE.md`
- `ADMIN_AUTH_MODEL.md`
- Platform Pre-Launch Abuse Test Matrix (`rooted-platform/docs/ROOTED_PRE-LAUNCH_ABUSE_TEST_MATRIX.md`)

---

## 1. SUBSCRIPTION LIFECYCLE ABUSE TESTS

### 1.1 Fake Upgrade Attempt (UI Only)

Goal: Ensure UI cannot upgrade tier without Stripe + backend validation.

Test:

- Inject JS into browser console.
- Manually set client-side state to `subscription_tier = 'premium_plus'`.
- Forge POST/PUT to any “upgrade” endpoint.

Expected:

- Server ignores client-claimed tier.
- RLS or business logic checks canonical tier from DB.
- No `subscription_tier` or `subscription_status` change in `public.providers`.
- No new privileges when calling protected endpoints.

---

### 1.2 Webhook Forgery

Goal: Prevent forged Stripe webhooks.

Test:

- Send manual POST to webhook endpoint, mimicking Stripe payload.
- Use invalid or missing Stripe signature header.

Expected:

- Signature verification fails.
- No DB writes.
- Optional: internal log entry flagged as suspicious.

---

### 1.3 Cancel Subscription → Still Getting Premium Tools

Test:

- Start subscription for a test vendor.
- Cancel subscription from Stripe Dashboard (simulate real customer cancel).

Expected:

- Webhook updates provider:
  - `subscription_status = 'canceled'` or `'past_due'` per design.
- Feature gates immediately disable:
  - Bid marketplace
  - Bulk marketplace
  - Premium analytics
- UI reflects loss of access on next refresh/session.

---

## 2. PROVIDER MANIPULATION ABUSE

### 2.1 Provider Tries to Self-Promote to Premium Plus

Test:

- Provider tampers with network requests or localStorage to claim `premium_plus`.

Expected:

- All commercial endpoints re-check `subscription_tier` AND `subscription_status` from DB.
- RLS denies access to endpoints that require Premium Plus.
- UI may show optimistic state briefly, but server responses enforce truth.

---

### 2.2 Sanctuary Attempts Commercial Upgrade

Test:

- Sanctuary or rescue entity attempts to upgrade via UI or API.

Expected:

- Sanctuary detection (`provider_is_sanctuary(...)`) overrides:
  - `subscription_tier` forced to a non-commercial option (e.g. `free`).
  - Commercial feature flags remain `false`.
- UI hides or disables all commercial upgrade paths.
- Webhook handler refuses to grant commercial tools even if Stripe shows paid status.

---

### 2.3 Kids Mode Exposure Blocks Billing

Test:

- Enable Kids Mode (or simulate).
- Attempt to navigate directly to billing routes, upgrade screens, or Stripe checkout URLs.

Expected:

- No billing UI surfaces render in Kids Mode.
- No Stripe sessions are created.
- Requests are redirected to a kids-safe guard route (e.g. `/kids/restricted`).

---

## 3. STRIPE FRAUD & PAYMENT ABUSE

### 3.1 Chargeback Attempt

Test:

- Create subscription for a test provider.
- Initiate chargeback / dispute in Stripe Dashboard.

Expected:

- Stripe lifecycle webhooks update `subscription_status` appropriately (e.g. `'past_due'` or `'canceled'`).
- Core feature gates disable paid tools when status is not `'active'`.
- Optional: internal alert or log for disputed account.

---

### 3.2 Stolen Card / Invalid Payment

Test:

- Intentionally use invalid card on test checkout.

Expected:

- Stripe rejects payment client-side.
- ROOTED receives no “active subscription” webhook.
- No provider DB fields change.
- No “ghost” premium access is granted.

---

### 3.3 Repeated Failed Payments

Test:

- Create subscription, then simulate repeated failures (test cards).

Expected:

- Stripe moves subscription to `past_due` or similar.
- Webhook updates `subscription_status`.
- Feature gates revoke premium access when status is not `active`.

---

## 4. PRIVACY & ETHICAL SAFETY TESTS

### 4.1 Kids Mode Billing Leakage

Attempt:

- Hit billing URLs while Kids Mode flag/session is active.

Expected:

- Server and/or UI redirect to kids guard.
- No billing content, prices, or upgrade options are shown.

---

### 4.2 Religious / Cultural Tracking

Attempt:

- Inject or spoof “cultural preference” fields on billing forms or customer metadata.

Expected:

- Server rejects unknown/illegal metadata fields OR stores only neutral, non-profiling flags that are explicitly allowed by Data Sovereignty law.
- No implicit inference of religion, ethnicity, or protected traits.
- No billing record is used as a proxy for demographics.

---

### 4.3 No Commercial Data in Kids Surfaces

Attempt:

- Force-load billing summary or pricing components inside a Kids Mode route.

Expected:

- Kids-mode layout prevents component mount or hides them.
- Any billing API endpoints called from Kids Mode are blocked by RLS / auth checks.

---

## 5. ADMIN / INSIDER ABUSE

### 5.1 Admin Attempts Silent Tier Change

Attempt:

- Use internal tools or direct SQL to change `subscription_tier` without logging.

Expected:

- Official admin flows must go through RPCs that write to `public.user_admin_actions`.
- Direct manual changes are restricted to service-role maintenance and must be treated as incident activity.
- Governance: no “silent” plan changes in production.

---

### 5.2 Developer Bypasses RLS with Service Key

Attempt:

- Accidentally or intentionally embed service key into client code.

Expected:

- Deployment checks prevent shipping service keys.
- Any request from web client using service key is treated as misconfiguration and rotated out.
- This is considered a security incident, not a valid usage pattern.

---

### 5.3 Rogue Worker Grants Bid Access

Attempt:

- Background worker sets `subscription_tier = 'premium_plus'` for arbitrary providers.

Expected:

- Only billing pipeline workers are allowed to write billing state.
- Any other worker must be denied by RLS or by separation of concerns.
- Sanctuary / nonprofit protections still block commercial markets even if tier is set.

---

## 6. GOVERNANCE VIOLATION TESTS

### 6.1 “Override Kids Mode for Growth”

Attempt:

- Add or test any pricing UI inside Kids Mode with the justification of “conversion”.

Expected:

- Platform governance and Kids Mode law invalidate this change.
- PRs / migrations violating this rule must be rejected.
- UI tests should detect billing components in Kids routes and fail.

---

### 6.2 “Holiday Injection Without Consent”

Attempt:

- Force a religious or cultural holiday promotion (e.g. Christmas tree icon) in billing UI for all users.

Expected:

- Holiday engine and template logic enforce:
  - User opted in
  - Business opted in
  - Holiday is active in settings
- If consent is not present, the overlay must not render.

---

### 6.3 “Upsell During Emergency Content”

Attempt:

- Show upgrade banners on crisis, safety, or health-related informational pages.

Expected:

- Emergency / crisis surfaces forbid monetization overlays.
- Billing components must not render on any crisis-related routes.

---

## Completion Standard

ROOTED may only activate **live billing** when:

- ✅ 100% of matrix tests are green  
- ✅ Governance rules remain uncompromised  
- ✅ Kids, sanctuary, and cultural protections all remain intact  

This matrix is canonical and binds all future billing implementations.
