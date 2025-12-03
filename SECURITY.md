# ROOTED Core — Security Posture (Canonical)

ROOTED Core enforces security at the **database and enforcement layer**, not just at the UI.

Security is treated as **platform law**, not as a feature.

---

## 1. Authentication

ROOTED relies on Supabase Auth for all authentication and password handling.

Passwords are:

✅ Never stored in plain text  
✅ Always hashed and salted using modern cryptographic standards  
✅ Never visible to ROOTED developers or administrators  

---

## 2. Authorization

All access is enforced through:

- Row Level Security (RLS)
- Admin-only RPCs
- Feature flag checks
- Account status checks

No UI-only enforcement is trusted.

---

## 3. Kids Mode Safety

When Kids Mode is enabled at the platform level:

- Monetization is blocked
- Messaging is blocked
- Commerce is blocked
- Fundraising is blocked
- Data persistence is restricted

Kids Mode is enforced in the **database layer**, not just the UI.

---

## 4. Sanctuary & Nonprofit Protection

Sanctuaries and rescues:

- ✅ May appear in discovery
- ✅ May host education & volunteer events
- ❌ May NOT use Premium, Premium Plus, or commercial tooling
- ❌ May NOT access bids, RFQs, or bulk procurement
- ❌ May NOT monetize through ads

These restrictions are enforced via:

- Provider type
- Feature flags
- Compliance overlays

---

## 5. Data Protection

ROOTED Core enforces:

✅ No medical records  
✅ No protected health data  
✅ No child identity data  
✅ No behavioral profiling  
✅ No ad tracking  
✅ No sale of personal data  

---

## 6. Audit & Abuse Resistance

- Admin actions must be logged
- Silent power changes are forbidden
- Raw role edits are forbidden
- Billing abuse is pre-tested
- Discovery manipulation is contractually blocked

---

## 7. Breach Philosophy

If a breach is detected:

- Access is immediately locked
- Tokens are revoked
- Admin review is mandatory
- Affected features are suspended until verified safe

Security is **fail-closed by design**.

---

ROOTED does not optimize for growth.
ROOTED optimizes for **safety, consent, and trust**.
