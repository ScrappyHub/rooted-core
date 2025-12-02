# ROOTED — Stripe Integration Checklist (Canonical)

Status: 🧩 Wiring / Integration Guide  
Scope: ROOTED Core (all commercial verticals)  

This document describes **exactly** how to integrate Stripe with ROOTED without violating governance, Kids Mode, or sanctuary protection laws.

---

## 1. Stripe Setup

In the Stripe Dashboard:

1. Create a **Production** account.
2. Configure:
   - Business name: `ROOTED` (or your LLC name)
   - Support email + URL
3. Create Products / Prices:
   - `vendor_premium_monthly`
   - `vendor_premium_plus_monthly`
   - (future) institutional plans if separate

Write down:

- `STRIPE_SECRET_KEY`
- `STRIPE_PUBLISHABLE_KEY`
- Price IDs for each tier

---

## 2. Environment Variables

In your app(s) (Vercel / local `.env`):

```env
STRIPE_SECRET_KEY=sk_live_...
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_WEBHOOK_SIGNING_SECRET=whsec_...
