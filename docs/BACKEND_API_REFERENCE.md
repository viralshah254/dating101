# Saathi Backend API Reference

Complete API documentation for the Saathi dating/matrimony backend.

---

## Base URL & conventions

| Item | Value |
|------|--------|
| **Base URL** | `https://api.saathi.app` (use `http://localhost:3000` for local dev) |
| **Content-Type** | `application/json` for all request and response bodies |
| **Authorization** | After login: `Authorization: Bearer <accessToken>` |

### Error responses

All errors use this shape:

```json
{
  "code": "ERROR_CODE",
  "message": "Human-readable message",
  "details": {}
}
```

- `details` is optional (e.g. validation field errors).
- HTTP status: `4xx` client errors, `5xx` server errors.

### Pagination

List endpoints accept:

- **limit** (number) – max items per page (default varies by endpoint).
- **cursor** (string) – opaque token for the next page.

Responses include **nextCursor** (string or `null` when no more pages).

---

## 1. Auth API

Primary authentication is **phone OTP only**. Email auth is not supported.

### 1.1 Send OTP

```http
POST /auth/send-otp
Content-Type: application/json
```

**Request body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| countryCode | string | Yes | E.g. `"+91"`, `"+44"`, `"+1"` |
| phone | string | Yes | National number, digits only (e.g. `9876543210`) |

**Example**

```json
{
  "countryCode": "+91",
  "phone": "9876543210"
}
```

**Success** `200 OK`

```json
{
  "verificationId": "ver_abc123",
  "expiresInSeconds": 300
}
```

**Development (no Twilio):** When `SMS_PROVIDER=mock`, the backend uses a fixed OTP so you can sign in without SMS. Use code **`1111`** when verifying. Works with or without Redis.

**Errors**

| HTTP | code | When |
|------|------|------|
| 400 | INVALID_PHONE | Malformed or unsupported country/phone |
| 429 | RATE_LIMITED | Too many OTP requests |
| 500 | SEND_FAILED | SMS provider failure |

---

### 1.2 Verify OTP

```http
POST /auth/verify-otp
Content-Type: application/json
```

**Request body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| verificationId | string | Yes | From send-otp response |
| code | string | Yes | 4-digit OTP (e.g. `"1234"`). When `SMS_PROVIDER=mock`, use **`1111`**. |

**Success** `200 OK`

```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "expiresIn": 3600,
  "userId": "usr_abc123",
  "isNewUser": true
}
```

**Errors**

| HTTP | code | When |
|------|------|------|
| 400 | INVALID_CODE | Wrong OTP |
| 400 | EXPIRED_OTP | verificationId or OTP expired |
| 404 | NOT_FOUND | verificationId unknown |

---

### 1.3 Refresh token

```http
POST /auth/refresh
Content-Type: application/json
```

**Request body**

```json
{
  "refreshToken": "eyJ..."
}
```

Alternatively, send the refresh token in the header: `Authorization: Bearer <refreshToken>`.

**Success** `200 OK`

```json
{
  "accessToken": "eyJ...",
  "expiresIn": 3600
}
```

**Errors**

| HTTP | code | When |
|------|------|------|
| 401 | INVALID_TOKEN | Refresh token invalid or expired |

---

### 1.4 Sign out

```http
POST /auth/sign-out
Authorization: Bearer <accessToken>
```

**Success** `200 OK` – body: `{}`.

---

### 1.5 Social login (optional, future)

Same token shape as Verify OTP. Currently return **501 Not Implemented**:

- `POST /auth/google` – body: `{ "idToken": "..." }`
- `POST /auth/apple` – body: `{ "identityToken": "...", "authorizationCode": "..." }`

Email auth is **not supported**; there is no `/auth/email` endpoint.

---

## 2. Profile API

All profile endpoints require:

```http
Authorization: Bearer <accessToken>
```

### 2.1 Get my profile

```http
GET /profile/me
```

