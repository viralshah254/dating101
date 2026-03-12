# Location, Geolocation & Maps — Backend Specification

**Purpose:** Dating-safety-first location handling: 2-mile accuracy, city/suburb zoom only, smart city picker with user counts. Free maps (OpenStreetMap).

---

## Table of contents

1. [Privacy & safety: 2-mile accuracy](#1-privacy--safety-2-mile-accuracy)
2. [Map zoom restrictions](#2-map-zoom-restrictions)
3. [City picker: nearby first, country→city, user counts](#3-city-picker-nearby-first-countrycity-user-counts)
4. [Free maps solution](#4-free-maps-solution)
5. [API endpoints](#5-api-endpoints)
6. [Database schema](#6-database-schema)
7. [Frontend integration](#7-frontend-integration)

---

## 1. Privacy & safety: 2-mile accuracy

**Requirement:** Never store or expose exact user location. Dating platforms must prevent stalkers from pinpointing addresses.

### Backend rules

| Rule | Implementation |
|------|----------------|
| **Store fuzzed coordinates** | When user shares location, round to ~2-mile grid. Example: `(51.5074, -0.1278)` → `(51.52, -0.12)` (grid cell ~3.2 km). |
| **Never return exact lat/lng** | In API responses, return only: `city`, `region`, `distanceKm` (rounded to 1 decimal), or grid-cell centroid. |
| **Distance display** | Show "Within 5 km" or "2 miles away" — never "123 m away". |
| **Map pins** | Always use blurred/approximate positions (grid centroid). Never plot exact address. |

### Fuzzing algorithm

```text
GRID_SIZE_KM ≈ 3.2  (≈2 miles)
lat_fuzzed = round(lat * (111 / GRID_SIZE_KM)) / (111 / GRID_SIZE_KM)
lng_fuzzed = round(lng * (111 * cos(lat) / GRID_SIZE_KM)) / (111 * cos(lat) / GRID_SIZE_KM)
```

Store `lat_fuzzed`, `lng_fuzzed` (or a geohash at precision ~5) in the user's location record. Use this for matching and map display.

---

## 2. Map zoom restrictions

**Requirement:** Users can zoom within city or suburb only — not to street level.

### Zoom levels (OpenStreetMap / Flutter Map)

| Level | Typical view | Allowed? |
|-------|--------------|----------|
| 0–8  | World / country | No (too zoomed out) |
| 9–10 | Region / metro | Yes (city level) |
| 11–12 | City / suburb | Yes |
| 13–14 | Neighborhood | Yes (suburb) |
| 15+ | Street / building | **No** (privacy risk) |

**Backend:** No backend change. Frontend enforces `minZoom: 9`, `maxZoom: 14` on the map.

**Optional:** If the map center is tied to a selected city, restrict the visible bounds to that city's bounding box so users cannot pan to unrelated areas.

---

## 3. City picker: nearby first, country→city, user counts

**Requirement:** Change city filter should:
1. Show **nearby cities** first (based on user's fuzzed location)
2. For others: **select country first**, then city
3. Show **user count** per city
4. **Only show cities with active users**

### Data model

```typescript
interface CityOption {
  id: string;           // e.g. "city_london_gb"
  name: string;        // "London"
  countryCode: string;  // "GB"
  countryName: string;  // "United Kingdom"
  userCount: number;    // active users in this city
  isNearby?: boolean;   // true if within ~X km of user
}

interface CountryOption {
  code: string;         // "GB"
  name: string;         // "United Kingdom"
  cityCount: number;   // cities with active users
  userCount: number;   // total active users
}
```

### API response shape

```text
GET /location/cities?nearby=true&limit=10
```

Returns nearby cities with active users, sorted by distance.

```text
GET /location/countries
```

Returns countries that have at least one city with active users, sorted by user count.

```text
GET /location/cities?countryCode=GB
```

Returns cities in GB with active users, sorted by user count.

---

## 4. Free maps solution

**Use OpenStreetMap (OSM)** — no API key, no cost.

| Component | Solution |
|-----------|----------|
| **Tiles** | `https://tile.openstreetmap.org/{z}/{x}/{y}.png` |
| **Geocoding** | Nominatim (free, OSM) — or use device geocoding for "Your area" |
| **Reverse geocoding** | Nominatim (free) |
| **User agent** | Required by OSM. Set `User-Agent` header. |

**Rate limits:** Nominatim allows 1 req/sec. Cache responses. For production, consider self-hosted Nominatim or a commercial geocoding service if you need higher throughput.

**Alternatives:** MapLibre, Mapbox (free tier), or continue with Flutter Map + OSM tiles.

---

## 5. API endpoints

### Location (city picker) — quick reference

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/location/countries` | Countries with active users |
| GET | `/location/cities` | Cities: `nearby=true&lat=&lng=` or `countryCode=X` |
| POST | `/security/location` | Record location (body: `lat`, `lng`, `address?`); backend auto-updates `Profile.currentCity` and `Profile.currentCountry` from reverse geocode |

**When to call location:** Once per day or on app open when you have location. Backend auto-updates `Profile.currentCity` and `Profile.currentCountry` from reverse geocode.

See **[FRONTEND_LOCATION_AND_PROFILES.md](./FRONTEND_LOCATION_AND_PROFILES.md)** for full frontend guide (profiles, city picker flow).

---

### 5.1 Get nearby cities

```http
GET /location/cities?nearby=true&limit=10
```

**Requires:** User's location (from fuzzed stored location or last known).

**Query:** `limit` (default 10).

**Response `200 OK`:**

```json
{
  "cities": [
    {
      "id": "city_london_gb",
      "name": "London",
      "countryCode": "GB",
      "countryName": "United Kingdom",
      "userCount": 1247,
      "isNearby": true,
      "distanceKm": 12
    }
  ]
}
```

**Only cities with `userCount > 0`.** Sort by `distanceKm` asc.

**Count accuracy:** `userCount` must equal the number of profiles returned by `GET /discovery/recommended?city={name}` (same city matching, same active definition). See [BACKEND_DISCOVERY_CITY_FILTER.md](./BACKEND_DISCOVERY_CITY_FILTER.md) § Count consistency.

---

### 5.2 Get countries with active users

```http
GET /location/countries
```

**Response `200 OK`:**

```json
{
  "countries": [
    {
      "code": "IN",
      "name": "India",
      "cityCount": 15,
      "userCount": 8450
    },
    {
      "code": "GB",
      "name": "United Kingdom",
      "cityCount": 8,
      "userCount": 3200
    }
  ]
}
```

**Only countries with active users.** Sort by `userCount` desc.

---

### 5.3 Get cities by country

```http
GET /location/cities?countryCode=GB
```

**Query:** `countryCode` (required).

**Response `200 OK`:**

```json
{
  "cities": [
    {
      "id": "city_london_gb",
      "name": "London",
      "countryCode": "GB",
      "countryName": "United Kingdom",
      "userCount": 1247
    },
    {
      "id": "city_manchester_gb",
      "name": "Manchester",
      "countryCode": "GB",
      "countryName": "United Kingdom",
      "userCount": 342
    }
  ]
}
```

**Only cities with `userCount > 0`.** Sort by `userCount` desc.

**Count accuracy:** `userCount` must equal the number of profiles returned by `GET /discovery/recommended?city={name}`. Use the same city field, matching logic, and active definition. See [BACKEND_DISCOVERY_CITY_FILTER.md](./BACKEND_DISCOVERY_CITY_FILTER.md) § Count consistency.

---

### 5.4 Update filter-options cities

**Extend** `GET /discovery/filter-options` (or add to it) so cities can be returned in the new shape:

```json
{
  "cities": {
    "options": ["Mumbai", "Delhi", "London"],
    "strict": false,
    "nearby": [
      { "id": "city_london_gb", "name": "London", "userCount": 1247 }
    ],
    "byCountry": {
      "IN": [
        { "id": "city_mumbai_in", "name": "Mumbai", "userCount": 2100 },
        { "id": "city_delhi_in", "name": "Delhi", "userCount": 1800 }
      ],
      "GB": [
        { "id": "city_london_gb", "name": "London", "userCount": 1247 }
      ]
    }
  }
}
```

**Or** keep filter-options as-is and add separate `GET /location/cities` and `GET /location/countries` calls. Frontend can call either.

---

## 6. Database schema

### User location (fuzzed)

```sql
CREATE TABLE user_locations (
  user_id         UUID PRIMARY KEY REFERENCES users(id),
  lat_fuzzed      DECIMAL(9,6) NOT NULL,   -- 2-mile grid
  lng_fuzzed      DECIMAL(9,6) NOT NULL,
  city_id         VARCHAR(50),             -- e.g. city_london_gb
  country_code    VARCHAR(2),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_locations_geo ON user_locations(lat_fuzzed, lng_fuzzed);
```

### Cities with active user counts

Pre-compute or query:

```sql
-- Materialized view or cached query
SELECT city_id, city_name, country_code, COUNT(*) as user_count
FROM user_locations ul
JOIN users u ON u.id = ul.user_id
WHERE u.last_active_at > NOW() - INTERVAL '30 days'
GROUP BY city_id, city_name, country_code
HAVING COUNT(*) > 0;
```

---

## 7. Frontend integration

### Map zoom

```dart
MapOptions(
  minZoom: 9,
  maxZoom: 14,
  // ...
)
```

### City picker flow

1. **Your area** — Use device location (fuzzed), set `travelCity = null` → discovery uses user's location.
2. **Nearby cities** — Call `GET /location/cities?nearby=true`, show with user count.
3. **Other cities** — User selects country → call `GET /location/cities?countryCode=X` → show cities with user count.
4. Only render cities with `userCount > 0`.

### Privacy copy

- "We use ~2 mile accuracy to protect your privacy."
- "Your exact location is never shown."
- "Privacy: Blurred" (map) — always default to blurred pins.

---

## 8. Checklist for backend

| # | Task |
|---|------|
| 1 | Implement location fuzzing (2-mile grid) when storing user location |
| 2 | Never return exact lat/lng in API responses |
| 3 | Implement `GET /location/cities?nearby=true` |
| 4 | Implement `GET /location/countries` |
| 5 | Implement `GET /location/cities?countryCode=X` |
| 6 | Only return cities/countries with active users (`userCount > 0`) |
| 7 | Include `userCount` in city responses |
| 8 | (Optional) Extend filter-options with new cities shape |

---

## 9. Related docs

- [FRONTEND_LOCATION_AND_PROFILES.md](./FRONTEND_LOCATION_AND_PROFILES.md) — Frontend guide (profiles, city picker flow)
- [BACKEND_DISCOVERY_INTEGRATION.md](./BACKEND_DISCOVERY_INTEGRATION.md) — discovery, travel city
- [BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md](./BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md) — filter options
