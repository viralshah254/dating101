# Saathi — Frontend Integration Guide

How to connect your app (React Native, React Web, Flutter, etc.) to the Saathi backend. Use this with the full [BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) for request/response details.

---

## Table of contents

1. [What you need on the frontend](#1-what-you-need-on-the-frontend)
2. [Base URL & headers](#2-base-url--headers)
3. [Auth & token handling](#3-auth--token-handling)
4. [Error handling](#4-error-handling)
5. [Pagination](#5-pagination)
6. [App flow: login → home vs onboarding](#6-app-flow-login--home-vs-onboarding)
7. [Endpoints by feature](#7-endpoints-by-feature)
8. [Discovery & matching (recommended, compatibility, feedback)](#8-discovery--matching)
9. [Photo uploads (S3 presigned URLs)](#9-photo-uploads-s3-presigned-urls)
10. [Quick reference](#10-quick-reference)

---

## 1. What you need on the frontend

| Need | Where / how |
|------|-------------|
| **Base URL** | `https://api.saathi.app` (prod) or `http://localhost:3000` (local). Make it env-driven. |
| **Access token** | From `POST /auth/verify-otp` (or refresh). Store securely (e.g. secure store / keychain). |
| **Refresh token** | From verify-otp. Store securely; use when access token expires (401). |
| **User ID** | From verify-otp (`userId`). Use for "my profile", "my preferences", and as viewer in discovery. |
| **HTTP client** | Any (fetch, axios, dio, etc.). Send `Content-Type: application/json` and `Authorization: Bearer <accessToken>` on all authenticated requests. |
| **Error parsing** | Every error body is `{ code, message, details? }`. Use `code` for logic, `message` for UI. |

Optional but recommended:

- **Entitlements** — Call `GET /subscription/entitlements` after login to know what the user can do (e.g. `canSendMessage`, `dailyInterestLimit`).
- **Mode** — Store whether the user is in **dating** or **matrimony** (or let them switch). Discovery and compatibility use `mode` in the query.

---

## 2. Base URL & headers

- **Base URL:**
  - Production: `https://api.saathi.app`
  - Local: `http://localhost:3000` (or your dev URL)

- **Every request:**
  - `Content-Type: application/json` (for bodies)
  - No auth for: `POST /auth/send-otp`, `POST /auth/verify-otp`, `POST /auth/refresh`

- **Authenticated requests:**
  - `Authorization: Bearer <accessToken>`

Example (fetch):

```ts
const API_BASE = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:3000';

function authHeaders(accessToken: string) {
  return {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${accessToken}`,
  };
}

async function api<T>(path: string, opts: { method?: string; body?: object; token?: string }): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: opts.method ?? 'GET',
    headers: opts.token ? authHeaders(opts.token) : { 'Content-Type': 'application/json' },
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw { status: res.status, ...data };
  return data as T;
}
```

---

## 3. Auth & token handling

### 3.1 Login flow (phone OTP)

1. **Send OTP**
   `POST /auth/send-otp`
   Body: `{ "countryCode": "+91", "phone": "9876543210" }`
   Response: `{ verificationId, expiresInSeconds }`.
   Store `verificationId` (and optionally show a countdown from `expiresInSeconds`).

2. **Verify OTP**
   `POST /auth/verify-otp`
   Body: `{ "verificationId": "<from step 1>", "code": "1234" }`
   In local dev with mock SMS, use code **`1111`**.
   Response: `{ accessToken, refreshToken, expiresIn, userId, isNewUser }`.

3. **Store**
   - `accessToken` → use for all authenticated requests.
   - `refreshToken` → use when you get 401 to get a new access token.
   - `userId` → current user id.
   - If `isNewUser === true`, show onboarding; otherwise you can go to home and then `GET /profile/me` to decide.

### 3.2 Refresh when token expires

On **401** from any authenticated call:

1. Call `POST /auth/refresh` with body `{ "refreshToken": "<stored>" }` (or send refresh token in `Authorization: Bearer <refreshToken>`).
2. Response: `{ accessToken, expiresIn }`. Replace stored access token.
3. Retry the original request with the new access token.
   If refresh returns 401, treat as logged out (clear tokens, redirect to login).

### 3.3 Sign out

`POST /auth/sign-out` with `Authorization: Bearer <accessToken>`. Then clear tokens and userId on the client.

---

## 4. Error handling

Every error response has this shape:

```json
{
  "code": "ERROR_CODE",
  "message": "Human-readable message",
  "details": {}
}
```

- **`code`** — Use for branching (e.g. `PROFILE_NOT_FOUND` → show profile setup; `VALIDATION_ERROR` → show field errors from `details`).
- **`message`** — Show in toasts or inline error text.
- **`details`** — Optional; often field-level errors for `VALIDATION_ERROR`.

Handle at least:

| HTTP | Code | Action |
|------|------|--------|
| 401 | — | Refresh token or redirect to login |
| 404 | PROFILE_NOT_FOUND | User has no profile → onboarding / profile setup |
| 400 | VALIDATION_ERROR | Show `details` on the form |
| 403 | PREMIUM_REQUIRED | Show upgrade prompt |
| 403 | DAILY_LIMIT | Show limit message |
| 429 | RATE_LIMITED | Back off and retry |

---

## 5. Pagination

List endpoints return:

```json
{
  "items": [ ... ],
  "nextCursor": "opaque_string_or_null"
}
```

(Some responses use `profiles`, `interests`, `threads`, `messages` instead of `items`; the key is that there is always a **nextCursor**.)

- **First page:** Omit `cursor` or send `cursor=`.
- **Next page:** Send `cursor=<nextCursor>` from the previous response.
- When `nextCursor` is `null`, there are no more pages.

Query params usually include `limit` (optional; backend has defaults).

Example:

```ts
const params = new URLSearchParams({ mode: 'matrimony', limit: '20' });
if (cursor) params.set('cursor', cursor);
const res = await api<{ profiles: Profile[]; nextCursor: string | null }>(
  `/discovery/recommended?${params}`, { token }
);
```

---

## 6. App flow: login → home vs onboarding

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐
│  Send OTP   │ ──▶ │  Verify OTP  │ ──▶ │ GET /profile/me│
│             │     │              │     │                │
└─────────────┘     └──────────────┘     └───────┬────────┘
                                                 │
                                    ┌────────────┴────────────┐
                                    │                         │
                               200 OK                   404 NOT FOUND
                                    │                         │
                                    ▼                         ▼
                              ┌──────────┐           ┌──────────────┐
                              │   Home   │           │  Onboarding  │
                              │ (Feed)   │           │ (Setup flow) │
                              └──────────┘           └──────────────┘
```

1. User completes phone OTP → you get `accessToken`, `refreshToken`, `userId`, `isNewUser`.
2. Call **`GET /profile/me`**:
   - **200** → User has a profile. Go to **Home** (e.g. discovery feed). You can still call `GET /subscription/entitlements` to drive UI (e.g. show upgrade for messaging).
   - **404** with `code: "PROFILE_NOT_FOUND"` → No profile yet. Show **onboarding** (mode selection → profile setup steps).
3. **Profile setup**
   - First time: **`PUT /profile/me`** with full or partial profile (including `creationLat`, `creationLng`, `creationAt`, `creationAddress` when you have them).
   - Later steps: **`PATCH /profile/me`** with only the fields that changed.
   - Partner preferences: **`PUT /profile/me/preferences`** when the user sets preferences.
4. After profile is created/updated, navigate to Home (e.g. discovery).

---

## 7. Endpoints by feature

### Auth (no token)

| Action | Method | Path | Body |
|--------|--------|------|------|
| Send OTP | POST | `/auth/send-otp` | `{ countryCode, phone }` |
| Verify OTP | POST | `/auth/verify-otp` | `{ verificationId, code }` |
| Refresh token | POST | `/auth/refresh` | `{ refreshToken }` or header |

### Auth (with token)

| Action | Method | Path |
|--------|--------|------|
| Sign out | POST | `/auth/sign-out` |

### Profile

| Action | Method | Path | Notes |
|--------|--------|------|-------|
| Get my profile | GET | `/profile/me` | 404 → onboarding |
| Update profile (partial) | PATCH | `/profile/me` | Merge; include creation* at sign-up |
| Replace profile | PUT | `/profile/me` | Full replace |
| Get preferences | GET | `/profile/me/preferences` | Partner preferences |
| Update preferences | PUT | `/profile/me/preferences` | Full replace |
| Get another profile | GET | `/profile/:userId` | Full profile |
| Get another summary | GET | `/profile/:userId/summary` | Card/summary view |
| Get photo upload URLs | POST | `/profile/me/photos/upload-url` | See [§9](#9-photo-uploads-s3-presigned-urls) |
| Delete photo | DELETE | `/profile/me/photos/:key` | URL-encode the S3 key |

### Security / location

| Action | Method | Path | Body |
|--------|--------|------|------|
| Record location | POST | `/security/location` | `{ lat, lng, address? }` |

Call when you have location (e.g. once per day or on app open).

### Discovery & matching

| Action | Method | Path | Query / body |
|--------|--------|------|--------------|
| Recommended (with compatibility) | GET | `/discovery/recommended` | `mode`, `limit`, `cursor` |
| Compatibility for one profile | GET | `/discovery/compatibility/:candidateId` | `mode` (optional) |
| Send feedback (like/pass/etc.) | POST | `/discovery/feedback` | `{ candidateId, action, timeSpentMs?, source? }` |
| Matching preferences (for UI) | GET | `/discovery/preferences` | — |
| Search | GET | `/discovery/search` | `ageMin`, `ageMax`, `city`, `religion`, `education`, `heightMinCm`, `limit`, `cursor` |
| Nearby | GET | `/discovery/nearby` | `lat`, `lng`, `radiusKm?`, `limit`, `cursor` |

### Interests

| Action | Method | Path | Body |
|--------|--------|------|------|
| Send interest | POST | `/interests` | `{ toUserId, message? }` |
| Received interests | GET | `/interests/received` | `limit`, `cursor` |
| Sent interests | GET | `/interests/sent` | `limit`, `cursor` |
| Accept | POST | `/interests/:interestId/accept` | — |
| Decline | POST | `/interests/:interestId/decline` | — |
| Withdraw | DELETE | `/interests/:interestId` | — |

### Shortlist

| Action | Method | Path |
|--------|--------|------|
| Get shortlist | GET | `/shortlist` |
| Add | POST | `/shortlist/:userId` |
| Remove | DELETE | `/shortlist/:userId` |
| Check | GET | `/shortlist/:userId/check` |

### Chat

| Action | Method | Path | Body |
|--------|--------|------|------|
| Get or create thread | POST | `/chat/threads` | `{ otherUserId }` |
| List threads | GET | `/chat/threads` | `limit` |
| Get messages | GET | `/chat/threads/:threadId/messages` | `limit`, `cursor` |
| Send message | POST | `/chat/threads/:threadId/messages` | `{ text }` |
| Mark read | POST | `/chat/threads/:threadId/read` | — |

### Subscription

| Action | Method | Path | Body |
|--------|--------|------|------|
| Get subscription | GET | `/subscription/me` | — |
| Purchase | POST | `/subscription/purchase` | `{ platform, receiptOrToken, planId }` |
| Restore | POST | `/subscription/restore` | `{ platform, receiptOrToken }` |
| Get entitlements | GET | `/subscription/entitlements` | — |

Use **entitlements** to show/disable features (e.g. messaging, "who liked you", daily limits).

---

## 8. Discovery & matching

Recommended and compatibility are driven by the user's **partner preferences** (gender, age, religion, etc.) and **strict filters**. The backend applies hard filters and returns scores and reasons. See [MATCHING_AND_COMPATIBILITY.md](./MATCHING_AND_COMPATIBILITY.md) for the full pipeline spec.

### 8.1 Recommended feed

**Request**

```http
GET /discovery/recommended?mode=matrimony&limit=20&cursor=usr_xyz
Authorization: Bearer <accessToken>
```

- **mode** (required): `"dating"` or `"matrimony"`.
- **limit** (optional): default 20, max 50.
- **cursor** (optional): from previous response's `nextCursor` for the next page.

**Response**

```json
{
  "profiles": [
    {
      "id": "usr_abc",
      "name": "Priya S.",
      "age": 27,
      "city": "Mumbai",
      "imageUrl": "https://cdn.saathi.app/photos/usr_abc/photo_1.jpg",
      "distanceKm": 4.2,
      "verified": true,
      "bio": "Product designer who loves hiking and chai.",
      "interests": ["Hiking", "Design", "Cooking"],
      "motherTongue": "Gujarati",
      "occupation": "Product Designer",
      "heightCm": 163,
      "religion": "Hindu",
      "community": "Patel",
      "educationDegree": "B.Des",
      "maritalStatus": "Never married",
      "diet": "Vegetarian",
      "photoCount": 4,
      "compatibilityScore": 0.87,
      "compatibilityLabel": "Excellent match",
      "matchReasons": [
        "Lives in Mumbai",
        "Same religion — Hindu",
        "Shares 3 interests with you"
      ],
      "breakdown": {
        "basics": 0.92,
        "culture": 0.88,
        "lifestyle": 0.80,
        "career": 0.85,
        "interests": 0.78,
        "family": 0.90,
        "location": 0.95
      }
    }
  ],
  "nextCursor": "usr_def456"
}
```

**Frontend usage**

- Use `profiles[].compatibilityScore` (0–1) and `compatibilityLabel` for badges (e.g. "Excellent match").
- Show up to 3 `matchReasons` on the card.
- Optionally show `breakdown` on the profile screen (basics, culture, lifestyle, career, interests, family, location).
- For "Load more", call again with `cursor=nextCursor`; when `nextCursor` is `null`, stop.

### 8.2 Compatibility for one profile

When the user opens a full profile, you can show the full compatibility breakdown.

**Request**

```http
GET /discovery/compatibility/:candidateId?mode=matrimony
Authorization: Bearer <accessToken>
```

**Response**

```json
{
  "candidateId": "usr_abc",
  "compatibilityScore": 0.87,
  "compatibilityLabel": "Excellent match",
  "matchReasons": ["Lives in Mumbai", "Same religion — Hindu", "Shares 3 interests with you"],
  "breakdown": {
    "basics": 0.92,
    "culture": 0.88,
    "lifestyle": 0.80,
    "career": 0.85,
    "interests": 0.78,
    "family": 0.90,
    "location": 0.95
  },
  "preferenceAlignment": {
    "age": "within_range",
    "religion": "match",
    "motherTongue": "match",
    "education": "match",
    "maritalStatus": "match",
    "diet": "match",
    "height": "within_range",
    "location": "same_city",
    "income": "close",
    "drinking": "match",
    "smoking": "match"
  }
}
```

**Frontend usage**

- Use for the "Why we matched" / compatibility section on the profile screen.
- `preferenceAlignment` values: `"match"`, `"close"`, `"within_range"`, `"no_preference"`, `"mismatch"` (and e.g. `"same_city"` for location). Map these to icons or short labels.

### 8.3 Feedback (like / pass / block)

Send feedback when the user acts on a profile so the backend can improve ranking and avoid showing the same profile again.

**Request**

```http
POST /discovery/feedback
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "candidateId": "usr_abc",
  "action": "like",
  "timeSpentMs": 4200,
  "source": "recommended"
}
```

- **candidateId** (required): Profile the user acted on.
- **action** (required): `"like"`, `"pass"`, `"superlike"`, `"block"`, `"report"`, or `"view"`.
- **timeSpentMs** (optional): Time spent on the profile in milliseconds.
- **source** (optional): `"recommended"`, `"search"`, or `"nearby"`.

**Response:** `200 OK` with `{ "recorded": true }`.

**Frontend usage**

- On "Like" / "Pass" / "Block", call this with the corresponding `action` and the displayed profile's `id` as `candidateId`.
- If you track time on screen, send `timeSpentMs`; otherwise omit it.
- Then remove that profile from the local feed and, if needed, load more (e.g. with current or new `cursor`).

### 8.4 Matching preferences (for UI)

**Request**

```http
GET /discovery/preferences
Authorization: Bearer <accessToken>
```

**Response**

```json
{
  "current": {
    "ageMin": 25,
    "ageMax": 32,
    "preferredReligions": ["Hindu"],
    "preferredMotherTongues": ["Gujarati", "Hindi"],
    "strictFilters": { "religion": true }
  },
  "suggestions": []
}
```

Use `current` to prefill the "Partner preferences" screen. `suggestions` can be used later for "Consider expanding age" etc.

---

## 9. Photo uploads (S3 presigned URLs)

Photos are uploaded directly to S3 from the client — no file bytes go through the API server.

### 9.1 Upload flow

```
┌──────────┐    1. POST /profile/me/     ┌──────────┐    2. PUT image bytes    ┌────┐
│  Client  │ ──  photos/upload-url   ──▶ │  Backend │                          │ S3 │
│  (app)   │ ◀─  { uploadUrl,        ─── │          │                          │    │
│          │      photoUrl, key }         └──────────┘                          │    │
│          │ ──────────────────────────────────────────────────────────────────▶ │    │
│          │                                                                    └────┘
│          │    3. PATCH /profile/me
│          │ ──  { photoUrls: [photoUrl, ...] }  ──▶  Backend stores URLs
└──────────┘
```

**Step 1 — Get presigned URLs**

```http
POST /profile/me/photos/upload-url
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "contentType": "image/jpeg",
  "count": 3
}
```

Response:

```json
{
  "uploads": [
    {
      "uploadUrl": "https://saathi-photos.s3.amazonaws.com/usr_abc/photo_1.jpg?X-Amz-...",
      "photoUrl": "https://cdn.saathi.app/photos/usr_abc/photo_1.jpg",
      "key": "usr_abc/photo_1.jpg"
    }
  ]
}
```

**Step 2 — Upload to S3**

```ts
await fetch(upload.uploadUrl, {
  method: 'PUT',
  headers: { 'Content-Type': 'image/jpeg' },
  body: imageBytes,
});
```

**Step 3 — Save URLs to profile**

```http
PATCH /profile/me
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "photoUrls": [
    "https://cdn.saathi.app/photos/usr_abc/photo_1.jpg",
    "https://cdn.saathi.app/photos/usr_abc/photo_2.jpg"
  ]
}
```

### 9.2 Delete a photo

```http
DELETE /profile/me/photos/usr_abc%2Fphoto_1.jpg
Authorization: Bearer <accessToken>
```

URL-encode the S3 key. The backend deletes from S3 and removes from `photoUrls`.

### 9.3 Display photos

Use the `photoUrl` (CDN URL) returned from the upload. When loading a profile, `photoUrls` contains the CDN URLs. First URL is the profile picture.

---

## 10. Quick reference

### Environment

| | Value |
|---|-------|
| Prod API | `https://api.saathi.app` |
| Local API | `http://localhost:3000` |
| Mock OTP (local) | Use code `1111` with `POST /auth/verify-otp` |

### Storage (client)

| Key | Purpose |
|-----|---------|
| `accessToken` | Every authenticated request |
| `refreshToken` | Used on 401 to get a new access token |
| `userId` | Current user |
| `mode` | `"dating"` or `"matrimony"` — sent to discovery endpoints |

### Critical flows

1. **Login:** send-otp → verify-otp → store tokens + userId → GET /profile/me → home or onboarding.
2. **Onboarding:** PUT/PATCH /profile/me (and creation* when available), PUT /profile/me/preferences → then home.
3. **Photo upload:** POST /profile/me/photos/upload-url → PUT bytes to S3 → PATCH /profile/me with photoUrls.
4. **Discovery:** GET /discovery/recommended?mode=… → show cards with compatibilityScore, matchReasons, breakdown → on action, POST /discovery/feedback → GET /discovery/compatibility/:id when opening a profile.
5. **401:** POST /auth/refresh with refreshToken → retry request; if 401 again, sign out.

### Related docs

| Document | Contents |
|----------|----------|
| [BACKEND_API_REQUIREMENTS.md](./BACKEND_API_REQUIREMENTS.md) | **Master checklist** — full list of APIs to build, build order, and links to detailed specs |
| [BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) | Full API reference — auth, profile, discovery, request/response fields, error codes, DTOs |
| [BACKEND_INTERACTIONS_AND_VISITORS.md](./BACKEND_INTERACTIONS_AND_VISITORS.md) | Interest, priority interest, shortlist, visitors, matches, accept/decline |
| [BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md](./BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md) | Explore filters and strict preferences — GET /discovery/filter-options |
| [MATCHING_AND_COMPATIBILITY.md](./MATCHING_AND_COMPATIBILITY.md) | ML matching pipeline — hard filters, scoring model, feature extraction, training |
| [profile.md](./profile.md) | Profile field audit — all fields collected by frontend, backend alignment |