**Success** `200 OK` – body: **UserProfile** (see [§9.1 UserProfile](#91-userprofile)).

**Errors**

| HTTP | code | When |
|------|------|------|
| 401 | UNAUTHORIZED | Missing or invalid token |
| 404 | PROFILE_NOT_FOUND | No profile yet (app shows profile setup) |

---

### 2.2 Update my profile (partial)

```http
PATCH /profile/me
Content-Type: application/json
```

Send only the fields that changed; backend merges.

**Success** `200 OK` – body: full **UserProfile** as stored.

**Location at sign-up:** When the user completes profile setup, the app should send **creationLat**, **creationLng**, **creationAt** (ISO 8601 datetime), and **creationAddress** in the same PATCH body. The backend stores these on the profile for safety and support; they are part of **UserProfile** (§9.1).

**Errors**

| HTTP | code | When |
|------|------|------|
| 400 | VALIDATION_ERROR | Invalid fields (see `details`) |

---

### 2.3 Replace my profile (optional)

```http
PUT /profile/me
Content-Type: application/json
```

Body: full **UserProfile**. Backend replaces.

**Success** `200 OK` – body: full **UserProfile**.

---

### 2.4 Get partner preferences

```http
GET /profile/me/preferences
```

**Success** `200 OK` – body: **PartnerPreferences** (see [§9.5](#95-partnerpreferences)).

---

### 2.5 Update partner preferences

```http
PUT /profile/me/preferences
Content-Type: application/json
```

Body: **PartnerPreferences**.

**Success** `200 OK` – body: **PartnerPreferences** as stored.

---

### 2.6 Get profile by id

```http
GET /profile/:userId
```

**Success** `200 OK` – body: **UserProfile**. When the caller is another user (viewer), the response includes **`canRequestContactDetails`** (boolean): `true` if the viewer has a mutual match with this user or the viewer's entitlement allows contact requests (e.g. premium). Use for contact-request gating in the app. Sensitive fields may be masked for non-self viewers.

**Errors**

| HTTP | code | When |
|------|------|------|
| 404 | NOT_FOUND | Invalid userId or no profile |

---

### 2.7 Get profile summary by id

```http
GET /profile/:userId/summary
```

**Success** `200 OK` – body: **ProfileSummary** (see [§9.6](#96-profilesummary)). When the caller is a viewer (another user), the response includes **`canRequestContactDetails`** (boolean) for contact-request gating.

**Errors**

| HTTP | code | When |
|------|------|------|
| 404 | NOT_FOUND | Invalid userId or no profile |

---

### 2.8 Get photo upload URL(s) (S3 presigned + CloudFront)

Requires **S3** (and optionally **CloudFront**) to be configured via env: `S3_BUCKET`, `AWS_REGION` (default `ap-south-1`), optional `CLOUDFRONT_DOMAIN`; AWS credentials via `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` or IAM. Returns presigned PUT URLs so the client can upload images directly to S3. Profile `photoUrls` are stored as S3 keys and resolved to CloudFront (or S3) URLs when the profile is returned.

```http
POST /profile/me/photos/upload-url
Authorization: Bearer <accessToken>
Content-Type: application/json
```

**Request body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| count | number | No | Number of URLs (1–5). Default 1. |

**Success** `200 OK`

```json
{
  "urls": [
    {
      "uploadUrl": "https://bucket.s3.region.amazonaws.com/profiles/usr_abc/1234567890-abc.jpg?X-Amz-...",
      "key": "profiles/usr_abc/1234567890-abc.jpg",
      "photoUrl": "https://d123.cloudfront.net/profiles/usr_abc/1234567890-abc.jpg"
    }
  ]
}
```

- **uploadUrl** — Presigned PUT URL (expires in 5 minutes). Client uploads the image with `PUT` and `Content-Type: image/jpeg`.
- **key** — S3 object key; use this in **POST /profile/me/photos** after upload to add the photo to the profile.
- **photoUrl** — Public URL for display (CloudFront if `CLOUDFRONT_DOMAIN` is set, otherwise S3). Use for preview after upload.

**Flow:** 1) Request upload URLs. 2) Upload each image with `PUT` to `uploadUrl`. 3) Call **POST /profile/me/photos** with body `{ "key": "..." }` for each uploaded photo (or send the key in one call per photo).

**Errors**

| HTTP | code | When |
|------|------|------|
| 501 | NOT_IMPLEMENTED | S3 not configured (S3_BUCKET not set) |
| 503 | SERVICE_UNAVAILABLE | Failed to generate presigned URL |

---

### 2.9 Add photo after upload

Call after the client has successfully uploaded an image to the presigned `uploadUrl`. Adds the S3 key to the profile's `photoUrls` (stored as key; returned as CloudFront/S3 URL in profile responses).

```http
POST /profile/me/photos
Authorization: Bearer <accessToken>
Content-Type: application/json
```

**Request body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| key | string | Yes | S3 key returned from upload-url (e.g. `profiles/usr_abc/1234567890-abc.jpg`). Must belong to the current user. |

**Success** `201 Created`

```json
{ "photoUrl": "https://d123.cloudfront.net/profiles/usr_abc/1234567890-abc.jpg" }
```

**Errors:** `400 VALIDATION_ERROR` if key is not for the current user or max photos (10) reached.

---

### 2.10 Delete photo by key

```http
DELETE /profile/me/photos/:key
Authorization: Bearer <accessToken>
```

Removes the photo with the given key (or full URL; key is normalized) from the profile's `photoUrls` array.

**Success** `200 OK`: `{ "removed": true }` or `{ "removed": false }` if key was not found.

---

## 3. Security & location API

Location data is stored for **security and pattern analysis** (e.g. to detect unusual login locations). All endpoints require auth.

### 3.1 Location at sign-up

When the user completes profile setup, the app sends **creationLat**, **creationLng**, **creationAt**, and **creationAddress** in `PATCH /profile/me`. The backend persists these on **UserProfile**; no separate endpoint is required for sign-up location.

### 3.2 Record location (periodic check-in)

The app should call this endpoint when it has the user’s location—for example **once per day** or on app open—so the backend can build a location pattern for security.

```http
POST /security/location
Authorization: Bearer <accessToken>
Content-Type: application/json
```

**Request body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| lat | number | Yes | Latitude (-90 to 90) |
| lng | number | Yes | Longitude (-180 to 180) |
| address | string | No | Human-readable address (e.g. for support) |

**Example**

```json
{
  "lat": 19.076,
  "lng": 72.8777,
  "address": "Mumbai, Maharashtra, India"
}
```

**Success** `200 OK`

```json
{
  "recordedAt": "2025-03-01T14:30:00Z"
}
```

Each call creates a **location log** entry (timestamped). The backend can use this history to establish a pattern and flag unusual locations for security.

**Errors**

| HTTP | code | When |
|------|------|------|
| 400 | VALIDATION_ERROR | Missing or invalid lat/lng (e.g. out of range) |

### 3.3 Safety (block, report, blocked list, unblock)

All safety endpoints require auth. See **[BACKEND_SECURITY_BLOCK_REPORT.md](./BACKEND_SECURITY_BLOCK_REPORT.md)** for full request/response shapes.

| Method | Path | Description |
|--------|------|-------------|
| POST | /safety/block | Block a user with reason (body: blockedUserId, reason, source?). |
| POST | /safety/report | Report a user with reason and optional details (body: reportedUserId, reason, details?, source?). |
| GET | /safety/blocked | List blocked users with minimal profile (query: limit?, cursor?). |
| DELETE | /safety/blocked/:userId | Unblock a user. |

Block reason codes: `spam`, `harassment`, `inappropriate_content`, `fake_profile`, `other`.  
Report reason codes: `spam`, `harassment`, `inappropriate_photos`, `fake_profile`, `scam`, `other`.

---

## 4. Discovery API

All discovery endpoints require auth.

### 4.1 Recommended profiles

```http
GET /discovery/recommended?mode=dating&city=Mumbai&limit=20&cursor=usr_xyz
```

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| mode | string | Yes | `"dating"` or `"matrimony"` |
| city | string | No | **Travel mode:** when set, recommendations are for this city only (e.g. "Explore London"). |
| limit | number | No | Default 20, max 50 |
| cursor | string | No | Pagination cursor (last profile id) |

**Success** `200 OK` – each profile includes **`matchReasons`** (array of strings, 1–3 items) for "Why recommended" chips, plus `compatibilityScore`, `compatibilityLabel`, and optional `breakdown`.

```json
{
  "profiles": [ { "id": "...", "name": "...", "matchReasons": ["Lives in Mumbai", "Same religion — Hindu"], ... }, ... ],
  "nextCursor": "usr_abc123"
}
```

---

### 4.2 Explore (filtered feed)

```http
GET /discovery/explore?mode=matrimony&limit=20&ageMin=24&ageMax=35&city=London&religion=Hindu&education=Master's&heightMinCm=160&diet=Vegetarian
```

Same response shape as recommended. When filters are present, only profiles matching those filters are returned. **Strict preferences** (religion, education, diet) are enforced server-side: if the user has a strict preference set, it is applied (or overrides the request) so results always respect preferences.

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| mode | string | Yes | `"dating"` or `"matrimony"` |
| limit | number | No | Default 20 |
| cursor | string | No | Pagination cursor |
| ageMin, ageMax | number | No | Age range |
| city | string | No | City filter |
| religion | string | No | Religion filter |
| education | string | No | Education level filter |
| heightMinCm | number | No | Min height (cm) |
| diet | string | No | Diet filter |

---

### 4.3 Search profiles

```http
GET /discovery/search?ageMin=25&ageMax=35&city=Delhi&religion=Hindu&limit=20&cursor=...
```

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| ageMin | number | No | Minimum age |
| ageMax | number | No | Maximum age |
| city | string | No | City filter |
| religion | string | No | Religion filter |
| education | string | No | Education filter |
| heightMinCm | number | No | Min height (cm) |
| limit | number | No | Default 20 |
| cursor | string | No | Pagination cursor |

**Success** `200 OK` – same shape as recommended.

---

### 4.4 Nearby profiles

```http
GET /discovery/nearby?lat=19.076&lng=72.8777&radiusKm=10&limit=50&cursor=...
```

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| lat | number | Yes | Latitude |
| lng | number | Yes | Longitude |
| radiusKm | number | No | Default 10 |
| limit | number | No | Default 50 |
| cursor | string | No | Pagination cursor |

**Success** `200 OK` – same shape as recommended.

---

### 4.5 Get filter options (Explore tab)

```http
GET /discovery/filter-options
Authorization: Bearer <accessToken>
```

Returns filter options and defaults for the filters sheet. Response includes the **preferred shape** (strict-preferences) so the frontend can show "From your preferences" and lock strict dimensions, plus legacy **defaults** and **options** for backward compatibility.

**Success** `200 OK` – preferred shape:

```json
{
  "age": { "min": 18, "max": 60, "defaultMin": 24, "defaultMax": 35, "strict": false },
  "cities": { "options": ["Mumbai", "Delhi", "London", ...], "strict": false },
  "religions": { "options": ["Hindu", "Muslim", ...], "strict": false, "defaultSelected": null },
  "education": { "options": ["High School", "Bachelor's", "Master's", "Doctorate", ...], "strict": false, "defaultSelected": null },
  "diet": { "options": ["Vegetarian", "Vegan", "Eggetarian", "Non-vegetarian"], "strict": false, "defaultSelected": null },
  "defaults": { "ageMin": 21, "ageMax": 45, "city": null, "religion": null, "education": null, "heightMinCm": null },
  "options": { "religions": [...], "educationLevels": [...], "maritalStatuses": [...], "cities": [...] }
}
```

For any dimension with **`strict: true`**, only the allowed option(s) are returned (e.g. `religions: { "options": ["Hindu"], "strict": true, "defaultSelected": "Hindu" }`). Frontend shows a "From your preferences" badge and does not allow changing that dimension.

See **[BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md](./BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md)** for full spec.

---

### 4.6 Compatibility (full profile)

```http
GET /discovery/compatibility/:candidateId?mode=matrimony
Authorization: Bearer <accessToken>
```

Used on the full profile screen for the compatibility card. Returns **matchReasons**, **breakdown**, and **preferenceAlignment**.

**Success** `200 OK`

```json
{
  "candidateId": "usr_abc",
  "compatibilityScore": 0.87,
  "compatibilityLabel": "Excellent match",
  "matchReasons": ["Lives in Mumbai", "Same religion — Hindu", "Shares 3 interests with you"],
  "breakdown": { "basics": 0.92, "culture": 0.88, "lifestyle": 0.80, "career": 0.85, "interests": 0.78, "location": 0.95, "family": 0.7 },
  "preferenceAlignment": { "age": "within_range", "religion": "match", "location": "same_city", ... }
}
```

If this endpoint is not available or returns 404, the app can fall back to the profile’s **matchReasons** from the recommended/explore response.

---

### 4.7 Saved searches (matrimony)

Users can save current explore filters as a named search and get **newMatchCount** (badge) for profiles that match since they last viewed. Run a saved search by calling **GET /discovery/explore** with the saved search's **filters** as query params.

| Method | Path | Description |
|--------|------|-------------|
| GET | /discovery/saved-searches | List saved searches; each includes **newMatchCount** (profiles matching since last viewed). |
| POST | /discovery/saved-searches | Create (body: **filters** required, name?, notifyOnNewMatch?). |
| PATCH | /discovery/saved-searches/:id | Update name and/or notifyOnNewMatch. |
| DELETE | /discovery/saved-searches/:id | Delete. Returns `{ "deleted": true }`. |
| POST | /discovery/saved-searches/:id/viewed | Mark viewed; resets new-match count. Returns `{ "viewedAt": "..." }`. |

**Filters** shape: same as explore (ageMin, ageMax, city, religion, education, heightMinCm, diet, occupation, etc.). See [BACKEND_SAVED_SEARCHES.md](./BACKEND_SAVED_SEARCHES.md).

---

## 5. Interests API

All endpoints require auth. Powers "Express Interest" (matrimony) and intros (dating).

### 5.1 Send interest

```http
POST /interests
Content-Type: application/json
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| toUserId | string | Yes | Target user id |
| message | string | No | Optional intro message (dating) |

**Success** `201 Created`

```json
{
  "id": "int_xyz",
  "fromUserId": "usr_abc",
  "toUserId": "usr_def",
  "sentAt": "2025-03-01T10:00:00Z",
  "status": "pending"
}
```

**Errors**

| HTTP | code | When |
|------|------|------|
| 400 | ALREADY_SENT | Interest already sent to this user |
| 403 | DAILY_LIMIT | Free tier daily limit reached |
| 403 | BLOCKED | Either user has blocked the other |

---

### 5.2 Get received interests

```http
GET /interests/received?limit=50&cursor=...
```

**Success** `200 OK`

```json
{
  "interests": [ { /* Interest */ }, ... ],
  "nextCursor": "int_abc"
}
```

---

### 5.3 Get sent interests

```http
GET /interests/sent?limit=50&cursor=...
```

Same params and response shape as received.

---

### 5.4 Accept interest

```http
POST /interests/:interestId/accept
```

**Success** `200 OK` – body: updated **Interest** with `status: "accepted"`.

---

### 5.5 Decline interest

```http
POST /interests/:interestId/decline
```

**Success** `200 OK` – body: updated **Interest** with `status: "declined"`.

---

### 5.6 Withdraw interest

```http
DELETE /interests/:interestId
```

**Success** `204 No Content`. Only pending interests can be withdrawn.

---

## 5a. Interactions API (Saathi — Interest & Priority Interest)

Same concepts as §5 but with a dedicated **requests inbox** and **priority interest** (boosted, limited per day). All require auth.

### 5a.1 Express interest

```http
POST /interactions/interest
Content-Type: application/json
```

**Body:** `{ "toUserId": "usr_abc", "source": "recommended" }`

**Success** `201 Created`

- If the other user has already sent you interest → **mutual match** is created; response includes `mutualMatch: true`, `matchId`, `chatThreadId`.
- Otherwise → `status: "pending"`, `mutualMatch: false`.

**Errors:** `SELF_INTERACTION`, `USER_BLOCKED`, `PROFILE_INCOMPLETE`, `ALREADY_SENT`, `DAILY_LIMIT`.

---

### 5a.2 Express priority interest

```http
POST /interactions/priority-interest
Content-Type: application/json
```

**Body:** `{ "toUserId": "usr_abc", "message": "Optional intro.", "source": "recommended" }`

**Success** `201 Created` — includes `priorityRemaining` (daily limit left).

**Errors:** `PRIORITY_LIMIT_REACHED`, `ALREADY_SENT`, etc.

---

### 5a.3 Respond to interest (accept / decline)

```http
PATCH /interactions/:interactionId
Content-Type: application/json
```

**Body:** `{ "action": "accept" }` or `{ "action": "decline", "message": "Optional short message", "reasonId": "optional_canned_id" }`

- For **decline**, optional **message** (max 500 chars) and **reasonId** (e.g. `not_right_match`, `not_ready`, `family_decided`, `other`) are stored and can be used for soft rejection copy.
- Response shape unchanged.

**Success** `200 OK` — on accept: `mutualMatch: true`, `matchId`, `chatThreadId`.

---

### 5a.4 Withdraw pending interest

```http
DELETE /interactions/:interactionId
```

**Success** `200 OK`: `{ "interactionId": "...", "status": "withdrawn" }`. Only sender can withdraw; only when pending.

---

### 5a.5 Get received interests (requests inbox)

```http
GET /interactions/received?status=pending&page=1&limit=20&type=all
```

| Query | Default | Description |
|-------|---------|-------------|
| status | pending | `pending`, `accepted`, `declined`, `all` |
| type | all | `interest`, `priority_interest`, `all` |
| page, limit | 1, 20 | Pagination |

**Success** `200 OK` — `interactions[]` (each has `fromUser` summary, `message`, `seenByRecipient`) and `pagination` (`page`, `limit`, `total`, `hasMore`). Priority interests appear first.

---

### 5a.5a Get received interests count (badge)

```http
GET /interactions/received/count?status=pending
Authorization: Bearer <accessToken>
```

| Query | Default | Description |
|-------|---------|-------------|
| status | pending | `pending`, `accepted`, `declined`, or `all` |

**Success** `200 OK`

```json
{ "count": 5 }
```

---

### 5a.6 Get sent interests

```http
GET /interactions/sent?status=pending&page=1&limit=20&type=all
```

Same query params and response shape; each item has `toUser` instead of `fromUser`.

---

## 6. Shortlist API

All endpoints require auth.

### 6.1 Get shortlist

```http
GET /shortlist?page=1&limit=20&sort=recent
```

| Query | Default | Description |
|-------|---------|-------------|
| sort | recent | `recent` (by sortOrder then createdAt) or `most_interested` (by interest sent date then createdAt) |
| page, limit | 1, 20 | Pagination |

**Success** `200 OK`

```json
{
  "profiles": [
    {
      "shortlistId": "sl_xyz",
      "profile": { /* ProfileSummary */ },
      "note": "Good family background",
      "createdAt": "2026-02-23T10:00:00Z"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 3, "hasMore": false }
}
```

---

### 6.2 Add to shortlist

```http
POST /shortlist
Content-Type: application/json
```

**Body:** `{ "profileId": "usr_abc", "note": "Optional private note" }`

**Success** `201 Created`

```json
{
  "shortlistId": "sl_xyz",
  "profileId": "usr_abc",
  "createdAt": "2026-02-23T10:00:00Z"
}
```

---

### 6.2a Update shortlist entry (note / order)

```http
PATCH /shortlist/:shortlistId
Content-Type: application/json
```

**Body:** `{ "note": "Updated private note", "sortOrder": 1 }` — both optional. Use **sortOrder** for manual reorder (lower = higher in list).

**Success** `200 OK`

```json
{ "shortlistId": "sl_xyz", "note": "Updated note", "sortOrder": 1 }
```

---

### 6.3 Remove from shortlist

```http
DELETE /shortlist/:profileId
```

**Success** `200 OK`: `{ "removed": true }`.

---

### 6.4 Get who shortlisted me

```http
GET /shortlist/received?page=1&limit=20
Authorization: Bearer <accessToken>
```

Returns people who added the current user to their shortlist. Gated by entitlement **canSeeWhoShortlistedYou** (premium or female): when false, returns `profiles[]` with `profileId` and `blurred: true` only; when true, returns full minimal profile.

**Success** `200 OK`

```json
{
  "profiles": [
    { "profileId": "usr_abc", "firstName": "Priya", "name": "Priya S", "age": 27, "imageUrl": "https://...", "blurred": false }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 5, "hasMore": false },
  "count": 5
}
```

---

### 6.4a Get shortlist received count (badge)

```http
GET /shortlist/received/count
Authorization: Bearer <accessToken>
```

**Success** `200 OK`

```json
{ "count": 3 }
```

---

### 6.5 Check if shortlisted

```http
GET /shortlist/:userId/check
```

**Success** `200 OK`: `{ "shortlisted": true }`.

---

## 6a. Visits API

All require auth.

### 6a.1 Record profile visit

```http
POST /visits
Content-Type: application/json
```

**Body:** `{ "profileId": "usr_abc", "source": "recommended", "durationMs": 45000 }`

**Success** `201 Created`: `{ "visitId": "vis_xyz", "profileId": "usr_abc", "visitedAt": "..." }`.

---

### 6a.2 Get my visitors

```http
GET /visits/received?page=1&limit=20
```

**Success** `200 OK`: `visitors[]` (each has `visitor` summary, `visitedAt`, `source`), `pagination`, and `newCount`.

---

### 6a.3 Mark visitors as seen

```http
POST /visits/mark-seen
Content-Type: application/json
```

**Request body:** Optional. Client may send `{}`. Backend must accept no body or `{}` and return 200 (do not return 400/500 for empty body).

**Success** `200 OK`: `{ "markedAt": "..." }`.

---

## 6b. Matches API

All require auth.

### 6b.1 Get mutual matches

```http
GET /matches?page=1&limit=20
```

A **mutual match** is when **both users have expressed interest (or priority interest) in each other** — in either order. Return only such pairs. See [BACKEND_MATCHES_AND_VISITORS.md](./BACKEND_MATCHES_AND_VISITORS.md).

**Success** `200 OK`: `matches[]` (each has `matchId`, `matchedAt`, `profile`, `chatThreadId`, `lastMessage`) and `pagination`.

---

### 6b.2 Unmatch

```http
DELETE /matches/:matchId
```

**Success** `200 OK`: `{ "deleted": true }`.

---

## 6c. Profile privacy & notifications

### 6c.1 Privacy

```http
PATCH /profile/me/privacy
Content-Type: application/json
```

**Body:** `{ "showInVisitors": false, "profileVisibility": "everyone" | "only_matches" | "only_after_interest", "hideFromDiscovery": false }`. All fields optional.

**Success** `200 OK`: returns the updated privacy flags. See [BACKEND_CROSS_CUTTING.md §2.2](BACKEND_CROSS_CUTTING.md#22-privacy-controls).

---

### 6c.2 Notification preferences

```http
GET /profile/me/notifications
```
**Success** `200 OK`: returns current notification flags (same shape as PATCH body). Optional; if 404, app uses defaults.

```http
PATCH /profile/me/notifications
Content-Type: application/json
```

**Body:** e.g. `{ "interestReceived": true, "priorityInterestReceived": true, "interestAccepted": true, "interestDeclined": false, "mutualMatch": true, "profileVisited": true, "newMessage": true }`.

**Success** `200 OK`: returns the updated notification flags.

---

## 6d. Contact requests API

All require auth. Used for **Request contact** on profile and **View contacts** (Call/WhatsApp) when accepted. Recipients see requests in "Contact requests" and can **Accept** or **Decline**; backend should **notify the requester** on accept/decline. Full contract: [BACKEND_CONTACT_REQUESTS.md](./BACKEND_CONTACT_REQUESTS.md).

| Method | Path | Description |
|--------|------|-------------|
| GET | /contact-requests/status/:profileId | Status of my request toward that profile (none \| pending \| accepted \| declined); when accepted, includes sharedPhone for Call/WhatsApp. |
| POST | /contact-requests | Send contact request (body: toUserId). |
| GET | /contact-requests/received | Received contact requests (query: page, limit). |
| POST | /contact-requests/:requestId/accept | Accept; share my contact with requester; notify requester. |
| POST | /contact-requests/:requestId/decline | Decline; notify requester. |

---

## 6e. Account (export, deactivate, delete)

See [BACKEND_CROSS_CUTTING.md §5.3](BACKEND_CROSS_CUTTING.md#53-account-and-data).

| Method | Path | Description |
|--------|------|-------------|
| POST | /account/export | Request a copy of user data; returns requestId, status, message (e.g. "We'll email you when ready"). |
| POST | /account/deactivate | Deactivate account (reversible). Body optional: `{ "reason": "..." }`. |
| POST | /account/delete | Permanently delete account. Body optional: `{ "reason": "..." }`. 403 if e.g. active subscription. |

---

## 7. Chat API

All endpoints require auth. **Dating** and **matrimony** chats are **separate**: every thread has a `mode` (`dating` or `matrimony`). The frontend always passes `mode` when listing and creating threads.

See **[BACKEND_CHAT_INTEGRATION.md](./BACKEND_CHAT_INTEGRATION.md)** for app integration details.

### 7.1 List threads

```http
GET /chat/threads?limit=50&mode=dating&cursor=thread_xyz
```

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| limit | number | No | Max threads (default 50). |
| cursor | string | No | Pagination cursor for next page. |
| **mode** | string | **Yes** | `"dating"` or `"matrimony"`. |

**Success** `200 OK`

```json
{
  "threads": [
    {
      "id": "thread_abc",
      "otherUserId": "usr_def",
      "otherName": "Priya Sharma",
      "lastMessage": "Hi! How are you?",
      "lastMessageAt": "2025-03-01T14:30:00Z",
      "unreadCount": 2,
      "mode": "dating"
    }
  ],
  "nextCursor": null
}
```

---

### 7.2 Get or create thread

```http
POST /chat/threads
Content-Type: application/json
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| otherUserId | string | Yes | The other participant. |
| **mode** | string | **Yes** | `"dating"` or `"matrimony"`. |

**Success** `200 OK` (existing) or `201 Created` (new)

```json
{
  "id": "thread_abc",
  "threadId": "thread_abc"
}
```

**Errors**

| HTTP | code | When |
|------|------|------|
| 400 | VALIDATION_ERROR | Missing otherUserId or mode. |
| 403 | CONNECTION_REQUIRED | No interest or match; send or accept an interest first. |
| 404 | NOT_FOUND | otherUserId invalid or no profile. |

---

### 7.3 Get messages

```http
GET /chat/threads/:threadId/messages?limit=50&cursor=msg_xyz
```

**Success** `200 OK`

```json
{
  "messages": [
    {
      "id": "msg_001",
      "senderId": "usr_abc",
      "text": "Hello!",
      "sentAt": "2025-03-01T14:30:00Z",
      "isVoiceNote": false
    }
  ],
  "nextCursor": null
}
```

---

### 7.4 Send message

```http
POST /chat/threads/:threadId/messages
Content-Type: application/json
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| text | string | Yes | Message content. |

**Success** `201 Created` – body: single **ChatMessage**.

**Errors**

| HTTP | code | When |
|------|------|------|
| 403 | INTRO_LIMIT | Free user already sent one intro and not matched. |
| 404 | NOT_FOUND | threadId invalid. |

---

### 7.5 Mark thread read

```http
POST /chat/threads/:threadId/read
```

**Success** `200 OK`

```json
{
  "markedAt": "2025-03-01T14:35:00Z"
}
```

Next **GET /chat/threads** must return that thread with **`unreadCount: 0`**.

---

## 8. Subscription & Entitlements API

All endpoints require auth.

### 8.1 Get subscription state

```http
GET /subscription/me
```

**Success** `200 OK`

```json
{
  "tier": "none",
  "expiresAt": null,
  "isActive": false
}
```

---

### 8.2 Purchase

```http
POST /subscription/purchase
Content-Type: application/json
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| platform | string | Yes | `"ios"`, `"android"`, `"stripe"` |
| receiptOrToken | string | Yes | IAP receipt or Stripe token |
| planId | string | Yes | E.g. `"premium_monthly"` |

**Success** `200 OK` – body: updated **SubscriptionState**.

**Errors**

| HTTP | code | When |
|------|------|------|
| 400 | INVALID_RECEIPT | Receipt validation failed |
| 409 | ALREADY_ACTIVE | User already has an active subscription |

---

### 8.3 Restore purchases

```http
POST /subscription/restore
Content-Type: application/json
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| platform | string | Yes | `"ios"` or `"android"` |
| receiptOrToken | string | Yes | IAP receipt |

**Success** `200 OK` – body: **SubscriptionState**.

---

### 8.4 Get entitlements

```http
GET /subscription/entitlements
```

**Success** `200 OK`

```json
{
  "tier": "none",
  "gender": "male",
  "canExpressInterest": true,
  "canShortlist": true,
  "canViewFullProfile": true,
  "canSendMessage": false,
  "canSeeWhoLikedYou": false,
  "canRequestContact": false,
  "canViewAllPhotos": false,
  "canSeeCompatBreakdown": false,
  "canUseTravelMode": false,
  "canBoostProfile": false,
  "hasPriorityDiscovery": false,
  "hasReadReceipts": false,
  "dailyInterestLimit": 10,
  "dailyMessageLimit": 0
}
```

---

## Entitlements matrix

| Feature | Free Male | Free Female | Premium (any) |
|--------|-----------|-------------|----------------|
| Express Interest | 10/day | 30/day | Unlimited |
| Shortlist | Yes | Yes | Yes |
| View Full Profiles | Yes | Yes | Yes |
| Send Messages | **No** | 20/day | Unlimited |
| See Who Liked You | **No** | Yes | Yes |
| Request Contact | **No** | Yes | Yes |
| View All Photos | **No** | Yes | Yes |
| Compatibility Breakdown | **No** | Yes | Yes |
| Travel Mode | No | No | Yes |
| Profile Boost | No | No | Yes |
| Priority Discovery | No | No | Yes |
| Read Receipts | No | No | Yes |

When a gated action is attempted: **403** with `PREMIUM_REQUIRED` or `DAILY_LIMIT`.

---

## 9. DTOs (Data transfer objects)

### 9.1 UserProfile

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | Yes | Same as auth userId |
| name | string | Yes | Full name |
| gender | string? | No | e.g. "Man", "Woman", "Non-binary" |
| age | number? | No | |
| dateOfBirth | string? | No | ISO 8601 date |
| currentCity | string? | No | |
| currentCountry | string? | No | |
| originCity | string? | No | Hometown |
| originCountry | string? | No | |
| languagesSpoken | string[] | No | Default [] |
| motherTongue | string? | No | |
| photoUrls | string[] | No | Default [] |
| aboutMe | string | No | Default "" |
| interests | string[] | No | Default [] |
| verificationStatus | object? | No | See VerificationStatus |
| profileCompleteness | number | No | 0.0–1.0 |
| isVerified | boolean | No | true if score ≥ threshold |
| privacySettings | object? | No | key → boolean |
| datingExtensions | object? | No | See DatingExtensions |
| matrimonyExtensions | object? | No | See MatrimonyExtensions |
| partnerPreferences | object? | No | See PartnerPreferences |
| lastActiveAt | string? | No | ISO 8601 datetime |
| creationLat | number? | No | |
| creationLng | number? | No | |
| creationAt | string? | No | ISO 8601 datetime |
| creationAddress | string? | No | |

### 9.2 VerificationStatus

| Field | Type | Description |
|-------|------|-------------|
| photoVerified | boolean | Default false |
| idVerified | boolean | Default false |
| emailVerified | boolean | Default false |
| phoneVerified | boolean | Default false |
| linkedInVerified | boolean | Default false |
| educationVerified | boolean | Default false |
| score | number | 0.0–1.0 |

### 9.3 DatingExtensions

| Field | Type | Description |
|-------|------|-------------|
| datingIntent | string? | "serious", "casual", "marriage", "friends first" |
| prompts | PromptAnswer[] | |
| voiceIntroUrl | string? | |
| travelModeEnabled | boolean | Default false |
| discoveryPreferences | object? | ageMin, ageMax, maxDistanceKm, preferredCities, travelModeEnabled |

### 9.4 MatrimonyExtensions

| Field | Type | Description |
|-------|------|-------------|
| roleManagingProfile | string? | "self", "parent", "guardian", "sibling", "friend" |
| religion | string? | |
| casteOrCommunity | string? | |
| motherTongue | string? | |
| maritalStatus | string? | |
| heightCm | number? | |
| bodyType | string? | e.g. "Slim", "Athletic", "Average", "Heavy", "Curvy" |
| complexion | string? | e.g. "Fair", "Wheatish", "Dark", "Prefer not to say" |
| educationDegree | string? | |
| educationInstitution | string? | |
| occupation | string? | |
| employer | string? | |
| industry | string? | |
| incomeRange | object? | minLabel, maxLabel, currency |
| familyDetails | object? | familyType, familyValues, fatherOccupation, motherOccupation, siblingsCount, siblingsMarried, familyExpectations? |
| diet | string? | |
| drinking | string? | |
| smoking | string? | |
| horoscope | object? | dateOfBirth, timeOfBirth, birthPlace, manglik, nakshatra, horoscopeDocUrl |

### 9.5 PartnerPreferences

| Field | Type | Description |
|-------|------|-------------|
| ageMin | number | Default 21 |
| ageMax | number | Default 45 |
| heightMinCm | number? | |
| heightMaxCm | number? | |
| preferredLocations | string[] | |
| preferredReligions | string[] | |
| preferredCommunities | string[] | |
| educationPreference | string? | |
| occupationPreference | string? | |
| maritalStatusPreference | string[] | |
| dietPreference | string? | |
| horoscopeMatchPreferred | boolean? | |

### 9.6 ProfileSummary

Used in discovery (recommended, search, nearby), profile summary, shortlist, visitors, and matches.

| Field | Type | Description |
|-------|------|-------------|
| id | string | User id |
| name | string | |
| age | number? | Computed from dateOfBirth when set |
| city | string? | |
| imageUrl | string? | Primary photo URL |
| distanceKm | number? | |
| verified | boolean | Default false |
| matchReason | string? | Single reason (legacy) |
| **matchReasons** | string[] | **1–3 "Why recommended" reasons** |
| bio | string | Default "" |
| promptAnswer | string? | |
| interests | string[] | Default [] |
| sharedInterests | string[] | Interests shared with current viewer |
| motherTongue | string? | |
| occupation | string? | |
| heightCm | number? | |
| religion | string? | |
| community | string? | |
| educationDegree | string? | |
| maritalStatus | string? | |
| diet | string? | |
| incomeLabel | string? | |
| employer | string? | |
| familyType | string? | |
| photoCount | number | Default 0 |
| compatibilityScore | number? | |
| compatibilityLabel | string? | |
| breakdown | object? | Per-dimension scores |

### 9.7 Interest

| Field | Type | Description |
|-------|------|-------------|
| id | string | Interest id |
| fromUserId | string | Sender |
| toUserId | string | Recipient |
| sentAt | string | ISO 8601 datetime |
| status | string | "pending", "accepted", "rejected", "withdrawn" |

### 9.8 ChatThreadSummary

| Field | Type | Description |
|-------|------|-------------|
| id | string | Thread id |
| otherUserId | string | Other participant |
| otherName | string | |
| lastMessage | string? | |
| lastMessageAt | string? | ISO 8601 datetime |
| unreadCount | number | Default 0 |
| mode | string | "dating" or "matrimony" |

### 9.9 ChatMessage

| Field | Type | Description |
|-------|------|-------------|
| id | string | Message id |
| senderId | string | Author user id |
| text | string | Content |
| sentAt | string | ISO 8601 datetime |
| isVoiceNote | boolean | Default false |

---

## Quick reference: endpoints

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| POST | /auth/send-otp | No | Send OTP |
| POST | /auth/verify-otp | No | Verify OTP, get tokens |
| POST | /auth/refresh | No | Refresh access token |
| POST | /auth/sign-out | Yes | Sign out |
| POST | /auth/google | No | Google sign-in (501) |
| POST | /auth/apple | No | Apple sign-in (501) |
| GET | /profile/me | Yes | Get my profile |
| PATCH | /profile/me | Yes | Update my profile |
| PUT | /profile/me | Yes | Replace my profile |
| GET | /profile/me/preferences | Yes | Get preferences |
| PUT | /profile/me/preferences | Yes | Update preferences |
| GET | /profile/:userId | Yes | Get profile by id |
| GET | /profile/:userId/summary | Yes | Get summary by id |
| POST | /profile/me/photos/upload-url | Yes | Get S3 presigned upload URL(s) |
| POST | /profile/me/photos | Yes | Add photo after upload (body: key) |
| DELETE | /profile/me/photos/:key | Yes | Delete photo by key |
| POST | /security/location | Yes | Record location (security pattern) |
| POST | /safety/block | Yes | Block user |
| POST | /safety/report | Yes | Report user |
| GET | /safety/blocked | Yes | List blocked users |
| DELETE | /safety/blocked/:userId | Yes | Unblock user |
| GET | /discovery/recommended | Yes | Recommended profiles (optional city for travel mode) |
| GET | /discovery/explore | Yes | Filtered feed; strict prefs enforced |
| GET | /discovery/filter-options | Yes | Filter options (preferred shape + defaults/options) |
| GET | /discovery/compatibility/:candidateId | Yes | Compatibility detail |
| GET | /discovery/saved-searches | Yes | List saved searches (with newMatchCount) |
| POST | /discovery/saved-searches | Yes | Create saved search (body: name?, filters, notifyOnNewMatch?) |
| PATCH | /discovery/saved-searches/:id | Yes | Update name / notifyOnNewMatch |
| DELETE | /discovery/saved-searches/:id | Yes | Delete saved search |
| POST | /discovery/saved-searches/:id/viewed | Yes | Mark viewed (reset new-match badge) |
| GET | /discovery/search | Yes | Search profiles |
| GET | /discovery/nearby | Yes | Nearby profiles |
| POST | /interests | Yes | Send interest |
| GET | /interests/received | Yes | Received interests |
| GET | /interests/sent | Yes | Sent interests |
| POST | /interests/:interestId/accept | Yes | Accept interest |
| POST | /interests/:interestId/decline | Yes | Decline interest |
| DELETE | /interests/:interestId | Yes | Withdraw interest |
| POST | /interactions/interest | Yes | Express interest (Saathi) |
| POST | /interactions/priority-interest | Yes | Priority interest |
| PATCH | /interactions/:interactionId | Yes | Accept or decline (body: action; decline: optional message, reasonId) |
| DELETE | /interactions/:interactionId | Yes | Withdraw pending interest |
| GET | /interactions/received | Yes | Requests inbox |
| GET | /interactions/received/count | Yes | Pending received count (badge) |
| GET | /interactions/sent | Yes | Sent interests |
| GET | /shortlist | Yes | Get shortlist (query: sort=recent\|most_interested, page, limit) |
| PATCH | /shortlist/:shortlistId | Yes | Update note and/or sortOrder |
| GET | /shortlist/received | Yes | Who shortlisted me (Shortlisted you tab) |
| GET | /shortlist/received/count | Yes | Shortlist received count (badge) |
| POST | /shortlist | Yes | Add to shortlist |
| DELETE | /shortlist/:profileId | Yes | Remove from shortlist |
| GET | /shortlist/:userId/check | Yes | Check if shortlisted |
| GET | /contact-requests/status/:profileId | Yes | Contact request status (sharedPhone when accepted) |
| POST | /contact-requests | Yes | Send contact request (body: toUserId) |
| GET | /contact-requests/received | Yes | Received contact requests (query: page, limit) |
| POST | /contact-requests/:requestId/accept | Yes | Accept contact request; notify requester |
| POST | /contact-requests/:requestId/decline | Yes | Decline contact request; notify requester |
| GET | /profile/me/notifications | Yes | Get notification preferences (optional; 404 → app defaults) |
| POST | /account/export | Yes | Request data export (see BACKEND_CROSS_CUTTING) |
| POST | /account/deactivate | Yes | Deactivate account (reversible) |
| POST | /account/delete | Yes | Permanently delete account |
| POST | /visits | Yes | Record profile visit |
| GET | /visits/received | Yes | My visitors |
| POST | /visits/mark-seen | Yes | Mark visitors as seen |
| GET | /matches | Yes | Mutual matches |
| DELETE | /matches/:matchId | Yes | Unmatch |
| PATCH | /profile/me/privacy | Yes | Privacy (showInVisitors) |
| PATCH | /profile/me/notifications | Yes | Notification preferences |
| POST | /chat/threads | Yes | Get or create thread (body: otherUserId, mode) |
| GET | /chat/threads | Yes | List threads (query: mode required) |
| GET | /chat/threads/:threadId/messages | Yes | Get messages |
| POST | /chat/threads/:threadId/messages | Yes | Send message |
| POST | /chat/threads/:threadId/read | Yes | Mark read |
| GET | /subscription/me | Yes | Get subscription |
| POST | /subscription/purchase | Yes | Purchase |
| POST | /subscription/restore | Yes | Restore purchases |
| GET | /subscription/entitlements | Yes | Get entitlements |

---

**Related docs**

- [BACKEND_PROFILE_SECTIONS.md](./BACKEND_PROFILE_SECTIONS.md) — Profile sections (app edit flow: section → fields, save & close, GET/PATCH usage)
- [BACKEND_DISCOVERY_INTEGRATION.md](./BACKEND_DISCOVERY_INTEGRATION.md) — Discovery frontend contract (filters, travel, match reasons)
- [BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md](./BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md) — Filter options & strict preferences
- [BACKEND_SECURITY_BLOCK_REPORT.md](./BACKEND_SECURITY_BLOCK_REPORT.md) — Block/report API
- [BACKEND_CHAT_INTEGRATION.md](./BACKEND_CHAT_INTEGRATION.md) — Chat integration checklist
- [BACKEND_MATCHES_AND_VISITORS.md](./BACKEND_MATCHES_AND_VISITORS.md) — Mutual match definition, GET /matches, POST /visits/mark-seen
- [BACKEND_REQUESTS_SHORTLIST_FAMILY.md](./BACKEND_REQUESTS_SHORTLIST_FAMILY.md) — Requests (decline message), contact gating, shortlist (notes, sort), family, horoscope, parent role
- [BACKEND_SAVED_SEARCHES.md](./BACKEND_SAVED_SEARCHES.md) — Saved searches and new-match notifications (matrimony)
- [BACKEND_CONTACT_REQUESTS.md](./BACKEND_CONTACT_REQUESTS.md) — Contact request flow, accept/decline, notifications, View contacts (Call/WhatsApp)
- [BACKEND_CROSS_CUTTING.md](./BACKEND_CROSS_CUTTING.md) — Notifications, privacy, account (export/deactivate/delete), profile boost, referral, deep links
- [BACKEND_VERIFICATION.md](./BACKEND_VERIFICATION.md) — Verification screen: ID, face, LinkedIn, education; verificationStatus and safety score; optional upload/OAuth endpoints
