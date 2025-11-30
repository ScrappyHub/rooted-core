# ROOTED Core – Debug Toolkit (CANONICAL)

This is the canonical reference for debugging ROOTED’s **core platform**  
(Supabase, auth, roles, RLS, media, GEO, analytics).

If a vertical is acting weird, **start here**.

Related docs:

- `rooted-core/docs/ADMIN_AUTH_MODEL.md`
- `rooted-core/docs/MODERATION_SYSTEM.md`
- `rooted-core/docs/NOTIFICATIONS_SYSTEM.md`
- `rooted-core/docs/DISCOVERY_RULES.md`
- `rooted-core/docs/GEO_RULES.md`

---

## 1. Scope

Core covers:

- `auth.users`, `user_tiers`, `feature_flags`
- Auth & session lookup
- RLS / policies on shared tables
- Media & storage (public vs protected)
- GEO & discovery rules
- Basic analytics plumbing
- Admin debug dashboards & RPCs

Vertical-specific bugs (Community, Construction, Arts & Culture, etc.)  
should still check **Core first**, then move to their own debug docs.

---

## 2. Quick Top-Down Checklist

Run these **in order** when something feels off:

1. **Who am I logged in as?**
   - Check `auth.users` and `user_tiers` for this user.
   - Confirm `role` and `tier` are what you think they are  
     (`guest | individual | vendor | institution | admin` and `free | premium | premium_plus`).

2. **Is RLS blocking it?**
   - Look for RLS errors in Supabase logs.
   - Try the same query via Supabase “Run as user” if needed.

3. **Is the feature actually built in this vertical?**
   - If it references frozen verticals (healthcare, emergency, disaster, workforce),
     verify there’s real DB + UI wiring and not just docs.

4. **Is GEO/discovery hiding it?**
   - Confirm provider/landmark/event is marked discoverable and within radius / filters.
   - Check category + seasonal filters.

5. **Is media/storage blocking it?**
   - Check bucket, object path, and storage policies.
   - Test from an incognito window for public vs protected behavior.

6. **Is this just UI state?**
   - Refresh, log out/in, clear local storage.
   - Confirm feature flags for that user are correct.

If you still can’t tell, log it as `core-unknown` (see §8).

---

## 3. Auth & `user_tiers` Debug

### 3.1 Tables

- `auth.users` (Supabase)
- `public.user_tiers` (single source of truth for role/tier)
- `feature_flags` JSON on `user_tiers`

### 3.2 Steps

1. Find test users in `auth.users`.
2. For each, ensure **exactly one** row in `user_tiers`:
   - `role` ∈ `['guest','individual','vendor','institution','admin']`
   - `tier` ∈ `['free','premium','premium_plus']`
3. In the app, log in as each and confirm:
   - Routing matches (`/community/...` vs `/vendor/...` vs `/institution/...`).
   - Premium-only UI doesn’t appear for free tier.
   - Admin-only panels appear only for `role='admin'`.

**If it fails:**

- Missing `user_tiers` row
- Wrong `role` / `tier`
- Front-end routing using stale or hard-coded logic

---

## 4. RLS & Permissions

### 4.1 High-priority tables

- `providers`
- `provider_media` / `vendor_media`
- `conversations`, `conversation_participants`, `messages`
- `events`, `event_registrations`
- `landmarks`
- Analytics tables (`vendor_analytics_*`, `bulk_offer_analytics`, etc.)
- `moderation_queue`
- `notifications`

### 4.2 Test pattern

For each table, use three test accounts:

1. **Vendor**
   - Can `SELECT/UPDATE/DELETE` only their own rows.
   - Cannot see other vendors’ private data.

2. **Institution**
   - Can see their own RFQs, bids, events, etc.
   - Cannot see other institutions’ private data.

3. **Admin**
   - Can see everything needed for operations/moderation.
   - Still subject to RLS rules defined in `ADMIN_AUTH_MODEL.md`.

**Red flags:**

- “RLS: new row violates row-level policy” on actions that should be allowed.
- A non-admin seeing another user’s private rows.
- Any table with RLS disabled or enabled-with-zero-policies  
  (see RLS Health dashboard in §9.6).

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

   - Upload succeeds (no 401/403/500).
   - Public media is viewable without auth when intended.
   - Protected media **does not** load in incognito/private.

3. If broken:

   - Check Supabase Storage policies.
   - Check object key path (e.g. `vendors/{vendor_id}/...`) matches policy predicates.
   - Confirm UI is using the correct bucket and path.

---

## 6. GEO & Discovery

Core rule: discovery follows `rooted-core/docs/GEO_RULES.md` and `DISCOVERY_RULES.md`.

### 6.1 Debug steps

1. In Community UI, open a “discover” map/list view.
2. Adjust:
   - Radius
   - Category
   - Seasonal / featured filters

3. Confirm:

   - Only curated/allowed providers show.
   - Municipal / backend-only entities never show for normal users.
   - Kids Mode content respects Kids rules.

If a municipality or backend-only entity appears → data tagging or GEO rule bug.

---

## 7. Analytics Plumbing (High-Level)

Current state: **lightweight, not full BI**.

### 7.1 Confirm:

- Basic events (clicks/views) are writing to:
  - `vendor_analytics_daily`
  - `vendor_analytics_basic_daily`
  - `vendor_analytics_advanced_daily`
  - `bulk_offer_analytics`

- Any aggregations or materialized views that exist are updating.

If no data appears:

- Confirm front-end is actually sending the event.
- Confirm RLS permits inserts from that role/tier.
- Treat anything labeled “advanced analytics” as **best effort / WIP** until fully wired.

