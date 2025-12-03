# ROOTED — STRIPE INTEGRATION CHECKLIST (CANONICAL)

Status: 🧩 Wiring / Integration Only  
Scope: ROOTED Core (Commercial Verticals Only)  
Authority Chain:
ROOTED_PLATFORM_CONSTITUTION.md  
→ ROOTED_ACCESS_POWER_LAW.md  
→ SANCTUARY & NONPROFIT COMMERCIAL RESTRICTION LAW  
→ This File

Stripe integration may NEVER bypass:

- Kids Mode restrictions
- Sanctuary commercial prohibitions
- Tier-based feature entitlements
- Account status enforcement
- Opt-in / consent law

---

## 1. Stripe Setup

- Production account only
- Products:
  - vendor_premium_monthly
  - vendor_premium_plus_monthly
- Future: institutions only if mirrored legally

---

## 2. Environment Variables

```env
STRIPE_SECRET_KEY=sk_live_...
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_WEBHOOK_SIGNING_SECRET=whsec_...
3. Webhooks (MANDATORY)
Required events:

checkout.session.completed

customer.subscription.updated

customer.subscription.deleted

All webhook handlers MUST:

Update user_tiers.tier

Update feature_flags

Log change to public.user_admin_actions

Trigger notification in public.notifications

4. Tier Enforcement Rules (NOT NEGOTIABLE)
Premium:

✅ Bulk tools

✅ Basic analytics

❌ Bidding

❌ Advanced analytics

Premium Plus:

✅ Bidding

✅ Bulk

✅ All analytics

Sanctuaries & Nonprofits:

❌ Stripe checkout disabled globally

❌ Subscription creation prohibited at DB level

5. Kids Mode Stripe Lock
If feature_flags.is_kids_mode = true:

❌ No checkout sessions may be created

❌ No Stripe redirects permitted

❌ No pricing visible

6. Stripe Never Becomes Authority
Stripe does NOT control:

Roles

Access

Discovery

Analytics

Moderation

Safety

Stripe only reflects what ROOTED already allows.

7. Failure Handling
If Stripe fails:

Subscription remains unchanged

Access remains unchanged

User notified via notifications system
