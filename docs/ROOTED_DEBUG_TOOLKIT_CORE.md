# ✅ ROOTED DEBUG TOOLKIT (v2)
_For Founder, Engineers, QA, & Future You_

Status: **Aligned with locked backend + ROOTED Community launch**  
Scope: **Supabase + App-level sanity checks** (ROOTED Core + Community + verticals)

---

## 🧠 0. CORE PRINCIPLES

1. **We do not debug by guessing. We use tools.**
2. **We never bypass RLS.**  
   If something fails, we debug *why*, we do **not** turn off security.
3. **We always test as real roles:**
   - `individual` / `community`
   - `vendor_free`, `vendor_premium`, `vendor_premium_plus`
   - `institution_free`, `institution_premium`, `institution_premium_plus`
   - `admin`
4. **We never “just change data.”**  
   We understand what table it lives in and why.
5. **We never bypass governance:**
   - `user_tiers`
   - `feature_flags`
   - `account_status`
   - `account_deletion_requests`
   - `user_admin_actions`
6. **Kids Mode and community safety rules are never disabled for convenience.**

This toolkit defines the **official ways** to debug ROOTED.

---

## 🧰 1. GLOBAL DEBUG TOOLS

### 1.1 Supabase SQL Editor

Use for:

- Read-only checks of tables
- Running the provided debug queries
- Verifying RLS behavior by testing as different users (via app)

**RULE:**

- ❌ Do **not** modify schema or disable RLS in the SQL editor.  
- ✅ Only run:
  - Queries from this toolkit, or
  - Explicit migration scripts.

All schema changes go through migrations / version control.

---

### 1.2 `/founder/preview` Route

**Purpose:**  
Safe, non-destructive way to test:

- Seasons
- Holidays
- Dark mode
- Kids Mode
- Role/tier simulations (visually)

**Rules:**

- Works via React state **only**
- Does **not** write to DB
- Resets on refresh / navigation

Use it to debug **UI behavior** without touching real data.

---

### 1.3 Feature Flag Helpers

Helpers in `public` schema:

