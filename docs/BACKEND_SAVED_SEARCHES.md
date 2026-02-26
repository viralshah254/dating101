# Saathi — Saved Searches (Matrimony): Backend Contract

Backend behaviour for **saving current filters as a named search** and **notifications when new profiles match** a saved search. Frontend can show "Save search" and "Search: Software, Bangalore, 28–35" and subscribe to alerts when backend supports it.

**Related:** [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) (§4 Discovery, §4.7 Saved searches), [BACKEND_REQUESTS_SHORTLIST_FAMILY.md](./BACKEND_REQUESTS_SHORTLIST_FAMILY.md) (§8 Search and matches), [BACKEND_DISCOVERY_INTEGRATION.md](./BACKEND_DISCOVERY_INTEGRATION.md).

---

## 1. Overview

- **Saved search:** User applies filters (age, city, religion, education, etc.) and can save that combination as a named search (e.g. "Software, Bangalore, 28–35").
- **Notifications:** When new profiles match a saved search, the user can be notified (push or in-app badge) so they can review new matches.

---

## 2. API contract (backend to implement)

### 2.1 List saved searches

```http
GET /discovery/saved-searches
Authorization: Bearer <accessToken>
```

**Success** `200 OK`

```json
{
  "savedSearches": [
    {
      "id": "ss_abc",
      "name": "Software, Bangalore, 28–35",
      "filters": {
        "ageMin": 28,
        "ageMax": 35,
        "city": "Bangalore",
        "occupation": "Software"
      },
      "createdAt": "2026-02-26T10:00:00Z",
      "notifyOnNewMatch": true,
      "newMatchCount": 3
    }
  ]
}
```

- **name** — Optional display name (can be auto-generated from filters, e.g. "Software, Bangalore, 28–35").
- **filters** — Same shape as GET /discovery/explore query (ageMin, ageMax, city, religion, education, heightMinCm, diet, etc.).
- **notifyOnNewMatch** — Whether the user wants push/in-app notifications when new profiles match.
- **newMatchCount** — Optional: number of new profiles matching since last viewed (for badge).

---

### 2.2 Create saved search

```http
POST /discovery/saved-searches
Content-Type: application/json
Authorization: Bearer <accessToken>
```

**Request body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | No | Display name; if omitted, backend can derive from filters |
| filters | object | Yes | Same as explore params: ageMin, ageMax, city, religion, education, heightMinCm, diet, etc. |
| notifyOnNewMatch | boolean | No | Default true |

**Example**

```json
{
  "name": "Software, Bangalore, 28–35",
  "filters": {
    "ageMin": 28,
    "ageMax": 35,
    "city": "Bangalore",
    "religion": "Hindu",
    "education": "Master's"
  },
  "notifyOnNewMatch": true
}
```

**Success** `201 Created`

```json
{
  "id": "ss_abc",
  "name": "Software, Bangalore, 28–35",
  "filters": { ... },
  "createdAt": "2026-02-26T10:00:00Z",
  "notifyOnNewMatch": true
}
```

**Errors**

| HTTP | code | When |
|------|------|------|
| 400 | VALIDATION_ERROR | Invalid or empty filters |
| 409 | ALREADY_EXISTS | Same filters already saved (optional) |

---

### 2.3 Update saved search

```http
PATCH /discovery/saved-searches/:id
Content-Type: application/json
Authorization: Bearer <accessToken>
```

**Body:** `{ "name": "New name", "notifyOnNewMatch": false }` — both optional.

**Success** `200 OK` — return updated saved search.

---

### 2.4 Delete saved search

```http
DELETE /discovery/saved-searches/:id
Authorization: Bearer <accessToken>
```

**Success** `204 No Content` or `200 OK` with `{ "deleted": true }`.

---

### 2.5 Run saved search (get profiles)

Use existing **GET /discovery/explore** with the saved search’s `filters` applied. No new endpoint required; frontend passes the saved search filters to explore.

---

### 2.6 New-match count / mark viewed

So the app can show "3 new" and then clear the badge:

```http
POST /discovery/saved-searches/:id/viewed
Authorization: Bearer <accessToken>
```

**Success** `200 OK` — backend records that the user viewed results for this saved search; `newMatchCount` can reset to 0.

Optional: **GET /discovery/saved-searches** returns updated `newMatchCount` after viewing.

---

### 2.7 Notifications

When a new profile matches a saved search and `notifyOnNewMatch` is true:

- Backend (or a job) triggers a **push notification** or **in-app notification**: e.g. "3 new profiles match your search: Software, Bangalore, 28–35."
- Implementation is backend-specific (FCM, APNs, in-app feed).

---

## 3. Frontend usage

| Feature | Backend | Frontend |
|--------|---------|----------|
| Save current filters | POST /discovery/saved-searches | "Save search" in Refine/Explore sheet or after applying filters |
| List saved searches | GET /discovery/saved-searches | Settings or Discover → "Saved searches" list |
| Run saved search | GET /discovery/explore with saved filters | Tap a saved search → load Explore with those filters |
| Notify on new match | notifyOnNewMatch flag | Toggle in saved search row or detail |
| New match badge | newMatchCount in list | Badge on saved search row or Discover tab |
| Mark viewed | POST .../viewed | When user opens results for that saved search |

---

## 4. References

- [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) — Discovery (§4), filter params.
- [BACKEND_DISCOVERY_INTEGRATION.md](./BACKEND_DISCOVERY_INTEGRATION.md) — Filters, explore, filter-options.
