# ROOTED Billing & Subscription Architecture (Canonical)

Status: ✅ Canonical  
Scope: ROOTED Core (all verticals that use billing)  
Applies To: Vendors, Institutions, Admins  
Excludes: Community users, Kids Mode, sanctuaries/nonprofits for commercial tools  

---

## 1. Design Principles

ROOTED billing is:

- Governance-first, not revenue-first
- Privacy-preserving
- Stripe-anchored (no raw card/bank data in ROOTED DB)
- Tier-driven, not ad-hoc feature flags
- Explicitly safe for:
  - Children
  - Sanctuaries & rescues
  - Non-commercial nonprofits

All design must comply with:

- `ROOTED_PLATFORM_CONSTITUTION.md`
- `ROOTED_ACCESS_POWER_LAW.md`
- `ROOTED_SANCTUARY_NONPROFIT_LAW.md`
- `ROOTED_KIDS_MODE_GOVERNANCE.md`
- `BILLING_ABUSE_TEST_MATRIX.md`

---

## 2. Provider-Level Billing Fields

All commercial access is anchored at the **provider** level.

**Table:** `public.providers`

Canonical billing fields:

- `subscription_tier` (text)
  - `free | premium | premium_plus` (or future canonical values)
- `subscription_status` (text)
  - `inactive | trialing | active | past_due | canceled`
- `payment_provider_customer_id` (text)
  - e.g. `cus_xxxxx` (Stripe Customer ID)
- *(Optional future)* `payment_provider_subscription_id` (text)

These are the **only billing fields** ROOTED stores for providers.

ROOTED **never** stores:

- Card numbers
- Expiry dates
- CVC / CVV
- Bank account numbers
- Full invoice payloads
- Raw payment methods

All such data remains in Stripe.

---

## 3. Stripe Integration Pattern

Stripe is responsible for:

- Customer creation
- Subscription lifecycle
- Charging & invoicing
- Payment failures and chargebacks

ROOTED only keeps:

- Minimal mirrored state (`subscription_tier`, `subscription_status`)
- Provider/customer linkage ID (`payment_provider_customer_id`)

**Webhook flow:**

1. Stripe sends event → secured webhook endpoint.
2. Webhook handler verifies signature.
3. Handler locates provider by `payment_provider_customer_id`.
4. Handler updates:
   - `subscription_tier` (based on plan)
   - `subscription_status` (active, canceled, etc.)
5. No sensitive billing info is stored locally.

If signature verification fails → event ignored and logged.

---

## 4. Tier → Feature Mapping (Law Grid)

Feature access is defined centrally and enforced by RLS and feature flags.

| Role        | Tier          | Bulk Market | Bid Market | Basic Analytics | Advanced Analytics |
|-------------|---------------|------------:|-----------:|----------------:|-------------------:|
| Vendor      | free          | ❌          | ❌         | ✅ (limited)     | ❌                 |
| Vendor      | premium       | ✅          | ❌         | ✅              | ❌                 |
| Vendor      | premium_plus  | ✅          | ✅         | ✅              | ✅                 |
| Institution | free          | ❌          | ❌         | ✅ (own data)    | ❌                 |
| Institution | premium       | ✅          | ❌         | ✅              | ❌                 |
| Institution | premium_plus  | ✅          | ✅         | ✅              | ✅                 |
| Admin       | any           | ✅          | ✅         | ✅              | ✅                 |

Enforcement:

- Read/write on RFQs, bids, bulk offers, and analytics tables always check:
  - Role (from `user_tiers`)
  - `subscription_tier`
  - `subscription_status = 'active'`
  - Sanctuary/nonprofit flags
  - Kids Mode context where relevant

**Sanctuaries / rescues:**

- Commercial flags hard-false regardless of `subscription_tier`
- May never access:
  - RFQs
  - Bids
  - Bulk market
  - Ads

**Kids Mode:**

- No monetization surfaces, ever, regardless of the provider’s tier.

---

## 5. Onboarding → Billing Flow

### 5.1 Application

- Vendor/institution submits application.
- Stored in:
  - `public.vendor_applications`
  - `public.institution_applications`
- `moderation_status = 'pending'`
- Row added to `public.moderation_queue` (see `MODERATION_SYSTEM.md`).

### 5.2 Approval

- Admin approves via `admin_moderate_submission(...)`.
- Provider row created in `public.providers`.
- Initial billing state:
  - `subscription_tier = 'free'`
  - `subscription_status = 'inactive'` or `'active'` per doctrine
  - `payment_provider_customer_id = NULL` until Stripe handshake.

### 5.3 Billing Handshake

- User hits “Upgrade” in UI (adult view only).
- UI creates Stripe Checkout or Billing Portal session.
- On success:
  - Stripe webhook → ROOTED backend.
  - Backend sets:
    - `payment_provider_customer_id`
    - `subscription_tier` based on Stripe plan
    - `subscription_status = 'active'`

### 5.4 Downgrade / Cancel

- Stripe marks subscription as `canceled` / `past_due`.
- Webhook updates `subscription_status`.
- RLS and feature checks automatically treat provider as downgraded; premium-only features no longer accessible.

---

## 6. Founding Vendor Doctrine

Certain early anchor partners (e.g. Jaindl, cornerstone farms) may be granted **Founding Vendor** status.

Rules:

- Seeded manually by founder via SQL or admin tools.
- Granted **lifetime Premium** (`subscription_tier = 'premium'`), not Premium Plus.
- May be allowed **discounted Premium Plus** upgrades through Stripe if you choose later.

Implementation:

- `subscription_tier = 'premium'`
- `subscription_status = 'active'`
- `feature_flags`:
  - `"is_founding_vendor": true`
  - Optional `"has_discounted_upgrade": true`

Founding status does **not** bypass grid rules; it only sets defaults and discounts.

---

## 7. Non-Commercial Entities (Sanctuaries / Nonprofits)

Sanctuaries, rescues, and mission-first nonprofits:

- ✅ May have presence in ROOTED Community.
- ✅ May host education & volunteer events.
- ❌ May **not** use RFQs, bids, bulk markets, or ads.

Even if they have a Stripe customer for **donation**-style flows in the future:

- Commercial tools remain blocked via:
  - `provider_type`
  - Compliance overlays
  - RLS
  - Feature flags

Billing must never transform a protected entity into a commercial actor.

---

## 8. Kids Mode & Billing

Kids Mode is a **hard no-monetization zone**:

- No billing or upgrade views.
- No subscription language.
- No donation/fundraising CTAs.
- No pricing display.

Implementation:

- Billing routes check Kids Mode context and reject.
- Components check Kids Mode context and do not render.
- Any attempt to pass Kids Mode context to billing endpoints is blocked and logged.

---

## 9. Security Considerations

- Service keys are never exposed to the client.
- Webhook endpoints:
  - Require Stripe signature verification.
  - Perform idempotency checks for repeated events.
- All new billing tables:
  - Must enable RLS.
  - Must limit access to provider owner and admins.
  - Must avoid storing sensitive payment data.

For full abuse coverage, see: `BILLING_ABUSE_TEST_MATRIX.md`.

This architecture is canonical for all ROOTED billing integrations.
