# ROOTED Core – Debug Toolkit

This doc is the **canonical reference** for debugging ROOTED’s core platform
(Supabase, auth, roles, RLS, media, GEO, analytics).

If a vertical is acting weird, start here.

---

## 1. Scope

Core covers:

- `user_tiers` + `feature_flags`
- Auth & session lookup
- RLS / policies on shared tables
- Media & storage (public vs protected)
- GEO & discovery rules
- Basic analytics plumbing

Vertical-specific bugs (Community, Construction, etc.) should still check
core first, then move to their own debug docs.

---

## 2. Quick Top-Down Checklist

Run these **in order** when something feels off:

1. **Who am I logged in as?**
   - Check `user_tiers` for this user.
   - Confirm `role` and `tier` are what you think they are.

2. **Is RLS blocking it?**
   - Look for RLS errors in Supabase logs.
   - Try the same query via Supabase “Run as user” if needed.

3. **Is the feature actually built in this vertical?**
   - If it references future verticals (healthcare, disaster, etc.),
     verify there’s real DB + UI wiring, not just docs.

4. **Is GEO/discovery hiding it?**
   - Confirm provider/landmark/event is marked “discoverable” and within
     radius / filters.

5. **Is media/storage blocking it?**
   - Check the bucket, object path, and storage policies.

6. **Is this just UI state?**
   - Refresh, log out/in, clear local storage; make sure feature flags
     aren’t stuck.

---

## 3. Auth & `user_tiers` Debug

### 3.1 Tables

- `auth.users` (Supabase)
- `user_tiers`
- Any `feature_flags` table or JSON column you use

### 3.2 Steps

1. Find test users in `auth.users`.
2. For each, ensure **exactly one** row in `user_tiers`:
   - `role` ∈ `['community','vendor','institution','admin']`
   - `tier` ∈ `['free','premium','premium_plus']`
3. In the app, log in as each and confirm:
   - Routing matches (`/community/...` vs `/vendor/...` etc.).
   - Premium-only UI doesn’t appear for free tier.

**If it fails:**

- Missing `user_tiers` row
- Wrong `role` / `tier`
- Front-end role routing using stale/incorrect logic

---

## 4. RLS & Permissions

### 4.1 Tables to sanity check

- `providers`
- `provider_media` / vendor media
- `conversations`, `conversation_participants`, `messages`
- `events`, `event_registrations`
- Analytics tables

### 4.2 Test pattern

For each table:

1. Use a **test vendor** account:
   - Try `SELECT`, `INSERT`, `UPDATE`, `DELETE` where appropriate.
   - Confirm vendor can only see/edit **their** rows.

2. Use a **test institution** account:
   - Confirm they can see what they should (e.g., their RFQs) and not
     other institutions’ private data.

3. Use an **admin** account:
   - Confirm they see everything that’s required for operations.

**Red flags:**

- “RLS: new row violates row-level policy” on actions that should be allowed.
- A non-admin seeing another user’s private rows.

---

## 5. Storage / Media

Buckets:

- `rooted-public-media`
- `rooted-protected-media`

### 5.1 Debug steps

1. Upload media in the app as:
   - Vendor
   - Institution

2. Confirm:
   - Successful upload (no 403/401).
   - Public media is viewable without auth when intended.
   - Protected media **does not** load in an incognito/private window.

3. If broken:
   - Check storage bucket policies in Supabase.
   - Check object key path (e.g., `vendors/{id}/...`) matches RLS rules.

---

## 6. GEO & Discovery

Core rule: **all discovery behavior follows the GEO docs in `rooted-core/docs/GEO_RULES.md`**.

### 6.1 Debug steps

1. In Community UI, open a “discover” map/list view.
2. Change:
   - Radius
   - Category
   - Any seasonal or “featured” filters
3. Confirm:
   - Only curated/allowed providers show.
   - Municipal / backend-only layers never show for normal users.

If a municipality or backend-only entity appears → data tagging + GEO rule bug.

---

## 7. Analytics Plumbing (High-Level)

Right now, analytics are **lightweight** in production.

### 7.1 Confirm:

- Events (clicks/views) write into the correct tables.
- Aggregation or materialized views are in place if already created.

If no data appears:
- Check that front-end is actually sending events.
- Check that RLS permits inserts from the client.

Full ETL / advanced analytics are future work; treat anything labeled
“advanced analytics” as **not guaranteed** until wiring is complete.

---

## 8. When In Doubt

If you can’t tell if something is:

- A core bug
- A vertical bug
- Or an unbuilt feature

Log a bug with:

- User role/tier
- Vertical + screen
- Exact action
- Expected vs actual

…and tag it as `core-unknown` until triaged.
