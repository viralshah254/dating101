# Frontend: Location, City Picker & Profile Updates

This doc describes what the frontend must do for **location**, **city/country picker**, and **profile creation/updates** related to location.

---

## 1. Overview

| Concern | Backend behavior | Frontend responsibility |
|---------|------------------|-------------------------|
| **Sign-up location** | Stored on Profile via `PATCH /profile/me` | Send `creationLat`, `creationLng`, `creationAt`, `creationAddress` when user completes profile setup |
| **Current city/country** | Derived from `POST /security/location` (reverse geocode) | Call `POST /security/location` when you have device location (app open, periodic) |
| **City picker (filters)** | `GET /location/cities`, `GET /location/countries` | Call these for the "Change city" / filter UI |
| **Manual city override** | `PATCH /profile/me` with `currentCity`, `currentCountry` | Optional: let user manually set city if they prefer |

---

## 2. New profiles (onboarding)

### 2.1 Sign-up location (one-time)

When the user **completes profile setup** and you have their location, send it in `PATCH /profile/me`:

```json
{
  "creationLat": 19.076,
  "creationLng": 72.8777,
  "creationAt": "2025-02-28T12:00:00Z",
  "creationAddress": "Mumbai, Maharashtra, India"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| creationLat | number | No | Latitude at sign-up |
| creationLng | number | No | Longitude at sign-up |
| creationAt | string | No | ISO 8601 timestamp when location was captured |
| creationAddress | string | No | Human-readable address (e.g. from reverse geocode) |

**When to send:** On the final step of profile creation, if the user has granted location. If they skip location, omit these fields.

### 2.2 City and country (manual or auto)

You can also set `currentCity` and `currentCountry` during profile creation:

```json
{
  "currentCity": "Mumbai",
  "currentCountry": "India"
}
```

- **Option A:** Let the user pick from the city picker (see §4) and send those values.
- **Option B:** Omit them; the backend will set them when you call `POST /security/location` later (see §3).

**Recommendation:** If you have device location at sign-up, call `POST /security/location` right after profile creation. The backend will reverse-geocode and set `currentCity` and `currentCountry` automatically. No need to send them in `PATCH` unless the user manually chose a city.

---

## 3. Updating profiles (location check-in)

### 3.1 Record location → auto-update city/country

**Endpoint:** `POST /security/location`

**When to call:**
- On app open (when you have location permission)
- Periodically (e.g. once per day) if the user travels
- After the user grants location permission for the first time

**Request:**
```http
POST /security/location
Authorization: Bearer <accessToken>
Content-Type: application/json
```

```json
{
  "lat": 19.076,
  "lng": 72.8777,
  "address": "Mumbai, Maharashtra, India"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| lat | number | Yes | -90 to 90 |
| lng | number | Yes | -180 to 180 |
| address | string | No | Optional; backend reverse-geocodes if omitted |

**Backend behavior:**
- Logs the location for security pattern analysis
- **Reverse-geocodes** lat/lng via Nominatim (OpenStreetMap)
- **Updates** `Profile.currentCity` and `Profile.currentCountry` for the user

So you do **not** need to call `PATCH /profile/me` to update city/country when the user's location changes—just call `POST /security/location` and the backend handles it.

### 3.2 Manual city/country override

If the user **manually selects** a city (e.g. in settings or filters), send it via `PATCH /profile/me`:

```json
{
  "currentCity": "London",
  "currentCountry": "United Kingdom"
}
```

Use this when:
- User chooses "I live in X" from the city picker
- User sets a "travel city" that becomes their primary display location (if your UX supports that)

---

## 4. City picker (filters / "Change city")

All location endpoints require auth: `Authorization: Bearer <accessToken>`.

### 4.1 Get nearby cities

```http
GET /location/cities?nearby=true&lat=-1.255062&lng=36.7470765&limit=10
Authorization: Bearer <accessToken>
```

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| nearby | string | Yes | `"true"` |
| lat | number | Yes | User's latitude |
| lng | number | Yes | User's longitude |
| limit | number | No | Default 10, max 50 |

**Response 200:**
```json
{
  "cities": [
    {
      "id": "city_nairobi_ke",
      "name": "Nairobi",
      "countryCode": "KE",
      "countryName": "Kenya",
      "userCount": 5,
      "isNearby": true,
      "distanceKm": 12.3
    }
  ]
}
```

**Use:** Show "Nearby" section in the city picker, sorted by distance.

### 4.2 Get countries with active users

```http
GET /location/countries
Authorization: Bearer <accessToken>
```

**Response 200:**
```json
{
  "countries": [
    {
      "code": "IN",
      "name": "India",
      "cityCount": 19,
      "userCount": 50
    },
    {
      "code": "KE",
      "name": "Kenya",
      "cityCount": 1,
      "userCount": 5
    }
  ]
}
```

**Use:** Populate the country dropdown. Only countries with active users are returned.

### 4.3 Get cities by country

```http
GET /location/cities?countryCode=IN&limit=20
Authorization: Bearer <accessToken>
```

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| countryCode | string | Yes | ISO code (e.g. `IN`, `KE`, `GB`) |
| limit | number | No | Default 10, max 50 |

**Response 200:**
```json
{
  "cities": [
    {
      "id": "city_mumbai_in",
      "name": "Mumbai",
      "countryCode": "IN",
      "countryName": "India",
      "userCount": 1247
    }
  ]
}
```

**Use:** After user selects a country, load cities for that country. Sorted by user count.

### 4.4 City picker flow (recommended)

1. **"Your area"** — Use device location; call `POST /security/location` so backend updates profile. For discovery, use `city=null` or omit → backend uses user's stored location.
2. **"Nearby cities"** — Call `GET /location/cities?nearby=true&lat=&lng=&limit=10` with device lat/lng. Show with `userCount`.
3. **"Other cities"** — Call `GET /location/countries` → user picks country → call `GET /location/cities?countryCode=X` → show cities with `userCount`.
4. Only show cities with `userCount > 0` (backend already filters; you can hide 0 for consistency).

---

## 5. Profile fields related to location

| Field | Writable via | Description |
|-------|--------------|-------------|
| currentCity | `PATCH /profile/me` or auto from `POST /security/location` | User's current city |
| currentCountry | `PATCH /profile/me` or auto from `POST /security/location` | User's current country |
| originCity | `PATCH /profile/me` | Hometown / place of origin |
| originCountry | `PATCH /profile/me` | Country of origin |
| creationLat | `PATCH /profile/me` | Sign-up latitude |
| creationLng | `PATCH /profile/me` | Sign-up longitude |
| creationAt | `PATCH /profile/me` | Sign-up timestamp |
| creationAddress | `PATCH /profile/me` | Sign-up address |

**Read-only:** `GET /profile/me` returns all of these. Use `currentCity` and `currentCountry` for display (e.g. "Lives in Mumbai, India").

---

## 6. Discovery and travel mode

- **Recommended feed:** `GET /discovery/recommended?mode=dating&city=London` — when `city` is set, shows profiles in that city (travel mode).
- **Explore:** `GET /discovery/explore?city=London&...` — same; `city` filter.
- **City value:** Use the city **name** (e.g. `"London"`, `"Mumbai"`) from the location API responses. The `id` (e.g. `city_london_gb`) is for your UI; the backend expects the name for filters.

---

## 7. Checklist for frontend

| # | Task |
|---|------|
| 1 | On profile creation: send `creationLat`, `creationLng`, `creationAt`, `creationAddress` if you have location |
| 2 | On app open / when location available: call `POST /security/location` with lat, lng |
| 3 | City picker: call `GET /location/cities?nearby=true&lat=&lng=` for nearby, `GET /location/countries` for country list, `GET /location/cities?countryCode=X` for cities in country |
| 4 | Use city **name** (not `id`) when passing `city` to discovery endpoints |
| 5 | Map zoom: enforce `minZoom: 9`, `maxZoom: 14` (see BACKEND_LOCATION_AND_GEOLOCATION.md) |
| 6 | Never display exact lat/lng to users; show "Within 5 km" or "2 miles away" |

---

## 8. Related docs

- [BACKEND_LOCATION_AND_GEOLOCATION.md](./BACKEND_LOCATION_AND_GEOLOCATION.md) — Backend spec (privacy, fuzzing, map zoom)
- [BACKEND_DISCOVERY_INTEGRATION.md](./BACKEND_DISCOVERY_INTEGRATION.md) — Discovery, travel city
- [FRONTEND_API_LIST.md](./FRONTEND_API_LIST.md) — Endpoint list
