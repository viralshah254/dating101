# Backend: Discovery City Filter — Implementation Guide

**Purpose:** Ensure `GET /discovery/recommended` and `GET /discovery/explore` correctly filter profiles by city when the `city` query parameter is present.

---

## Problem

When a user selects "Mumbai" in the "Change city" picker (travel mode), the app expects to see **only** profiles from Mumbai. If the backend returns profiles from other cities (e.g. Mysore, London), the user sees wrong results and the feature is broken.

---

## Required behavior

| Endpoint | Query param | Behavior |
|----------|-------------|----------|
| `GET /discovery/recommended` | `city=Mumbai` | Return **only** profiles where `Profile.currentCity` (or equivalent) equals `"Mumbai"` (case-insensitive) |
| `GET /discovery/explore` | `city=Mumbai` | Same — only profiles in Mumbai |
| `GET /discovery/search` | `city=Mumbai` | Same — only profiles in Mumbai |

When `city` is **omitted** or empty: return profiles based on user's location/preferences (no city filter).

---

## Implementation checklist

1. **Read the `city` query parameter** from the request.
2. **If `city` is present and non-empty:**
   - Resolve aliases via `getCityFilterVariants(city)` — e.g. `Thiruvananthapuram` → `["Thiruvananthapuram", "Trivandrum"]`.
   - Filter: `WHERE currentCity IN (...variants)` (case-insensitive).
   - Use exact match within variants: `"Mumbai"` matches `"Mumbai"` or `"Bombay"`, not `"Mysore"` or `"London"`.
