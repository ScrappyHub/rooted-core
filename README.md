## Discovery & Curated Vendor Layout

ROOTED Community must follow the platform-wide discovery rules defined in  
`rooted-core/docs/DISCOVERY_RULES.md`.

For all “discover vendors” sections in the Community app:

- Show **6–8 curated vendors** per section.
- Use a **50-mile radius** from the user’s location.
- Use a shared `CuratedVendorSection` component that calls the core
  `/api/vendors/curated` endpoint (once implemented).
- Filter buttons (Farms, Bakeries, Butchers, etc.) only change the
  `specialty` parameter – they do not change the layout or the 6–8 card rule.