```sql
select public.has_feature('<USER_UUID>', 'can_use_bid_marketplace');

select public.current_user_has_feature('can_use_bid_marketplace');
Use these to quickly answer:

“Can this user bid?”

“Can this user see advanced analytics?”

“Is this user actually premium_plus or did the UI lie?”

“Does this user actually have access to Construction or Arts & Culture?”

They read from public.user_tiers.feature_flags and respect the canonical flag grid.

1.4 Test User Matrix
Have real test accounts for end-to-end checks:

individual_test@...

vendor_free_test@...

vendor_premium_test@...

vendor_premium_plus_test@...

institution_free_test@...

institution_premium_test@...

institution_premium_plus_test@...

admin_test@...

Each must have a row in public.user_tiers that matches:

role

tier

account_status = 'active'

Correct feature_flags

Use these for app-level testing, not just SQL.

🧪 2. ONE-SHOT BACKEND HEALTH CHECK (ROOTED HEALTH SNAPSHOT)
This is your “ROOTED Year 1 Health Snapshot.”

Run this when you want to sanity-check core safety:

sql
Copy code
with critical_tables as (
  select unnest(array[
    'user_tiers',
    'providers',
    'provider_media',
    'vendor_media',
    'rfqs',
    'bids',
    'bulk_offers',
    'bulk_offer_analytics',
    'events',
    'event_registrations',
    'landmarks',
    'conversations',
    'conversation_participants',
    'messages',
    'feed_items',
    'feed_comments',
    'feed_likes',
    'vendor_analytics_basic_daily',
    'vendor_analytics_advanced_daily',
    'vendor_analytics_daily',
    'account_deletion_requests'
  ]) as table_name
),
rls_status as (
  select
    c.relname as table_name,
    c.relrowsecurity as rls_enabled
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
),
policy_counts as (
  select
    schemaname as schema_name,
    tablename as table_name,
    count(*) as policy_count
  from pg_policies
  where schemaname = 'public'
  group by schemaname, tablename
),
feature_matrix as (
  select
    role,
    tier,
    feature_flags ->> 'can_use_bid_marketplace'      as can_use_bid_marketplace,
    feature_flags ->> 'can_use_bulk_marketplace'     as can_use_bulk_marketplace,
    feature_flags ->> 'can_view_basic_analytics'     as can_view_basic_analytics,
    feature_flags ->> 'can_view_advanced_analytics'  as can_view_advanced_analytics
  from public.user_tiers
),
function_check as (
  select
    exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'has_feature'
    ) as has_feature_fn,
    exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'current_user_has_feature'
    ) as current_user_has_feature_fn
)
select
  'TABLE_RLS_STATUS' as section,
  ct.table_name      as key,
  coalesce(rs.rls_enabled, false)::text as value,
  coalesce(pc.policy_count, 0)::text    as extra
from critical_tables ct
left join rls_status   rs on rs.table_name = ct.table_name
left join policy_counts pc on pc.table_name = ct.table_name

union all

select
  'FUNCTION_CHECK'    as section,
  'has_feature'       as key,
  has_feature_fn::text  as value,
  null::text            as extra
from function_check

union all

select
  'FUNCTION_CHECK'          as section,
  'current_user_has_feature' as key,
  current_user_has_feature_fn::text as value,
  null::text                        as extra
from function_check

union all

select
  'FEATURE_MATRIX' as section,
  role || ':' || coalesce(tier, 'none') as key,
  jsonb_build_object(
    'can_use_bid_marketplace',      can_use_bid_marketplace,
    'can_use_bulk_marketplace',     can_use_bulk_marketplace,
    'can_view_basic_analytics',     can_view_basic_analytics,
    'can_view_advanced_analytics',  can_view_advanced_analytics
  )::text as value,
  null::text as extra
from feature_matrix

order by section, key;
How to read it
TABLE_RLS_STATUS

value = true → RLS is ON ✅

extra = number of RLS policies

FUNCTION_CHECK

has_feature and current_user_has_feature must both be true

FEATURE_MATRIX

Check each role:tier row JSON against your canonical feature flag grid

If something is off:

Fix via migrations / policy updates, not by flipping RLS OFF.

🧩 3. AREA-SPECIFIC DEBUG QUERIES
3.1 Roles & Feature Flags
sql
Copy code
select
  user_id,
  role,
  tier,
  account_status,
  feature_flags
from public.user_tiers
order by role, tier
limit 100;
Use when:

“I’m premium_plus but can’t bid.”

“This vendor should see bulk analytics but doesn’t.”

“This institution says they have Construction access.”

3.2 Admin Governance & Audit
View what the Admin Panel sees:

sql
Copy code
select *
from public.admin_user_accounts
order by role, tier, email
limit 100;
Check admin actions log:

sql
Copy code
select
  admin_id,
  target_user_id,
  action_type,
  details,
  created_at
from public.user_admin_actions
order by created_at desc
limit 50;
Use when:

A user suddenly can’t access something

You need to see who changed role/tier/status

3.3 Providers & Ownership
sql
Copy code
select
  p.id,
  p.name,
  p.provider_type,
  p.vertical,
  p.owner_user_id,
  p.created_at
from public.providers p
order by p.created_at desc
limit 50;
Use when:

A vendor can’t see their provider profile

An institution can’t access RFQs or events tied to them

3.4 RFQs & Bids
RFQs:

sql
Copy code
select
  r.id as rfq_id,
  r.title,
  r.status,
  r.institution_id,
  p.name as institution_name,
  p.provider_type,
  p.owner_user_id as institution_user_id,
  r.created_at
from public.rfqs r
join public.providers p on p.id = r.institution_id
order by r.created_at desc
limit 50;
Bids:

sql
Copy code
select
  b.id as bid_id,
  b.rfq_id,
  b.vendor_id,
  b.status,
  vp.name as vendor_name,
  vp.owner_user_id as vendor_user_id,
  b.created_at
from public.bids b
join public.providers vp on vp.id = b.vendor_id
order by b.created_at desc
limit 50;
Use when:

A premium_plus vendor can’t bid → check feature_flags + provider ownership

An institution can’t see bids → check their RFQ’s institution_id matches their provider

3.5 Bulk Offers & Analytics
sql
Copy code
select
  bo.id,
  bo.provider_id,
  bo.title,
  bo.is_active,
  p.name as vendor_name,
  p.owner_user_id,
  bo.created_at
from public.bulk_offers bo
join public.providers p on p.id = bo.provider_id
order by bo.created_at desc
limit 50;
sql
Copy code
select
  a.id,
  a.offer_id,
  a.vendor_user_id,
  a.impressions,
  a.clicks,
  a.saves,
  a.bids_count,
  a.created_at
from public.bulk_offer_analytics a
order by a.created_at desc
limit 50;
Use when:

Vendor says “my bulk analytics look wrong”

You want to confirm analytics are being written and read correctly

3.6 Media (Provider & Vendor)
sql
Copy code
select *
from public.provider_media
order by created_at desc
limit 20;
sql
Copy code
select *
from public.vendor_media
order by created_at desc
limit 20;
Use when:

Uploads aren’t appearing

Wrong provider is attached to media

You need to verify owner_user_id / visibility

3.7 Events & Registrations
sql
Copy code
select
  e.id,
  e.title,
  e.status,
  e.moderation_status,
  e.provider_id,
  p.name as host_name,
  p.owner_user_id as host_user_id,
  e.created_at
from public.events e
join public.providers p on p.id = e.provider_id
order by e.created_at desc
limit 50;
sql
Copy code
select
  r.id,
  r.event_id,
  r.user_id,
  e.title as event_title,
  r.created_at
from public.event_registrations r
join public.events e on e.id = r.event_id
order by r.created_at desc
limit 50;
Use when:

Hosts can’t see registrations

Users claim they registered but you don’t see data

3.8 Landmarks
sql
Copy code
select
  id,
  title,
  is_published,
  is_kids_safe,
  category,
  created_by,
  created_at
from public.landmarks
order by created_at desc
limit 50;
Use when:

A landmark doesn’t appear on map

Kids view misses something (check is_kids_safe)

3.9 Messaging
sql
Copy code
select
  c.id,
  c.created_by,
  c.created_at
from public.conversations c
order by c.created_at desc
limit 50;
sql
Copy code
select
  cp.conversation_id,
  cp.user_id
from public.conversation_participants cp
order by cp.conversation_id desc
limit 50;
sql
Copy code
select
  m.id,
  m.conversation_id,
  m.sender_id,
  m.content,
  m.created_at
from public.messages m
order by m.created_at desc
limit 50;
Use when:

A vendor or institution can’t see a conversation

Messages aren’t appearing in a thread

3.10 Feed Items & Likes
sql
Copy code
select
  id,
  author_id,
  visibility_scope,
  is_kids_safe,
  created_at
from public.feed_items
order by created_at desc
limit 50;
sql
Copy code
select
  id,
  feed_id,
  user_id,
  created_at
from public.feed_likes
order by created_at desc
limit 50;
Use when:

Posts don’t show up

Like counts look off → you can count feed_likes per feed_id

3.11 Seasonal Featured Providers
Season + featured logic is driven by a view, e.g.:

public.seasonal_featured_providers

Debug what’s seasonally “hot” right now:

sql
Copy code
select *
from public.seasonal_featured_providers
order by weight desc, name
limit 50;
Season Debug Qs:

“Given today, which tags are active?”

“Which vendors are considered seasonally featured?”

If the view is empty during a big season → seed is wrong or filters too strict.

3.12 Moderation & Notifications
Moderation queue (events/landmarks/applications):

sql
Copy code
select
  id,
  entity_type,
  entity_id,
  submitted_by,
  status,
  reason,
  created_at,
  reviewed_at,
  reviewed_by
from public.moderation_queue
order by created_at desc
limit 50;
Notifications:

sql
Copy code
select
  id,
  user_id,
  type,
  title,
  delivered,
  created_at,
  delivered_at
from public.notifications
order by created_at desc
limit 50;
Use when:

Submissions are stuck in “pending”

Users say “I never got the approval notification”

3.13 Community Uploads Safety (Global Hibernation Check)
If community uploads exist, they must be globally gated.

Check the toggle (pattern):

sql
Copy code
select *
from public.app_settings
where key = 'community_uploads_enabled';
Expected for now:

value = 'false' (or absent → treated as disabled)

RLS on community upload tables requires this flag = true

This ensures:

Community uploads are possible at schema level

But blocked until you deliberately turn them on

🧭 4. /founder/preview DEBUG FLOWS
These are manual click-through tests. You don’t touch SQL here.

4.1 Seasons Test
In /founder/preview:

Switch season → Spring, Summer, Fall, Winter.

Confirm:

Home UI colors change

Map / cards visually respond

Experiences and vendor tiles pick up seasonal styling

4.2 Holiday Consent Test
In /founder/preview:

Enable a holiday set (e.g. us_civic_holidays)

Toggle:

User holiday set ON/OFF

Business holiday set ON/OFF

Confirm:

Holiday overlays only appear when:

Date matches

User opted in

Business opted in

Kids Mode still has no holidays by default

4.3 Dark Mode Test
Toggle dark mode.

Walk through:

Home

Map

Profiles

Experiences

Kids pages

Check:

No white-on-white text

Cards and modals have clear contrast

4.4 Kids Mode Test
Turn on Kids Mode:

Confirm:

No RFQs, bids, marketplaces

No messaging

No institution dashboards

Only kids-safe experiences and landmarks

Turn Kids Mode off:

Confirm normal views are restored

Confirm no weird stale “kids” filters remain in adult views

🚨 5. WHEN SOMETHING LOOKS WRONG (FLOW)
Case 1 — User can’t do something they should be able to
Check public.user_tiers row for that user:

role, tier, account_status

feature_flags

Run:

sql
Copy code
select public.has_feature('<USER_UUID>', '<flag_name>');
Confirm RLS policies on the relevant table

Test the same flow in the app as that test user

Case 2 — User can do something they should NOT be able to
Check if their role or tier is wrong

Check if UI logged in as another account by accident

Confirm:

RLS enabled on the table

No “catch-all” policy like:

sql
Copy code
using (true)
for all authenticated users

Case 3 — Data exists in SQL but not in UI
Use the appropriate query from Section 3 to confirm data is present

If present:

Bug is in UI filters / query parameters / route

If missing:

The INSERT path is broken

Check the IDs:

user_id

provider_id

institution_id

Foreign keys

🧱 6. RED-LINE SAFETY INVARIANTS
These are never violated, even in debug:

❌ Never disable RLS “just to check something”

❌ Never run UPDATE/DELETE directly on user_tiers without going through admin tools in real operations

❌ Never open community uploads for Kids Mode

❌ Never expose community member profiles publicly

❌ Never grant sanctuary / rescue entities commercial access

❌ Never bypass the account deletion pipeline

If you need to hotfix something:

Do it once, via a documented migration, and update the relevant docs & policies.

This document is canonical.
If a future script, function, or AI suggestion conflicts with this toolkit → this toolkit wins.