---

## 8. When In Doubt (Bug Filing)

If you can’t tell if something is:

- A core bug  
- A vertical bug  
- Or an unbuilt feature  

Log a bug with:

- User role & tier
- Vertical + screen
- Exact action
- Expected vs actual behavior
- Any relevant IDs (user_id, provider_id, event_id)

Tag it as `core-unknown` until triaged.

---

## 9. Admin Debug Dashboards & Tools

This section defines the **Admin Panel tools** that implement the debug flows above.  
They are split into:

- **Read-only inspectors** (no mutations)
- **Controlled admin actions** (RPCs with `is_admin()` checks)
- **Root-only helpers** (SQL-only, no UI)

### 9.1 Read-Only Inspectors

#### 9.1.1 Users & Accounts

**Back end:**

- View: `public.admin_user_accounts`  
  or RPC: `public.admin_get_user_accounts()`

**Shows per user:**

- `user_id`
- `email`
- `role`
- `tier`
- `account_status`
- `feature_flags`
- `deletion_status` (from `account_deletion_requests`)
- `deletion_requested_at`

**UI:**

- Search by email or user_id
- Filters by `role`, `tier`, `account_status`, `deletion_status`
- Click row → open **User Debug View**

---

#### 9.1.2 User Debug View

**Back end idea:** `debug_user_snapshot(user_id)` that aggregates:

- `auth.users`
- `user_tiers`
- `user_admin_actions` (history)
- `account_deletion_requests`
- `user_devices`
- Recent `notifications`
- Recent `moderation_queue` items with `submitted_by = user_id`

**UI Tabs:**

- Profile (email, created_at, last_sign_in)
- Tier & Flags (role, tier, feature_flags, account_status)
- Admin Actions Log
- Deletion Requests
- Devices
- Recent Notifications
- Submissions (events, landmarks, applications)

> 🔒 **Rule:** This view is read-only. All changes go through admin RPCs.

---

#### 9.1.3 Moderation → Queue

**Back end:**

- `SELECT` from `public.moderation_queue`
- Joined with:
  - `events` (`entity_type = 'event'`)
  - `landmarks` (`entity_type = 'landmark'`)
  - `vendor_applications` / `institution_applications` (future)

**Shows:**

- `id`
- `entity_type`
- `entity_id`
- `submitted_by`
- `status`
- `reason`
- `created_at`
- `reviewed_at`
- `reviewed_by`

**UI:**

- Filters: `status`, `entity_type`, `submitted_by`
- Click row →
  - show underlying entity data
  - show linked notifications
  - show Approve / Reject buttons (see §9.2.2)

---

#### 9.1.4 Notifications → Queue & History

**Back end:**

- `public.notifications`

**Views:**

- Queue: `where delivered = false`
- History: recent by `user_id` or `type`

**UI:**

- Queue tab: identify stuck notifications
- History tab: verify what a user was sent
- Optional “Resend” button → `admin_resend_notification(notification_id)`

---

#### 9.1.5 Onboarding → Applications (Vendor / Institution)

Once application tables exist:

- `vendor_applications`
- `institution_applications`
- Joined with `moderation_queue`
- Joined with `auth.users` (who submitted)

**Panels:**

- Vendor Applications (Pending / Approved / Rejected)
- Institution Applications (Pending / Approved / Rejected)

Approve / Reject use application RPCs in §9.2.3.

---

#### 9.1.6 Security → RLS Health

**Back end:**

A debug query that lists each table with:

- `table_name`
- `rls_enabled` (boolean)
- `policy_count` (# of policies)

**UI:**

- Highlight:
  - RLS disabled → ⚠️
  - RLS enabled but `policy_count = 0` → ⚠️

This is the **backdoor detector**.  
Fixes are done in migrations / SQL, not in the UI.

---

### 9.2 Controlled Admin Actions (RPC-backed Buttons)

All these RPCs:

- Call `public.is_admin()`  
- Write to `user_admin_actions` / `moderation_queue` / etc.  
- Are the **only** mutation paths from the admin UI.

#### 9.2.1 Account Status & Tier

**RPCs:**

- `admin_set_account_status(user_id, new_status)`
- `admin_set_role_tier(user_id, new_role, new_tier)`
- `admin_update_feature_flags(user_id, new_flags)`

**UI (from User Debug View):**

- Dropdown: `account_status` (`active`, `suspended`, `deleted`, etc.)
- Dropdown: `role` & `tier`
- JSON editor / toggles for `feature_flags`

Every change:

- Calls the appropriate RPC
- Logs to `user_admin_actions`

---


You can paste that into your GitHub debug doc verbatim.

---

## ✅ Canonical status

What we just did is now canon for ROOTED:

- ✅ `current_season()` exists and is the **only** place that defines seasons.
- ✅ `seasonal_featured_providers` is the **canonical seasonal discovery view**.
- ✅ Directory, map, and home feed are expected to **read from this view** (or join to it) when deciding who to boost.
- ✅ Admins have a **Season Debug** section to inspect behavior, not guess.

No new tables, no new columns, no kids-mode bypasses.  
Just **read-only seasonal intelligence** layered on top of your existing providers.

If you’re good with this, next we can either:

- Wire seasonal logic into **events/experiences** the same way, or  
- Move on to the next item on your big checklist (institutions, sanctuaries, community uploads lock, volunteer badges, etc.).


#### 9.2.2 Moderation Actions (Approve / Reject)

**RPC:**

---

```sql
admin_moderate_submission(
  moderation_id uuid,
  new_status text,          -- 'approved' or 'rejected'
  decision_reason text
)
