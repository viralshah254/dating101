# Discovery: Recommended & Explore — Pagination for Backend

Reference for **GET /discovery/recommended** and **GET /discovery/explore** for the Shubhmilan app. Both endpoints must support **cursor-based pagination** so the app can lazy-load more profiles as the user scrolls (Recommended and Search tabs).

**Auth:** `Authorization: Bearer <accessToken>` required for both.

---

## 1. Why the app needs this

- The app shows a **Recommended** feed and a **Search** (explore) feed.
- It **lazy-loads**: first request returns the first page (e.g. 30 profiles); when the user scrolls near the end, the app requests the **next page** using a cursor.
- **Response shape is critical:** the app only uses `body.profiles` and `body.nextCursor`. If the backend returns a different shape (e.g. `{ "count": 1 }` with no `profiles` array), the app shows "No recommendations yet" and cannot paginate.

---

## 2. GET /discovery/recommended

**Purpose:** AI/preference-based recommended profiles. Same logic as today; response **must** include a `profiles` array and optional `nextCursor` for pagination.

### Request

```http
GET /discovery/recommended?mode=matrimony&limit=30&cursor=usr_xyz
Authorization: Bearer <accessToken>
```

| Query   | Type   | Required | Description |
|---------|--------|----------|-------------|
| mode    | string | **Yes**  | `"dating"` or `"matrimony"` |
| limit   | number | No       | Page size. App uses **30**. Max **50**. |
| cursor  | string | No       | Opaque cursor from previous response’s `nextCursor`. Omit on first request. |
| city    | string | No       | **Travel mode:** restrict to this city. |

### Response — 200 OK

```json
{
  "profiles": [
    {
      "id": "usr_abc",
      "name": "Priya Sharma",
      "age": 28,
      "city": "Mumbai",
      "imageUrl": "https://...",
      "bio": "I am Priya...",
      "matchReasons": ["Lives in Mumbai", "Same religion — Hindu"],
      "compatibilityScore": 0.85,
      "compatibilityLabel": "Excellent match",
      "roleManagingProfile": "self",
      "occupation": "Software Engineer",
      "religion": "Hindu",
      "educationDegree": "Bachelor's",
      "maritalStatus": "Never married",
      "diet": "Vegetarian",
      "photoCount": 3,
      "verified": false,
      "interests": ["Reading", "Travel"],
      "sharedInterests": [],
      "motherTongue": "Hindi",
      "heightCm": 162
    }
  ],
  "nextCursor": "usr_xyz"
}
```

- **profiles** — Array of profile objects. **Never omit;** use `[]` when there are no results. Each item must match the app’s ProfileSummary shape (see main API reference §9.6).
- **nextCursor** — String or `null`.
  - If there is a **next page**: return an opaque cursor string (e.g. last profile id or a server-generated token). The app will send this back as the `cursor` query param on the next request.
  - If there is **no next page**: omit the key or set to `null`.

**Important:** The app does **not** use a response like `{ "count": 1 }` without a `profiles` array. That causes an empty feed. Always return `{ "profiles": [...], "nextCursor": "..." }` (or `nextCursor: null` when done).

---

## 3. GET /discovery/explore

**Purpose:** Filtered discovery (Search tab). Same response shape as recommended; supports the same pagination with `cursor` and `nextCursor`.

### Request

```http
GET /discovery/explore?mode=matrimony&limit=30&ageMin=25&ageMax=35&city=Delhi&religion=Hindu&cursor=usr_xyz
Authorization: Bearer <accessToken>
```

| Query        | Type   | Required | Description |
|-------------|--------|----------|-------------|
| mode        | string | **Yes**  | `"dating"` or `"matrimony"` |
| limit       | number | No       | Page size. App uses **30**. |
| cursor      | string | No       | From previous response’s `nextCursor`. Omit on first request. |
| ageMin      | number | No       | Minimum age filter |
| ageMax      | number | No       | Maximum age filter |
| city        | string | No       | City filter |
| religion    | string | No       | Religion filter |
| education   | string | No       | Education filter |
| heightMinCm | number | No       | Min height (cm) |
| heightMaxCm | number | No       | Max height (cm) |
| diet        | string | No       | Diet filter |
| bodyType    | string | No       | Body type filter |
| maritalStatus | string | No     | Marital status filter |

