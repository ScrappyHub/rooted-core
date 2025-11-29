# ✅ ROOTED DEBUG TOOLKIT  
*(For Founder, Engineers, QA, & Future You)*

Status: Aligned with locked backend + ROOTED Community launch  
Scope: Supabase + App-level sanity checks

---

## 🧠 0. CORE PRINCIPLES

1. **We do not debug by guessing.** We use tools.
2. **We never bypass RLS.** If something fails, we debug *why*, not turn off security.
3. **We always test as real roles:**
   - individual / community
   - vendor_free / vendor_premium / vendor_premium_plus
   - institution_free / institution_premium / institution_premium_plus
   - admin
4. **We never “just change data.”** We understand what table it lives in and why.

This toolkit defines the **official ways** to debug ROOTED.

---

## 🧰 1. GLOBAL DEBUG TOOLS

These are tools everyone should know how to use.

### 1.1 Supabase SQL Editor

Use for:

- Read-only checks of tables
- Running provided debug queries
- Verifying RLS behavior by testing as different users (via UI/app)

**RULE:**  
❌ Do **not** modify schema or disable RLS in the SQL editor.  
✅ Only run queries from this toolkit, or explicit migration scripts.

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
- Resets on refresh

Use it to debug **UI behavior** without touching real data.

---

### 1.3 Feature Flag Helpers

These are defined in `public` schema:

```sql
select public.has_feature(<uuid>, 'can_use_bid_marketplace');
select public.current_user_has_feature('can_use_bid_marketplace');
Use these to quickly check:

“Can this user bid?”

“Does this user see advanced analytics?”

“Is this user actually premium_plus or did UI lie?”

1.4 Test User Matrix
For proper debugging, you should have test users like:

individual_test@...

vendor_free_test@...

vendor_premium_test@...

vendor_premium_plus_test@...

institution_free_test@...

institution_premium_test@...

institution_premium_plus_test@...

admin_test@...

Each should have a row in public.user_tiers that matches their role/tier.

Use them for end-to-end app testing, NOT just SQL.

🧪 2. ONE-SHOT BACKEND HEALTH CHECK (QUERY #365)
This is your “ROOTED Year 1 Health Snapshot”.
Run this anytime you want to verify core safety:

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
How to read it:
TABLE_RLS_STATUS

value = true → RLS is ON (good)

extra = number of policies

FUNCTION_CHECK

has_feature + current_user_has_feature should both be true

FEATURE_MATRIX

Verify the JSON for each role:tier matches the official flag grid

🧩 3. AREA-SPECIFIC DEBUG QUERIES
These are quick checks for each subsystem.

3.1 Roles & Feature Flags
sql
Copy code
select
  user_id,
  role,
  tier,
  feature_flags
from public.user_tiers
order by role, tier
limit 100;
Use when:

Someone says “I’m premium_plus but can’t bid.”

You need to confirm a test account’s power.

3.2 Providers & Ownership
sql
Copy code
select
  p.id,
  p.name,
  p.provider_type,
  p.vertical,
  p.owner_user_id
from public.providers p
order by p.created_at desc
limit 50;
Use when:

A vendor can’t see their provider profile.

An institution can’t access their RFQs or events.

3.3 RFQs + Bids
RFQs overview:

sql
Copy code
select
  r.id as rfq_id,
  r.title,
  r.status,
  r.institution_id,
  p.name as institution_name,
  p.provider_type,
  p.owner_user_id as institution_user_id
from public.rfqs r
join public.providers p on p.id = r.institution_id
order by r.created_at desc
limit 50;
Bids overview:

sql
Copy code
select
  b.id as bid_id,
  b.rfq_id,
  b.vendor_id,
  b.status,
  vp.name as vendor_name,
  vp.owner_user_id as vendor_user_id
from public.bids b
join public.providers vp on vp.id = b.vendor_id
order by b.created_at desc
limit 50;
Use when:

A premium_plus vendor can’t bid → check feature_flags + provider ownership.

An institution can’t see bids → check institution_id matches their provider.

3.4 Bulk Offers & Analytics
sql
Copy code
select
  bo.id,
  bo.provider_id,
  bo.title,
  bo.is_active,
  p.name as vendor_name,
  p.owner_user_id
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
  a.bids_count
from public.bulk_offer_analytics a
order by a.created_at desc
limit 50;
Use when:

Vendor says their bulk analytics look wrong.

You want to check that analytics are being written (by system) and read (by right vendor).

3.5 Media (Provider & Vendor)
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

Uploads aren’t appearing.

Wrong provider seems tied to media.

You need to verify owner_user_id / visibility.

3.6 Events & Registrations
sql
Copy code
select
  e.id,
  e.title,
  e.status,
  e.provider_id,
  p.name as host_name,
  p.owner_user_id as host_user_id
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
  e.title as event_title
from public.event_registrations r
join public.events e on e.id = r.event_id
order by r.created_at desc
limit 50;
Use when:

Hosts can’t see registrations.

Users say they registered but nothing appears.

3.7 Landmarks
sql
Copy code
select
  id,
  title,
  is_published,
  is_kids_safe,
  category,
  created_by
from public.landmarks
order by created_at desc
limit 50;
Use when:

Landmark isn’t appearing on map.

Kids view seems to miss something (check is_kids_safe).

3.8 Messaging
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

A vendor/institution can’t see a conversation.

Messages aren’t appearing in a thread.

3.9 Feed Items & Likes
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

Posts don’t show up.

Like counts look off (debug by counting feed_likes per feed_id).

🧭 4. /FOUNDER/PREVIEW DEBUG SCRIPTS
These are manual click-through tests.

4.1 Seasons Test
Go to /founder/preview.

Switch season → Spring, Summer, Fall, Winter.

Confirm:

Home UI colors change.

Maps and profiles visually respond.

Experiences / cards pick up seasonal styling.

4.2 Holiday Consent Test
In /founder/preview, enable a holiday set (e.g. us_civic_holidays).

Toggle:

User holiday set ON/OFF.

Business holiday set ON/OFF.

Confirm:

Holiday overlays only appear when both user + business enabled and date matches.

Kids Mode still has no holidays by default.

4.3 Dark Mode Test
Toggle dark mode.

Walk through:

Home

Map

Profiles

Experiences

Kids pages

Check:

No white-on-white text.

Cards and modals have clear background vs text contrast.

4.4 Kids Mode Test
Activate Kids Mode (via URL or internal toggle).

Check:

No access to RFQs, bids, marketplaces.

No messaging.

No institutions.

Only kids-safe experiences and landmarks.

Exit Kids Mode and confirm:

Normal views restored.

🚨 5. WHEN SOMETHING LOOKS WRONG (FLOW)
1. User can’t do something they should be able to:

Check user_tiers row for that user.

Check feature_flags.

Run select public.has_feature('<user_id>', '<flag>');

Confirm RLS policies match what you expect.

2. User can do something they should NOT be able to:

Check if their role or tier is mis-set.

Check if UI is accidentally logging in as a different account.

Verify RLS is enabled on that table and there isn’t a “too broad” policy (e.g. using (true) with to authenticated on ALL).

3. Data isn’t showing in UI:

Use the appropriate SQL debug query from Section 3 to confirm data exists.

If data is present:

It’s a UI filter/props issue.

If data is missing:

Check that the INSERT path is using the right IDs (user_id, provider_id, etc.).
