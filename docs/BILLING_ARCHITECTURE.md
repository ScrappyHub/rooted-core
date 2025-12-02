# ROOTED Billing & Subscription Architecture

Status: ✅ Canonical  
Scope: ROOTED Core (all verticals)  
Applies To: Vendors, Institutions, Admins (not community users, not kids)  

---

## 1. Design Principles

ROOTED billing is designed to be:

- Governance-first, not revenue-first
- Privacy-preserving
- Stripe-anchored (no card data stored locally)
- Tier-driven, not ad-hoc feature flags
- Safe for sanctuaries, nonprofits, and kids

We only store *minimal* billing state in our database and let Stripe handle all sensitive details.

---

## 2. Provider-Level Billing Fields

All commercial access is anchored at the **provider** level.

Table: `public.providers`

Canonical fields:

- `subscription_tier` (text)
  - Examples: `free`, `premium`, `premium_plus`
- `subscription_status` (text)
  - Examples: `inactive`, `trialing`, `active`, `past_due`, `canceled`
- `payment_provider_customer_id` (text)
  - Example: `cus_xxxxx` (Stripe Customer ID)

These three fields are **the only billing fields** we store for providers.

We do **not** store:

- Card numbers
- Expiration dates
- CVV / CVC
- Bank accounts
- Raw invoices
- Payment methods

All of that lives in Stripe.

---

## 3. Stripe Integration Pattern

Stripe is used for:

- Customer creation
- Subscription lifecycle
- Payments + invoices
- Webhook events

ROOTED uses Stripe IDs as foreign keys only:

- `payment_provider_customer_id` → Stripe Customer
- (future) `payment_provider_subscription_id` → Stripe Subscription

When Stripe events fire (webhooks), we:

1. Look up the provider by `payment_provider_customer_id`
2. Update:
   - `subscription_tier` (if plan changed)
   - `subscription_status` (active, canceled, etc.)
3. Never persist sensitive payment data locally

---

## 4. Tier → Feature Mapping (Law)

Billing is tightly bound to the canonical feature grid:

| Role        | Tier          | Bid Market | Bulk Market | Basic Analytics | Advanced Analytics |
|-------------|---------------|-----------:|------------:|----------------:|-------------------:|
| Vendor      | free          | ❌         | ❌          | ✅ (limited)     | ❌                 |
| Vendor      | premium       | ❌         | ✅          | ✅              | ❌                 |
| Vendor      | premium_plus  | ✅         | ✅          | ✅              | ✅                 |
| Institution | free          | ❌         | ❌          | ✅ (own data)    | ❌                 |
| Institution | premium       | ❌         | ✅          | ✅              | ❌                 |
| Institution | premium_plus  | ✅         | ✅          | ✅              | ✅                 |
| Admin       | any           | ✅         | ✅          | ✅              | ✅                 |

Enforcement:

- Feature flags + RLS read `subscription_tier` and `subscription_status`
- **Premium** → never includes bidding
- **Premium Plus** → only tier allowed to bid
- **Sanctuaries/nonprofits** → commercial flags hard-false regardless of billing status
- **Kids Mode** → no monetization ever, regardless of any provider tier

---

## 5. Provider Onboarding → Billing Flow

1. **Application**
   - Vendor / institution applies → `vendor_applications` / `institution_applications`
   - `moderation_status = 'pending'`

2. **Approval**
   - Admin approves via `admin_moderate_submission(...)`
   - Provider row created in `public.providers`
   - Defaults:
     - `subscription_tier = 'free'`
     - `subscription_status = 'inactive'` or `'active'` per doctrine
     - `payment_provider_customer_id = NULL` until Stripe handshake

3. **Billing Handshake**
   - User hits “Upgrade” in UI → redirected to Stripe Checkout / Billing Portal
   - On success:
     - Stripe webhook → ROOTED backend
     - We set:
       - `payment_provider_customer_id`
       - `subscription_status = 'active'`
       - `subscription_tier` matching plan

4. **Downgrade / Cancel**
   - Stripe marks subscription as canceled or past_due
   - Webhook updates `subscription_status` accordingly
   - Feature gates respect that state

---

## 6. Founding Vendor Doctrine (Jaindl, etc.)

Founding vendors (pre-launch anchor partners) are:

- Seeded manually by you (founder) via SQL or admin tools
- Given **lifetime Premium** (not Premium Plus) by policy
- Optionally: discounted Premium Plus upgrade later via Stripe plan

Implementation:

- `subscription_tier = 'premium'`
- `subscription_status = 'active'`
- `feature_flags` may include: `"is_founding_vendor": true`

Founding benefits are enforced by **feature flags and policy**, not by bypassing the canonical tier grid.

---

## 7. Non-Commercial Entities

Sanctuaries, rescues, and mission-first nonprofits:

- May have a Stripe customer record for *donations* later (future)
- May appear in discovery and volunteer flows
- May **not** access:
  - RFQs
  - Bids
  - Bulk marketplace
  - Paid ads

Even if Stripe says “active”, RLS and feature flags still block commercial tools.

---

## 8. Kids Mode and Billing

Kids Mode:

- Never shows pricing
- Never shows upgrade buttons
- Never shows subscriptions or donation CTAs
- Never reads `subscription_tier` for UI

All billing behavior is **adult-view-only** and strictly off in Kids Mode.

---

## 9. Security Considerations

- Payment data is never stored in ROOTED DB
- All billing actions are:
  - Logged via Stripe
  - Mirrored only as minimal state in `public.providers`
- Any additional billing table must:
  - Have RLS enabled
  - Be locked to provider owners and admins
  - Never store raw card / bank details

This file is canonical for billing behaviors across all ROOTED verticals.