### Response — 200 OK

Same as recommended:

```json
{
  "profiles": [ { "id": "...", "name": "...", "age": 26, "city": "...", "imageUrl": "...", "bio": "...", "matchReasons": [...], "roleManagingProfile": "self", ... } ],
  "nextCursor": "usr_abc123"
}
```

- **profiles** — Array of profile objects; **never omit** (use `[]` if none).
- **nextCursor** — Cursor for the next page, or `null` / omit when no more results.

---

## 4. Cursor behaviour (backend)

- **First request:** Client sends no `cursor`. Return the first `limit` profiles (e.g. 30) and, if there are more, set `nextCursor` to an opaque value (e.g. last profile id or a token).
- **Next requests:** Client sends `cursor=<value from previous nextCursor>`. Return the **next** `limit` profiles after that cursor, and again set `nextCursor` if more results exist, otherwise `null` or omit.
- **No more pages:** Set `nextCursor` to `null` or omit it. The app will stop requesting more pages.
- Cursor must be **stable** for the same user/session (e.g. not invalidated by small filter changes if you support that; at minimum, same request params + same cursor must return the same “next” page).

---

## 5. Exclude “already sent interest” from Recommended

**Requirement:** Profiles the current user has **already expressed interest in** (normal or priority) must **not** appear in `GET /discovery/recommended`. Those profiles appear in the app’s **Requests** (inbox) flow; showing them again in Recommended is confusing and duplicates content.

- **Backend must:** When building the recommended list, exclude profile IDs that the authenticated user has already sent an interest to (from your interactions/sent-interest data).
- **Result:** Recommended only shows profiles the user has **not** yet sent interest to. Once they send interest, that profile disappears from Recommended on the next load and is only visible in Requests until/unless they match.

The app may apply a client-side filter as a fallback; the source of truth should be the backend exclusion.

---

## 6. Vary order of profiles (shuffle / randomize)

**Requirement:** The order of profiles in both **Recommended** and **Explore** should **vary** between requests (e.g. different sessions or refreshes), so the same user does not always see the same first N profiles.

- **Recommended:** When returning the first page (no `cursor`), the backend should order or randomize the list in a way that changes over time (e.g. shuffle within a relevance band, or use a random seed per user/session).
- **Explore:** Same for the first page of filtered explore results; order should not be identical on every load.
- **Pagination:** When using `cursor` for subsequent pages, the ordering must be consistent with the first page that produced that cursor (so “next page” is deterministic for that cursor).

---

## 7. Summary for backend

| Item | Requirement |
|------|-------------|
| **Recommended** | `GET /discovery/recommended` with `mode`, optional `limit` (app uses 30), optional `cursor`, optional `city`. Response: `{ "profiles": [...], "nextCursor": "..." \| null }`. Never return only `{ "count": N }`. **Exclude** profiles the user has already sent interest to. **Vary** order on first load (shuffle/randomize). |
| **Explore** | `GET /discovery/explore` with `mode`, optional filters, optional `limit` (app uses 30), optional `cursor`. Same response shape as recommended. **Vary** order on first load. |
| **Profile fields** | Each item in `profiles` must include at least: `id`, `name`, `age`, `city`, `imageUrl`, `bio`, `matchReasons` (array). For matrimony include `roleManagingProfile`. See main API reference for full ProfileSummary. |
| **Pagination** | Use cursor-based pagination; return `nextCursor` when more results exist, `null` or omit when done. |
| **Exclude sent interest** | Do not include in Recommended any profile the current user has already sent (normal or priority) interest to. |
| **Ordering** | First page of Recommended and Explore should have varied order (e.g. shuffle/randomize); cursor-based next pages must be consistent with that order. |

---

## 8. Related docs

- [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) — §4.1 (Recommended), §4.2 (Explore), §9.6 (ProfileSummary)
- [BACKEND_DISCOVERY_INTEGRATION.md](./BACKEND_DISCOVERY_INTEGRATION.md) — filters, travel mode, match reasons