3. **If no profiles match:** Return `{ "profiles": [], "nextCursor": null }`.
4. **If `city` is omitted:** Apply normal discovery logic (user's location, preferences, etc.).

---

## Data model

Profiles should have a `currentCity` (or `city`) field. This is typically:
- Set by `POST /security/location` (reverse geocode)
- Or set manually via `PATCH /profile/me`

Match against this field when filtering.

---

## Example

**Request:**
```http
GET /discovery/recommended?mode=dating&city=Mumbai&limit=20
```

**Correct response:** Only profiles with `currentCity: "Mumbai"` (or "mumbai", "MUMBAI" — normalize as needed).

**Incorrect:** Returning profiles with `currentCity: "Mysore"`, `"London"`, etc.

---

## Count consistency (critical)

The **userCount** shown in the city picker (`GET /location/cities`) must match the number of profiles that would be returned by `GET /discovery/recommended?city=X` (or explore).

**Problem:** If the city picker shows "Thiruvananthapuram: 8 active" but discovery returns 0 profiles for that city, users lose trust. The counts are misleading.

**Requirement:** Both endpoints must use:

| Aspect | Requirement |
|--------|-------------|
| **City field** | Same field: `Profile.currentCity` |
| **City matching** | Same logic: exact match, case-insensitive, same aliases (e.g. Thiruvananthapuram = Trivandrum) |
| **Active definition** | Same: e.g. `last_active_at` within last 30 days |
| **Mode** | If discovery is mode-scoped (dating/matrimony), location counts should match that scope, or be mode-agnostic (total active) |

**Implementation:** Derive `userCount` for `GET /location/cities` from the same query/materialized view used by discovery. Do not use a separate, inconsistent count.

---

## City aliases (standardization)

The backend treats city aliases as the same city for filtering and counts. Example: `Trivandrum` and `Thiruvananthapuram` both match profiles in either city.

**Source:** `src/lib/city-aliases.ts`

| Canonical (display) | Aliases (DB may have either) |
|---------------------|------------------------------|
| Thiruvananthapuram | Trivandrum |
| Mumbai | Bombay |
| Bengaluru | Bangalore |
| Chennai | Madras |
| Kolkata | Calcutta |

- **Filtering:** `city=Thiruvananthapuram` or `city=Trivandrum` → `WHERE currentCity IN ('Thiruvananthapuram', 'Trivandrum')` (case-insensitive).
- **Location counts:** Trivandrum + Thiruvananthapuram merge into one city with combined `userCount`.
- **Filter-options / location API:** Return **canonical** names only (e.g. `Thiruvananthapuram`, `Bengaluru`).

**Frontend:** Use canonical names from `GET /location/cities` and `GET /discovery/filter-options` when passing `city` to discovery. Both aliases work, but canonical is preferred for consistency.

### Reference implementation

```typescript
/**
 * City aliases for discovery and location filtering.
 * Profiles may have "Trivandrum" or "Thiruvananthapuram" — we treat them as the same city.
 * Canonical name is used for display; all aliases match in DB queries.
 */

/** Canonical city name → all variants stored in DB (including canonical). */
export const CITY_ALIASES: Record<string, string[]> = {
  Thiruvananthapuram: ["Thiruvananthapuram", "Trivandrum"],
  Mumbai: ["Mumbai", "Bombay"],
  Bengaluru: ["Bengaluru", "Bangalore"],
  Chennai: ["Chennai", "Madras"],
  Kolkata: ["Kolkata", "Calcutta"],
};

/** Alias (any variant) → canonical name. Built at load. */
const ALIAS_TO_CANONICAL = (() => {
  const m = new Map<string, string>();
  for (const [canonical, aliases] of Object.entries(CITY_ALIASES)) {
    for (const a of aliases) {
      m.set(a.toLowerCase().trim(), canonical);
    }
  }
  return m;
})();

/** Given a city (canonical or alias), return all variants for DB filter. */
export function getCityFilterVariants(city: string | null | undefined): string[] {
  const trimmed = city?.trim();
  if (!trimmed) return [];
  const canonical = ALIAS_TO_CANONICAL.get(trimmed.toLowerCase()) ?? trimmed;
  const aliases = CITY_ALIASES[canonical];
  return aliases ? [...aliases] : [trimmed];
}

/** Given a city (canonical or alias), return the canonical name for display. */
export function getCanonicalCity(city: string | null | undefined): string {
  const trimmed = city?.trim();
  if (!trimmed) return "";
  return ALIAS_TO_CANONICAL.get(trimmed.toLowerCase()) ?? trimmed;
}

/** Expand cities (e.g. preferredLocations) to all variants for DB IN clause. */
export function expandCitiesToVariants(cities: string[]): string[] {
  const set = new Set<string>();
  for (const c of cities) {
    for (const v of getCityFilterVariants(c)) {
      set.add(v);
    }
  }
  return Array.from(set);
}
```

**Usage in discovery:** `WHERE currentCity IN (...getCityFilterVariants(city))` with `mode: "insensitive"`.

**Usage in location counts:** Group by `getCanonicalCity(currentCity)` so Trivandrum and Thiruvananthapuram merge.

---

## How the backend computes location counts and discovery filters

This section documents the **current backend behavior** so you can align frontend logic or other systems.

### Data source

All location-related data comes from **`Profile`**:

| Field | Type | Set by |
|-------|------|--------|
| `currentCity` | string? | `POST /security/location` (reverse geocode) or `PATCH /profile/me` |
| `currentCountry` | string? | Same |
| `lastActiveAt` | DateTime? | Updated on profile activity (e.g. login, discovery view) |

### 1. Location counts (`GET /location/cities`, `GET /location/countries`)

**Source:** `src/services/location.ts`

**Active user definition:** `lastActiveAt >= (now - 30 days)` OR `lastActiveAt IS NULL`

- Profiles with `lastActiveAt` in the last 30 days are counted.
- Profiles with `lastActiveAt = null` (new profiles, never updated) are also counted.

**Countries (`GET /location/countries`):**

- `WHERE currentCountry IS NOT NULL AND (lastActiveAt >= cutoff OR lastActiveAt IS NULL)`
- Group by `currentCountry`.
- `userCount` = count of profiles per country.
- `cityCount` = number of distinct `currentCity` values in that country.
- Sorted by `userCount` desc.
- Only countries with `userCount > 0` are returned.

**Cities (`GET /location/cities`):**

- Same active filter.
- `WHERE currentCity IS NOT NULL AND currentCountry IS NOT NULL AND (lastActiveAt >= cutoff OR lastActiveAt IS NULL)`
- Group by `(getCanonicalCity(currentCity), currentCountry)` so aliases (e.g. Trivandrum + Thiruvananthapuram) merge.
- `userCount` = count of profiles per canonical city.
- `countryCode` / `countryName` derived from `COUNTRY_MAP` (e.g. `"India"` → `"IN"`); unknown countries use first 2 chars of name.
- **Nearby mode** (`nearby=true&lat=&lng=`): distance from `CITY_COORDS` (static map). Cities not in `CITY_COORDS` get `distanceKm=9999` and sort last. `isNearby = distanceKm < 500`.

### 2. Discovery filter-options (`GET /discovery/filter-options`)

**Source:** `src/services/discovery.ts` → `getFilterOptions`

**Cities:** `DISTINCT currentCity` from `Profile` where `currentCity IS NOT NULL`

- **No active filter** — includes all profiles with a city, regardless of `lastActiveAt`.
- Sorted alphabetically.
- `take: 100`.
- Fallback: if no cities in DB, returns `["Mumbai", "Delhi", "Bangalore", "Chennai", "Hyderabad", "Kolkata", "Pune", "London", "Dubai"]`.

**`defaults.city`:** `partnerPreferences.preferredLocations?.[0]` (user's preferred city from preferences).

### 3. Discovery city filter (recommended, explore, search)

**Source:** `src/matching/hard-filters.ts`, `src/services/discovery.ts`, `src/lib/city-aliases.ts`

- Resolve city via `getCityFilterVariants(city)` — e.g. `Thiruvananthapuram` → `["Thiruvananthapuram", "Trivandrum"]`.
- Filter: `currentCity IN (...variants)` with `mode: "insensitive"`.
- **No active filter** — discovery shows all profiles (subject to other filters: excluded, blocked, etc.).
- Aliases match: `"Mumbai"` matches `"Mumbai"` or `"Bombay"`; `"Thiruvananthapuram"` matches `"Trivandrum"`.

### 4. Alignment summary

| Aspect | Location counts | Filter-options cities | Discovery city filter |
|--------|-----------------|----------------------|------------------------|
| **Active filter** | Yes (30 days) | No | No |
| **Data source** | `Profile.currentCity`, `currentCountry` | `Profile.currentCity` | `Profile.currentCity` |
| **User count** | Yes (per city/country) | No (just list) | N/A |

**Potential mismatch:** City picker (`/location/cities`) shows only cities with **active** users. Filter-options (`/discovery/filter-options`) shows cities from **all** profiles. A city in filter-options might have 0 active users, so selecting it would return empty discovery results.

**Recommendation:** Use `GET /location/cities` and `GET /location/countries` for the city picker (they include `userCount` and only active users). Use `GET /discovery/filter-options` for other filters (age, religion, etc.); its `cities.options` can be replaced or supplemented by location API data when building the city picker UI.

**When location shows N active but discovery returns 0:** Discovery has no active filter, so it should return at least N profiles. The most likely cause is **city name mismatch** — e.g. profiles stored as `"Trivandrum"` but the request uses `"Thiruvananthapuram"`. Add city aliases (see § City aliases) so both names match the same canonical value.

---

## Related docs

- [BACKEND_DISCOVERY_INTEGRATION.md](./BACKEND_DISCOVERY_INTEGRATION.md) — Full discovery API contract
- [BACKEND_LOCATION_AND_GEOLOCATION.md](./BACKEND_LOCATION_AND_GEOLOCATION.md) — Location API, userCount
- [FRONTEND_LOCATION_AND_PROFILES.md](./FRONTEND_LOCATION_AND_PROFILES.md) — City picker flow, city name usage
