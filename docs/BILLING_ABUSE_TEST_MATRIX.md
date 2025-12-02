# ROOTED Billing Abuse Test Matrix
Status: Canonical  
Scope: All billing flows (vendors + institutions)  
Purpose: Validate fraud resistance, governance compliance, and child/sanctuary protection.

This matrix must be completed **before** enabling real Stripe billing.

---

# 1. SUBSCRIPTION LIFECYCLE ABUSE TESTS

## 1.1 Fake Upgrade Attempt (UI Only)
Goal: Ensure UI cannot upgrade tier without Stripe.

Test:
- Run JS injection in browser console.
- Attempt to modify `subscription_tier` in React state.
- Attempt to send forged POST to upgrade endpoint.

Expected:
- Server rejects; RLS blocks unauthorized field updates.
- No DB mutation occurs.

---

## 1.2 Webhook Forgery
Goal: Prevent forged Stripe events.

Test:
- Send a manual POST to webhook endpoint.
- Spoof as if coming from Stripe.

Expected:
- Signature verification fails.
- No DB writes.
- Audit log entry for suspicious webhook.

---

## 1.3 Cancel Subscription → Still Getting Premium Tools
Test:
- Create subscription → cancel in Stripe Dashboard.

Expected:
- Webhook sets:
  - `subscription_status = 'canceled'`
  - Tier unchanged or reverted per policy
- UI gates immediately disable:
  - Bulk marketplace
  - RFQs
  - Premium analytics

---

# 2. PROVIDER MANIPULATION ABUSE

## 2.1 Provider tries to bypass to Premium Plus
Test:
- Provider changes localStorage or intercepts network calls to pretend they’re Premium Plus.

Expected:
- Server RLS enforces canonical tier grid.
- All commercial endpoints verify `subscription_tier`.

---

## 2.2 Sanctuary sets own tier to commercial
Test:
- Sanctuary attempts upgrade via UI or API.

Expected:
- RLS blocks.
- UI hides upgrade paths.
- Webhook handler overrides any commercial plan with:
  - `subscription_tier = 'free'`
  - `subscription_status = 'non_commercial'`

---

## 2.3 Kids Mode Exposure Blocks Billing
Test:
- Activate Kids Mode → attempt to upgrade.

Expected:
- Zero billing UI rendered.
- No Stripe session created.
- Billing route redirects to adult gateway.

---

# 3. STRIPE FRAUD & PAYMENT ABUSE

## 3.1 Chargeback attempt
Test:
- Create subscription → force chargeback in Stripe Dashboard.

Expected:
- Webhook sets:
  - `subscription_status = 'past_due'` or `'canceled'`
- RLS revokes premium tools.

---

## 3.2 Stolen Card / Invalid Payment
Expected:
- Stripe rejects at checkout.
- No provider DB entries change.
- No ghost customers created.

---

## 3.3 Repeated Failed Payments
Expected:
- Stripe retries automatically.
- After retry window → webhook sets `subscription_status = 'past_due'`.
- Premium tools disabled automatically.

---

# 4. PRIVACY & ETHICAL SAFETY TESTS

## 4.1 Kids Mode Billing Leakage
Attempt:
- Access billing from Kids Mode URL manually.

Expected:
- Server rejects; redirect to `/kids/restricted`.

---

## 4.2 Religious / Cultural Tracking
Attempt:
- Force-add cultural preference via network spoof.

Expected:
- Server rejects; consent is user-driven and stored only on UI layer.
- No inference or logging of identity traits.

---

## 4.3 No Commercial Data in Kids Surfaces
Attempt:
- Force-load pricing components inside Kids Mode.

Expected:
- UI blocks component mount.
- Server-level RLS blocks revenue endpoints entirely.

---

# 5. ADMIN / INSIDER ABUSE

## 5.1 Admin attempts silent tier change
Attempt:
- Admin panel change without logging.

Expected:
- Write triggers log in `user_admin_actions`.
- No silent changes allowed.

---

## 5.2 Developer bypasses RLS
Attempt:
- Use service-level key from client by mistake.

Expected:
- Service keys never shipped to frontend.
- Access is blocked and logged.

---

## 5.3 Rogue worker attempts to grant bid access
Attempt:
- Change sanctuary tier to Premium Plus.

Expected:
- Policy overrides:
  - RFQs blocked
  - Bids blocked
  - Bulk market blocked

---

# 6. GOVERNANCE VIOLATION TESTS

## 6.1 “Override Kids Mode for Growth”
Attempt:
- Add pricing inside Kids Mode to “boost conversions”.

Expected:
- Platform Constitution invalidates change.
- Contributor governance clause blocks merges.
- RLS + UI + policy triple-layer rejects.

---

## 6.2 “Holiday injection without consent”
Attempt:
- Force-christmas-tree icon for all users.

Expected:
- UI blocks.
- Holiday engine requires:
  - user opted in
  - business opted in
  - cultural set enabled
  - in-date-range
  - kids-safe

---

## 6.3 “Upsell during emergency content”
Attempt:
- Show an upgrade banner on crisis or health info.

Expected:
- UI blocks.
- High-safety layers disable monetization.

---

# Completion Standard

ROOTED may only activate live billing when:

- 100% of matrix tests are green
- Governance rules remain uncompromised
- All holiday, cultural, kids, sanctuary protections remain intact

This matrix is canonical.
