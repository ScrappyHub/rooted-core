# 🌱 ROOTED – UI DEBUG & QA CHECKLIST (NON-TECHNICAL)

> For founders, testers, and teammates who **don’t touch SQL**.  
> This is how to sanity-check ROOTED from the front-end only.

---

## 0. Before You Start

✅ Make sure you can log into the app.  
✅ Have access to these test accounts (or similar):

- `individual_test` (regular community user)
- `vendor_free_test`
- `vendor_premium_test`
- `vendor_premium_plus_test`
- `institution_test`
- `admin_test` (if available)

You **do not** need to know how they’re set up in the database.  
Just use them as “personas”.

---

## 1. Auth & Account Flows

Test for each user type (individual, vendor, institution):

1. **Sign in**
   - [ ] Can log in without weird errors
   - [ ] See the correct “home” for that role (community vs vendor vs institution)

2. **Log out**
   - [ ] Log out button works
   - [ ] You actually get logged out (no access to previous pages)

3. **Forgot password** (when wired)
   - [ ] Link is visible
   - [ ] Flow looks understandable (no broken screens)

4. **Delete account** (when wired)
   - [ ] Option is visible somewhere in settings/profile
   - [ ] There is a clear confirmation step (no accidental deletions)

If anything feels confusing, note **what you clicked** and **what you expected** vs **what you saw**.

---

## 2. Role-Based Views (Who Sees What)

### As an **Individual / Community User**

- [ ] You can see:
  - Directory / map
  - Vendor profiles
  - Events
  - Experiences (view-only)
- [ ] You CANNOT see:
  - RFQs
  - Bids
  - Vendor-only dashboards
  - Bulk/bid marketplace tools

### As a **Vendor**

Try with **free**, **premium**, and **premium_plus** accounts if you have them:

- [ ] You see a vendor dashboard or vendor home
- [ ] You can edit **your** provider profile
- [ ] You see marketplace/analytics buttons, but:
  - FREE: limited / mostly locked
  - PREMIUM: bulk options, basic analytics
  - PREMIUM_PLUS: full marketplace + analytics

### As an **Institution**

- [ ] You see an institution / organization dashboard
- [ ] You can:
  - See RFQs you created
  - View bids on **your** RFQs
- [ ] You cannot see other institutions’ private data

If you ever see **community users** entering B2B tools (RFQs, bids, analytics) → log that as a **high-priority bug**.

---

## 3. Kids Mode (Safety Check)

From a parent / account that can enable Kids Mode:

1. **Turn Kids Mode ON**
   - [ ] There is a clear way to enable it (kids button, toggle, or link)
   - [ ] There is some kind of parental step (PIN, confirmation, etc.)

2. In Kids Mode, verify:
   - [ ] No prices
   - [ ] No “book now” / “request quote” / “RFQ” buttons
   - [ ] No messaging / chat
   - [ ] No institution lists
   - [ ] Only kid-safe experiences and landmarks
   - [ ] Content looks “kid-facing” (language, visuals)

3. **Turn Kids Mode OFF**
   - [ ] There is a clear way back to the normal experience

If you ever see Kids Mode showing **money**, **bids**, or **B2B messaging** → that’s a **critical bug**.

---

## 4. Seasons & Holidays (/founder/preview)

Use `/founder/preview` or the “founder/preview” screen if available.  
This is a **safe sandbox** – it does not change real data.

1. **Season Toggle**
   - [ ] Switch between seasons (Spring / Summer / Fall / Winter)
   - [ ] Look for changes in:
     - Colors
     - Background accents
     - Cards / banners
   - [ ] Map & profiles should **feel** different per season (even subtle).

2. **Holiday Toggle**
   - [ ] Turn ON a holiday set (e.g., US civic holidays)
   - [ ] Turn OFF the same set
   - [ ] Confirm that:
     - With holidays OFF → normal seasonal look
     - With holidays ON → you see small holiday visuals *only* in appropriate spots

