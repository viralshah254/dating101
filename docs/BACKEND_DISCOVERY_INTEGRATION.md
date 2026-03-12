# Saathi — Discovery: Backend Integration (Frontend Contract)

This doc describes **what the frontend expects** from the discovery backend. Use it to implement or update APIs so the app’s Discovery screen (filters, travel mode, match reasons) works end-to-end.

**Related specs:**  
- [BACKEND_DISCOVERY_CITY_FILTER.md](./BACKEND_DISCOVERY_CITY_FILTER.md) — **City filter implementation** (critical for travel mode)  
- [BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md](./BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md) — filter options and strict preferences  
- [BACKEND_LOCATION_AND_GEOLOCATION.md](./BACKEND_LOCATION_AND_GEOLOCATION.md) — location privacy, city picker, map zoom  
- [MATCHING_AND_COMPATIBILITY.md](./MATCHING_AND_COMPATIBILITY.md) — matching pipeline and match reasons  

---

## Do we need to update the backend?

| Area | Backend change needed? | Notes |
|------|------------------------|--------|
| **Filter options** | Yes, if not implemented | Frontend calls `GET /discovery/filter-options` when the filters sheet opens. Response must follow [§ Filter options response](#filter-options-response) (or the alternate shape below). |
| **Strict preferences** | Yes, if not implemented | Filter options must respect user’s strict preferences (single option or locked range per dimension). See BACKEND_FILTER_OPTIONS_AND_PREFERENCES. |
| **Travel mode (city)** | Yes, if not supported | `GET /discovery/recommended` must accept optional query **`city`**. When present, return recommendations for that city (e.g. “explore London”) without changing the user’s home location. |
| **Explore with filters** | Yes, if not implemented | Frontend calls `GET /discovery/explore` with `ageMin`, `ageMax`, `city`, `religion`, `education`, `heightMinCm` when user applies filters. Same response shape as recommended. |
| **Match reasons** | Yes, if not in response | Each profile in **recommended** and **explore** responses must include **`matchReasons`** (array of strings), e.g. `["Lives in Mumbai", "Same religion — Hindu", "Shares 2 interests with you"]`. Optional: keep **`matchReason`** (single string) for backward compatibility. |
| **Compatibility** | Optional | Full profile uses `GET /discovery/compatibility/:candidateId` for detailed breakdown and match reasons; if missing, app falls back to profile’s `matchReasons`. |

---

## Endpoints the frontend uses

### 1. Recommended (main feed + travel mode)

```http
GET /discovery/recommended?mode={dating|matrimony}&limit=20&cursor={id}
GET /discovery/recommended?mode={dating|matrimony}&limit=20&city=London
```

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| mode | string | Yes | `dating` or `matrimony` |
| limit | number | No | Default 20, max 50 |
| cursor | string | No | Pagination (last profile id) |
| **city** | string | No | **Travel mode:** when set, return recommendations for this city only. |

**Critical — city filtering:** When `city` is present (e.g. `city=Mumbai`), the backend **must** return only profiles whose `currentCity` (or equivalent) matches the given city. Case-insensitive exact match is expected. Do **not** return profiles from other cities (e.g. Mysore when user selected Mumbai). If no profiles match, return an empty `profiles` array.

**Response:** `200 OK`

```json
{
  "profiles": [
    {
      "id": "usr_abc",
      "name": "Priya S.",
      "age": 27,
      "city": "Mumbai",
      "imageUrl": "https://...",
      "distanceKm": 4.2,
      "verified": true,
      "bio": "...",
      "interests": ["Hiking", "Design"],
      "matchReasons": [
        "Lives in Mumbai",
        "Same religion — Hindu",
        "Shares 2 interests with you"
      ]
    }
  ],
  "nextCursor": "usr_def"
}
```

**Required for “Why recommended” chips:** each object in `profiles` must include **`matchReasons`** (array of strings, 1–3 items). Optional: **`matchReason`** (single string) as fallback.

---

### 2. Explore (filtered feed)

```http
GET /discovery/explore?mode={dating|matrimony}&limit=20
  &ageMin=24&ageMax=35&city=London&religion=Hindu&education=Master's&heightMinCm=160
```

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| mode | string | Yes | `dating` or `matrimony` |
| limit | number | No | Default 20 |
| cursor | string | No | Pagination |
| ageMin, ageMax | number | No | Age range filter |
| city | string | No | City filter — only profiles in this city (same as recommended) |
| religion | string | No | Religion filter |
| education | string | No | Education level filter |
| heightMinCm | number | No | Min height (cm) filter |

**Response:** same as recommended (`profiles[]` with **`matchReasons`** per item, plus `nextCursor`).

**City filter:** When `city` is present, return only profiles whose `currentCity` matches (case-insensitive). See [BACKEND_DISCOVERY_CITY_FILTER.md](./BACKEND_DISCOVERY_CITY_FILTER.md).

Backend must enforce strict preferences server-side: if the user has a strict preference (e.g. religion = Hindu), ignore or override conflicting filter values. See BACKEND_FILTER_OPTIONS_AND_PREFERENCES §7.

---

### 3. Filter options (filters sheet)

```http
GET /discovery/filter-options
Authorization: Bearer <token>
```

**Response:** `200 OK` with a JSON object. Frontend supports **two** response shapes.

#### Preferred shape (strict-preferences)

See BACKEND_FILTER_OPTIONS_AND_PREFERENCES §4. Example:

```json
{
  "age": {
    "min": 18,
    "max": 60,
    "defaultMin": 24,
    "defaultMax": 35,
    "strict": false
  },
  "cities": {
    "options": ["Mumbai", "Delhi", "Bangalore", "London", "Dubai"],
    "strict": false
  },
  "religions": {
    "options": ["Hindu", "Muslim", "Christian", "Sikh", "Other"],
    "strict": false,
    "defaultSelected": null
  },
  "education": {
    "options": ["High School", "Bachelor's", "Master's", "Doctorate"],
    "strict": false
  },
  "diet": {
    "options": ["Vegetarian", "Vegan", "Eggetarian", "Non-vegetarian"],
    "strict": false
  }
}
```

For any dimension with **`strict: true`**, return only allowed option(s) (e.g. `"options": ["Hindu"], "defaultSelected": "Hindu"`). Frontend shows a “From your preferences” badge and does not allow changing that dimension.

#### Alternate shape (legacy)

If the backend returns `defaults` and `options` at top level:

```json
{
  "defaults": {
    "ageMin": 24,
    "ageMax": 35,
    "city": null,
    "religion": null,
    "education": null
  },
  "options": {
    "cities": ["Mumbai", "Delhi", "London", ...],
    "religions": ["Hindu", "Muslim", ...],
    "educationLevels": ["Bachelor's", "Master's", ...]
  }
}
```

Frontend maps this into the same UI; strict behaviour is not expressed in this shape (all dimensions are treated as non-strict).

---

### 4. Compatibility (full profile)

```http
GET /discovery/compatibility/:candidateId
Authorization: Bearer <token>
```

**Response:** `200 OK`

```json
{
  "candidateId": "usr_abc",
  "compatibilityScore": 0.87,
  "compatibilityLabel": "Excellent match",
  "matchReasons": ["Lives in Mumbai", "Same religion — Hindu", "Shares 3 interests with you"],
  "breakdown": { "basics": 0.92, "culture": 0.88, "lifestyle": 0.80, "career": 0.85, "interests": 0.78, "location": 0.95 },
  "preferenceAlignment": { "age": "within_range", "religion": "match", "location": "same_city" }
}
```

Used on the full profile screen for the compatibility card. If this endpoint is not implemented or fails, the app falls back to the profile’s **`matchReasons`** from the recommended/explore response.

---

### 5. Other discovery endpoints (unchanged)

| Endpoint | Purpose |
|----------|---------|
| `POST /discovery/feedback` | Record like, pass, superlike, block, report (with optional reason/details). |
| `GET /discovery/preferences` | Current matching preferences + suggestions (optional). |
| `GET /discovery/search` | Alternative to explore; same query params and response shape. |
| `GET /discovery/nearby?lat=&lng=&radiusKm=&limit=` | Map / nearby (dating). |

---

## Summary checklist for backend

- [ ] **`GET /discovery/filter-options`** — Implement and return the preferred shape (age, cities, religions, education, optional diet) with strict flags and defaults. Or support the alternate `defaults` + `options` shape.
- [ ] **`GET /discovery/recommended`** — Support optional query **`city`** for travel mode. Return **`matchReasons`** (array) on each profile.
- [ ] **`GET /discovery/explore`** — Accept filters (ageMin, ageMax, city, religion, education, heightMinCm). Enforce strict preferences server-side. Return **`matchReasons`** on each profile.
- [ ] **`GET /discovery/compatibility/:candidateId`** — Return **matchReasons** and breakdown (optional but improves full-profile UX).

Once these are in place, the Discovery filters sheet, “Change city” travel mode, and “Why recommended” chips will work against the real backend.