If holiday visuals appear when everything is OFF → log it.

---

## 5. Marketplaces (RFQs, Bids, Bulk)

### As a **Vendor Premium Plus**

- [ ] You see a way to:
  - Respond to RFQs
  - Manage bulk offers (if wired)
- [ ] You do **not** see weird errors when opening marketplace screens

### As a **Vendor Free / Premium (NOT Plus)**

- [ ] You might see “upgrade” or locked states
- [ ] You should NOT be able to:
  - Submit bids
  - See advanced analytics

### As an **Institution**

- [ ] You can:
  - Create RFQs (if UI is wired)
  - See bids on **your** RFQs
- [ ] You do not see other institutions’ private RFQ/bid details

If anyone other than **premium_plus vendor** can actually submit a bid → log as a major bug.

---

## 6. Events & Volunteering (UI Only)

### As a **Vendor / Institution**

- [ ] Check if there’s “Create event” or similar
- [ ] If it exists, walk through:
  - Title
  - Date
  - Location
  - Publish
- [ ] See if it appears in the event list/calendar

### As an **Individual / Community User**

- [ ] You can see events
- [ ] You can register / RSVP when that flow is built
- [ ] You are NOT asked to do scary admin things (no “approve registrations” or “manage” dashboards)

---

## 7. Landmarks & Map

On the map and landmark screens:

- [ ] Landmarks look educational (farms, historic places, etc.)
- [ ] You don’t see obvious ads plugged into landmarks
- [ ] In Kids Mode, you only see safe landmarks (no weird or adult-only locations)
- [ ] The map legend makes sense (no confusing municipal clutter for regular users)

If you see a landmark that looks like an ad or feels off-brand → note it.

---

## 8. Media & Galleries

As a **vendor**:

- [ ] You can upload a photo / video where expected
- [ ] Your upload appears on **your** profile or gallery
- [ ] You cannot see an “edit” button on other vendors’ media

As an **individual**:

- [ ] You can **view** media on vendor/institution profiles
- [ ] You do NOT see “upload” or “edit” options

---

## 9. Messaging (If UI is Exposed)

As a **vendor** or **institution**:

- [ ] You can start or view conversations with appropriate partners
- [ ] You can send messages inside those conversations
- [ ] You cannot see conversations you’re not part of

As a **community user**:

- [ ] You should NOT see B2B messaging tools

---

## 10. Feed, Posts & Likes

- [ ] You can see posts / updates in the feed
- [ ] You can “like” a post (if enabled)
- [ ] You cannot see a way to **post comments** (ROOTED is intentionally low-comment or no-comment)
- [ ] Nothing looks like a full-blown social media thread

If you find comment threads or arguments → that’s against the product’s intention and should be flagged.

---

## 11. Dark Mode & Mobile

### Dark Mode

- [ ] Toggle dark mode
- [ ] Walk through:
  - Home
  - Map
  - Profiles
  - Kids screens
- [ ] Make sure text is readable (no white-on-white or super low contrast)

### Mobile

On your phone or a narrow browser window:

- [ ] Check:
  - Navigation menu
  - Map
  - Cards
  - Modals
- [ ] Look for:
  - Overlapping text
  - Buttons off-screen
  - Horizontal scrolling where it shouldn’t be

---

## 12. How to Report Bugs (Simple Template)

When you find something, use this format:

**Title:** Short summary  
**Role:** (individual / vendor_free / vendor_premium / vendor_premium_plus / institution / admin)  
**Device:** (Desktop / Mobile + browser)  
**Where:** (page, section, or feature name)  
**Steps:**
1. I clicked…
2. Then I…
3. Then I expected…
4. But instead I saw…

**Screenshots:** Attach if you can.

This is enough for a dev (or future you) to track it down.

---

This checklist is meant to be **copied, printed, or shared** with anyone helping test ROOTED,  
without them ever needing to read SQL or touch Supabase.
