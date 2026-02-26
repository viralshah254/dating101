# Saathi Backend API Reference

Complete API documentation for the Saathi dating/matrimony backend.

**→ For a full checklist of APIs to build, see [BACKEND_API_REQUIREMENTS.md](./BACKEND_API_REQUIREMENTS.md).**

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

Send only the fields that changed; backend **deep-merges** nested objects (`matrimonyExtensions`, `familyDetails`, `horoscope`, `partnerPreferences`).

- Sending `null` for a field clears it.
- `profileCompleteness` is recomputed after every update.

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

**Success** `200 OK` – body: **UserProfile**. Sensitive fields may be masked for non-self viewers.

**Errors**

| HTTP | code | When |
|------|------|------|
| 404 | NOT_FOUND | Invalid userId or no profile |

---

### 2.7 Get profile summary by id

```http
GET /profile/:userId/summary
```

**Success** `200 OK` – body: **ProfileSummary** (see [§9.6](#96-profilesummary)).

**Errors**

| HTTP | code | When |
|------|------|------|
| 404 | NOT_FOUND | Invalid userId or no profile |

---

### 2.8 Get presigned upload URL (photos)

```http
POST /profile/me/photos/upload-url
Authorization: Bearer <accessToken>
Content-Type: application/json
```

The app calls this before uploading each photo. The backend generates an S3 presigned PUT URL that the app uploads to directly.

**Request body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| contentType | string | Yes | MIME type, e.g. `"image/jpeg"`, `"image/png"` |
| count | number | No | Number of URLs to generate (default 1, max 6) |

**Example request**

```json
{
  "contentType": "image/jpeg",
  "count": 3
}
```

**Success** `200 OK`

```json
{
  "uploads": [
    {
      "uploadUrl": "https://saathi-photos.s3.amazonaws.com/usr_abc/photo_1.jpg?X-Amz-...",
      "photoUrl": "https://cdn.saathi.app/photos/usr_abc/photo_1.jpg",
      "key": "usr_abc/photo_1.jpg"
    },
    {
      "uploadUrl": "https://saathi-photos.s3.amazonaws.com/usr_abc/photo_2.jpg?X-Amz-...",
      "photoUrl": "https://cdn.saathi.app/photos/usr_abc/photo_2.jpg",
      "key": "usr_abc/photo_2.jpg"
    },
    {
      "uploadUrl": "https://saathi-photos.s3.amazonaws.com/usr_abc/photo_3.jpg?X-Amz-...",
      "photoUrl": "https://cdn.saathi.app/photos/usr_abc/photo_3.jpg",
      "key": "usr_abc/photo_3.jpg"
    }
  ]
}
```

| Field | Description |
|-------|-------------|
| uploadUrl | Presigned S3 PUT URL — app uploads the image bytes here with `PUT` |
| photoUrl | CDN URL the app stores in `photoUrls` after upload succeeds |
| key | S3 object key (for delete) |

The presigned URL expires in **15 minutes**. The app should:
1. Call this endpoint to get presigned URLs
2. `PUT` the image bytes to each `uploadUrl` with `Content-Type: image/jpeg`
3. After all uploads succeed, `PATCH /profile/me` with the `photoUrls` array containing the `photoUrl` values

**Errors**

| HTTP | code | When |
|------|------|------|
| 400 | VALIDATION_ERROR | Invalid content type or count |
| 429 | RATE_LIMITED | Too many upload requests |
| 500 | INTERNAL_ERROR | Often **"Could not load credentials from any providers"** — see below. |

**Backend configuration (required for photo upload)**

To generate presigned S3 URLs, the backend must have **AWS credentials** available. If they are missing, the endpoint returns **500** with `INTERNAL_ERROR` and message *"Could not load credentials from any providers"*.

- **Local development:** Set environment variables before starting the server:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION` (e.g. `us-east-1`)
  - `S3_BUCKET` (or your app’s bucket env name)
- **Hosted (e.g. EC2/ECS/Lambda):** Use an IAM role with `s3:PutObject` (and optionally `s3:DeleteObject`) on the bucket, or set the same env vars.
- Ensure the bucket exists and the credentials have permission to create presigned URLs for that bucket.

---

### 2.9 Delete photo

```http
DELETE /profile/me/photos/:key
Authorization: Bearer <accessToken>
```

Deletes a photo from S3 and removes it from the user's `photoUrls` array.

**Example:** `DELETE /profile/me/photos/usr_abc%2Fphoto_1.jpg` (URL-encode the key)

**Success** `200 OK`

```json
{
  "photoUrls": ["https://cdn.saathi.app/photos/usr_abc/photo_2.jpg"]
}
```

Returns the updated `photoUrls` array.

**Errors**

| HTTP | code | When |
|------|------|------|
| 404 | NOT_FOUND | Photo key not found |

---

## 3. Security & location API

Location data is stored for **security and pattern analysis** (e.g. to detect unusual login locations). All endpoints require auth.

### 3.1 Location at sign-up

When the user completes profile setup, the app sends **creationLat**, **creationLng**, **creationAt**, and **creationAddress** in `PATCH /profile/me`. The backend persists these on **UserProfile**; no separate endpoint is required for sign-up location.

### 3.2 Record location (periodic check-in)

The app should call this endpoint when it has the user's location—for example **once per day** or on app open—so the backend can build a location pattern for security.

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

---

## 4. Discovery API

All discovery endpoints require auth. The recommendation engine uses ML-powered
compatibility scoring — see **[MATCHING_AND_COMPATIBILITY.md](./MATCHING_AND_COMPATIBILITY.md)**
for the full pipeline spec.

For **Explore tab filters** (age, city, religion, education, etc.) and **strict preferences** (options must respect the user’s profile), see **[BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md](./BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md)**. The backend should expose `GET /discovery/filter-options` and return only allowed options when the user has strict preferences.

### 4.1 Recommended profiles

```http
GET /discovery/recommended?mode=dating&limit=20&cursor=usr_xyz
```

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| mode | string | Yes | `"dating"` or `"matrimony"` |
| limit | number | No | Default 20, max 50 |
| cursor | string | No | Pagination cursor (last profile ID) |

Response includes ML compatibility scores, match reasons, and per-category
breakdowns. See [MATCHING_AND_COMPATIBILITY.md §8.1](./MATCHING_AND_COMPATIBILITY.md#81-get-recommended-profiles-enhanced)
for the full response schema.

**Success** `200 OK`

```json
{
  "profiles": [
    {
      "id": "usr_abc",
      "name": "Priya S.",
      "age": 27,
      "city": "Mumbai",
      "imageUrl": "https://cdn.saathi.app/photos/usr_abc/photo_1.jpg",
      "verified": true,
      "compatibilityScore": 0.87,
      "compatibilityLabel": "Excellent match",
      "matchReasons": ["Lives in Mumbai", "Same religion", "Shares 3 interests"],
      "breakdown": { "basics": 0.92, "culture": 0.88, "lifestyle": 0.80 }
    }
  ],
  "nextCursor": "usr_def456"
}
```

---

### 4.2 Get compatibility with specific profile

```http
GET /discovery/compatibility/:candidateId
Authorization: Bearer <accessToken>
```

Returns full compatibility breakdown for a specific profile. See
[MATCHING_AND_COMPATIBILITY.md §8.2](./MATCHING_AND_COMPATIBILITY.md#82-get-compatibility-with-specific-profile).

---

### 4.3 Report match feedback

```http
POST /discovery/feedback
Authorization: Bearer <accessToken>
Content-Type: application/json
```

```json
{
  "candidateId": "usr_abc",
  "action": "like",
  "timeSpentMs": 4200,
  "source": "recommended"
}
```

Records interaction for ML training. See
[MATCHING_AND_COMPATIBILITY.md §8.3](./MATCHING_AND_COMPATIBILITY.md#83-report-match-feedback).

---

### 4.5 Search profiles

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

**Success** `200 OK` – same shape as recommended (includes compatibility scores).

---

### 4.6 Nearby profiles

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

**Success** `200 OK` – body: updated **Interest** with `status: "rejected"`.

---

### 5.6 Withdraw interest

```http
DELETE /interests/:interestId
```

**Success** `204 No Content`. Only pending interests can be withdrawn.

---

## 6. Shortlist API

All endpoints require auth.

### 6.1 Get shortlist

```http
GET /shortlist?limit=100&cursor=...
```

**Success** `200 OK`

```json
{
  "profiles": [ { /* ProfileSummary */ }, ... ],
  "nextCursor": null
}
```

---

### 6.2 Add to shortlist

```http
POST /shortlist/:userId
```

**Success** `201 Created`

```json
{
  "userId": "usr_def"
}
```

---

### 6.3 Remove from shortlist

```http
DELETE /shortlist/:userId
```

**Success** `204 No Content`.

---

### 6.4 Check if shortlisted

```http
GET /shortlist/:userId/check
```

**Success** `200 OK`

```json
{
  "shortlisted": true
}
```

---

## 7. Chat API

All endpoints require auth. Messaging is gated by entitlements (§8).

### 7.1 Get or create thread

```http
POST /chat/threads
Content-Type: application/json
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| otherUserId | string | Yes | The other participant |

**Success** `201 Created`

```json
{
  "id": "thread_abc"
}
```

Use this `id` for getting/sending messages.

---

### 7.2 Get threads

```http
GET /chat/threads?limit=50
```

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
      "unreadCount": 2
    }
  ]
}
```

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

`cursor` is for loading older messages.

---

### 7.4 Send message

```http
POST /chat/threads/:threadId/messages
Content-Type: application/json
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| text | string | Yes | Message content |

**Success** `201 Created` – body: **ChatMessage**.

**Errors**

| HTTP | code | When |
|------|------|------|
| 403 | PREMIUM_REQUIRED | Free male user; messaging requires premium |
| 403 | DAILY_LIMIT | Free female user daily message limit reached |

---

### 7.5 Mark thread read

```http
POST /chat/threads/:threadId/read
```

**Success** `200 OK`.

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

| Field | Type | Description |
|-------|------|-------------|
| tier | string | `"none"` or `"premium"` |
| expiresAt | string \| null | ISO 8601; null if no subscription |
| isActive | boolean | Whether subscription is active now |

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

**Success** `200 OK` – body: **SubscriptionState**. If nothing found: `{ "tier": "none", "isActive": false }`.

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

Computed from user gender and subscription tier. See [Entitlements matrix](#entitlements-matrix) below.

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
| gender | string? | No | `"Man"`, `"Woman"`, `"Non-binary"` |
| age | number? | No | Computed from dateOfBirth |
| dateOfBirth | string? | No | ISO 8601 date (`YYYY-MM-DD`) |
| currentCity | string? | No | Where user lives now |
| currentCountry | string? | No | |
| originCity | string? | No | Hometown city |
| originCountry | string? | No | Hometown country |
| languagesSpoken | string[] | No | Default `[]` |
| motherTongue | string? | No | |
| photoUrls | string[] | No | Default `[]` |
| aboutMe | string | No | Default `""` |
| interests | string[] | No | Default `[]` |
| verificationStatus | object? | No | See [§9.2 VerificationStatus](#92-verificationstatus) |
| profileCompleteness | number | No | 0.0–1.0, backend-computed |
| isVerified | boolean | No | `true` if score ≥ threshold |
| privacySettings | object? | No | key → boolean |
| datingExtensions | object? | No | See [§9.3 DatingExtensions](#93-datingextensions) |
| matrimonyExtensions | object? | No | See [§9.4 MatrimonyExtensions](#94-matrimonyextensions) |
| partnerPreferences | object? | No | See [§9.5 PartnerPreferences](#95-partnerpreferences) |
| lastActiveAt | string? | No | ISO 8601 datetime |
| creationLat | number? | No | Latitude at profile creation |
| creationLng | number? | No | Longitude at profile creation |
| creationAt | string? | No | ISO 8601 datetime |
| creationAddress | string? | No | Reverse-geocoded address |

---

### 9.2 VerificationStatus

| Field | Type | Description |
|-------|------|-------------|
| photoVerified | boolean | Default `false` |
| idVerified | boolean | Default `false` |
| emailVerified | boolean | Default `false` |
| phoneVerified | boolean | Default `false` |
| linkedInVerified | boolean | Default `false` |
| educationVerified | boolean | Default `false` |
| score | number | 0.0–1.0 |

---

### 9.3 DatingExtensions

| Field | Type | Description |
|-------|------|-------------|
| datingIntent | string? | `"serious"`, `"casual"`, `"marriage"`, `"friends first"` |
| prompts | PromptAnswer[]? | Array of `{ questionId, questionText, answer }` |
| voiceIntroUrl | string? | |
| travelModeEnabled | boolean | Default `false` |
| discoveryPreferences | object? | `{ ageMin, ageMax, maxDistanceKm, preferredCities, travelModeEnabled }` |

---

### 9.4 MatrimonyExtensions

All fields are optional. Stored as `matrimonyExtensions` on the profile.

#### Core identity & physical

| Field | Type | Description |
|-------|------|-------------|
| roleManagingProfile | string? | `"self"`, `"parent"`, `"guardian"`, `"sibling"`, `"friend"` |
| religion | string? | e.g. `"Hindu"`, `"Muslim"`, `"Christian"` |
| casteOrCommunity | string? | e.g. `"Brahmin"`, `"Rajput"` |
| motherTongue | string? | e.g. `"Hindi"`, `"Tamil"` |
| maritalStatus | string? | `"Never married"`, `"Divorced"`, `"Widowed"`, `"Awaiting Divorce"` |
| heightCm | number? | Height in centimeters |
| bodyType | string? | `"Slim"`, `"Athletic"`, `"Average"`, `"Heavy"` |
| complexion | string? | `"Fair"`, `"Wheatish"`, `"Dark"`, `"Very fair"` |
| disability | string? | `"None"`, `"Physical"`, `"Visual"`, `"Hearing"`, `"Other"` |

#### Education

| Field | Type | Description |
|-------|------|-------------|
| educationDegree | string? | Highest degree, e.g. `"B.Tech"`, `"MBA"` |
| educationInstitution | string? | University/college name |
| educationEntries | object[]? | Multiple degrees — each: `{ degree, institution, graduationYear, scoreCountry, scoreType }` |
| aboutEducation | string? | Free-text about education background |

#### Career

| Field | Type | Description |
|-------|------|-------------|
| occupation | string? | e.g. `"Software Engineer"` |
| employer | string? | Company name |
| industry | string? | Sector, e.g. `"IT"`, `"Finance"` |
| incomeRange | object? | `{ minLabel, maxLabel, currency }` |
| workLocation | string? | City where user works |
| settledAbroad | string? | `"Yes"`, `"No"`, `"Planning to"` |
| willingToRelocate | string? | `"Yes"`, `"No"`, `"Maybe"` |
| aboutCareer | string? | Free-text about career |

#### Lifestyle

| Field | Type | Description |
|-------|------|-------------|
| diet | string? | `"Vegetarian"`, `"Non-vegetarian"`, `"Eggetarian"`, `"Vegan"`, `"Jain"` |
| drinking | string? | `"Non-drinker"`, `"Social"`, `"Regular"` |
| smoking | string? | `"Non-smoker"`, `"Occasional"`, `"Regular"` |
| exercise | string? | `"Daily"`, `"Often"`, `"Sometimes"`, `"Never"` |
| pets | string? | `"Dog"`, `"Cat"`, `"Both"`, `"Other"`, `"None"` |

#### Family details

Stored as `matrimonyExtensions.familyDetails`.

| Field | Type | Description |
|-------|------|-------------|
| familyType | string? | `"Joint"`, `"Nuclear"`, `"Other"` |
| familyValues | string? | `"Traditional"`, `"Moderate"`, `"Liberal"` |
| fatherOccupation | string? | |
| motherOccupation | string? | |
| siblingsCount | number? | Total siblings |
| siblingsMarried | number? | How many married |
| fatherAge | string? | Age or `"Deceased"` |
| motherAge | string? | Age or `"Deceased"` |
| brothers | string? | `"None"`, `"1"`, `"2"`, `"3"`, `"4+"` |
| sisters | string? | `"None"`, `"1"`, `"2"`, `"3"`, `"4+"` |
| familyLocation | string? | City/town where family lives |
| familyBasedOutOfCountry | string? | Country, e.g. `"India"`, `"USA"` |
| householdIncome | string? | e.g. `"10-15 LPA"`, `"$100K-150K"` |

#### Horoscope

Stored as `matrimonyExtensions.horoscope`.

| Field | Type | Description |
|-------|------|-------------|
| dateOfBirth | string? | ISO date (mirrors top-level) |
| timeOfBirth | string? | e.g. `"06:42 AM"` |
| birthPlace | string? | e.g. `"Nairobi, Kenya"` |
| manglik | string? | `"Manglik"`, `"Non-Manglik"`, `"Anshik Manglik"` |
| nakshatra | string? | e.g. `"Rohini"`, `"Ashwini"` |
| horoscopeDocUrl | string? | URL to uploaded kundli document |
| rashi | string? | e.g. `"Vrishabh"`, `"Mesh"`, `"Kanya"` |
| gotra | string? | e.g. `"Bharadwaj"`, `"Kashyap"` |

---

### 9.5 PartnerPreferences

Used for matching in both dating and matrimony modes.

#### Gender preference mapping

The `genderPreference` field stores a **normalized value**. The app displays mode-specific labels:

| Stored value | Matrimony label | Dating label |
|-------------|-----------------|--------------|
| `"Woman"` | Bride | Female |
| `"Man"` | Groom | Male |
| `"Any"` | _(not shown)_ | Everyone |

#### All fields

| Field | Type | Description |
|-------|------|-------------|
| genderPreference | string? | `"Woman"`, `"Man"`, `"Any"` — see mapping above |
| ageMin | number | Default `21` |
| ageMax | number | Default `45` |
| heightMinCm | number? | |
| heightMaxCm | number? | |
| preferredLocations | string[]? | City names |
| preferredReligions | string[]? | |
| preferredCommunities | string[]? | |
| preferredMotherTongues | string[]? | e.g. `["Hindi", "Gujarati"]` |
| educationPreference | string? | |
| occupationPreference | string? | |
| maritalStatusPreference | string[]? | |
| dietPreference | string? | |
| incomePreference | string? | e.g. `"5-10 LPA"` |
| drinkingPreference | string? | `"Non-drinker"`, `"Social"`, `"Doesn't matter"` |
| smokingPreference | string? | `"Non-smoker"`, `"Doesn't matter"` |
| settledAbroadPreference | string? | `"Yes"`, `"No"`, `"Doesn't matter"` |
| preferredCountries | string[]? | e.g. `["India", "USA"]` |
| cityPreferenceMode | string? | `"any"`, `"same_as_me"`, `"preferred"` |
| distanceMaxKm | number? | Max distance for dating mode |
| horoscopeMatchPreferred | boolean? | |
| strictFilters | object? | See strict filters below |

#### Strict filters

Stored as `partnerPreferences.strictFilters`. Each flag means the match engine **must** satisfy that criterion; `false` means soft/optional.

| Field | Type | Description |
|-------|------|-------------|
| religion | boolean | Default `false` |
| motherTongue | boolean | Default `false` |
| education | boolean | Default `false` |
| maritalStatus | boolean | Default `false` |
| income | boolean | Default `false` |
| diet | boolean | Default `false` |
| drinking | boolean | Default `false` |
| smoking | boolean | Default `false` |
| settledAbroad | boolean | Default `false` |

---

### 9.6 ProfileSummary

Lightweight DTO used in discovery cards and lists.

| Field | Type | Description |
|-------|------|-------------|
| id | string | User id |
| name | string | |
| age | number? | |
| city | string? | |
| imageUrl | string? | Primary photo URL |
| distanceKm | number? | |
| verified | boolean | Default `false` |
| matchReason | string? | |
| bio | string | Default `""` |
| promptAnswer | string? | |
| interests | string[] | Default `[]` |
| **sharedInterests** | **string[]** | **Interests this profile has in common with the current viewer. Required in discovery responses (recommended, search, nearby) so the app can highlight them. Case-insensitive match against viewer's interests.** |
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
| photoCount | number | Default `0` |
| compatibilityScore | number? | 0–1 |
| compatibilityLabel | string? | e.g. "Good match" |
| matchReasons | string[] | Default `[]` |
| breakdown | Record<string, number>? | Per-dimension scores 0–1 |

**Discovery responses** (`GET /discovery/recommended`, `GET /discovery/search`, `GET /discovery/nearby`): each profile in the response must include `sharedInterests` — the subset of that profile's `interests` that intersect with the **current authenticated user's** interests. The frontend uses this to visually highlight shared interests (e.g. green chip with heart icon).

---

### 9.7 Interest

| Field | Type | Description |
|-------|------|-------------|
| id | string | Interest id |
| fromUserId | string | Sender |
| toUserId | string | Recipient |
| sentAt | string | ISO 8601 datetime |
| status | string | `"pending"`, `"accepted"`, `"rejected"`, `"withdrawn"` |

---

### 9.8 ChatThreadSummary

| Field | Type | Description |
|-------|------|-------------|
| id | string | Thread id |
| otherUserId | string | Other participant |
| otherName | string | |
| lastMessage | string? | |
| lastMessageAt | string? | ISO 8601 datetime |
| unreadCount | number | Default `0` |

---

### 9.9 ChatMessage

| Field | Type | Description |
|-------|------|-------------|
| id | string | Message id |
| senderId | string | Author user id |
| text | string | Content |
| sentAt | string | ISO 8601 datetime |
| isVoiceNote | boolean | Default `false` |

---

## 10. PATCH examples — profile setup step-by-step

### Step 1: Identity

```json
{
  "name": "Vikram Shah",
  "gender": "Man",
  "dateOfBirth": "1996-01-01",
  "aboutMe": "Software engineer who loves hiking.",
  "currentCity": "Mumbai",
  "currentCountry": "India",
  "originCity": "Ahmedabad",
  "originCountry": "India",
  "motherTongue": "Gujarati",
  "matrimonyExtensions": {
    "maritalStatus": "Never married",
    "heightCm": 175,
    "bodyType": "Athletic",
    "complexion": "Wheatish",
    "disability": "None"
  },
  "partnerPreferences": {
    "genderPreference": "Woman"
  }
}
```

### Step 2: Interests

```json
{
  "interests": ["Fitness", "Cooking", "Travel", "Photography"]
}
```

### Step 3: Photos

```json
{
  "photoUrls": [
    "https://cdn.saathi.app/photos/usr_abc/1.jpg",
    "https://cdn.saathi.app/photos/usr_abc/2.jpg"
  ]
}
```

### Step 4: Education

```json
{
  "matrimonyExtensions": {
    "educationDegree": "B.Tech",
    "educationInstitution": "IIT Bombay",
    "educationEntries": [
      {
        "degree": "B.Tech",
        "institution": "IIT Bombay",
        "graduationYear": 2018,
        "scoreCountry": "India",
        "scoreType": "First class"
      },
      {
        "degree": "MBA",
        "institution": "IIM Ahmedabad",
        "graduationYear": 2020
      }
    ],
    "aboutEducation": "Graduated with honours, specialised in computer science."
  }
}
```

### Step 5: Career

```json
{
  "matrimonyExtensions": {
    "occupation": "Software Engineer",
    "employer": "Google",
    "industry": "IT",
    "incomeRange": { "minLabel": "25-30 LPA", "currency": "INR" },
    "workLocation": "Bangalore",
    "settledAbroad": "No",
    "willingToRelocate": "Maybe",
    "aboutCareer": "Leading a team of 10 engineers building cloud infrastructure."
  }
}
```

### Step 6: Details (family + horoscope + lifestyle)

```json
{
  "matrimonyExtensions": {
    "religion": "Hindu",
    "casteOrCommunity": "Brahmin",
    "diet": "Vegetarian",
    "drinking": "Non-drinker",
    "smoking": "Non-smoker",
    "exercise": "Daily",
    "familyDetails": {
      "familyType": "Joint",
      "familyValues": "Traditional",
      "fatherOccupation": "Business",
      "motherOccupation": "Homemaker",
      "fatherAge": "65",
      "motherAge": "60",
      "brothers": "1",
      "sisters": "2",
      "siblingsCount": 3,
      "familyLocation": "Ahmedabad",
      "familyBasedOutOfCountry": "India",
      "householdIncome": "15-20 LPA"
    },
    "horoscope": {
      "manglik": "Non-Manglik",
      "rashi": "Vrishabh",
      "nakshatra": "Rohini",
      "gotra": "Bharadwaj",
      "timeOfBirth": "06:42 AM",
      "birthPlace": "Ahmedabad, India",
      "dateOfBirth": "1996-01-01"
    }
  }
}
```

### Step 7: Partner preferences

```json
{
  "partnerPreferences": {
    "genderPreference": "Woman",
    "ageMin": 23,
    "ageMax": 30,
    "preferredReligions": ["Hindu"],
    "preferredMotherTongues": ["Gujarati", "Hindi"],
    "educationPreference": "Post-graduate",
    "maritalStatusPreference": ["Never married"],
    "dietPreference": "Vegetarian",
    "incomePreference": "10+ LPA",
    "drinkingPreference": "Non-drinker",
    "smokingPreference": "Non-smoker",
    "settledAbroadPreference": "Doesn't matter",
    "preferredLocations": ["Mumbai", "Ahmedabad"],
    "preferredCountries": ["India"],
    "cityPreferenceMode": "preferred",
    "strictFilters": {
      "religion": true,
      "diet": true,
      "motherTongue": false,
      "education": false,
      "maritalStatus": true,
      "income": false,
      "drinking": false,
      "smoking": false,
      "settledAbroad": false
    }
  }
}
```

### First-time setup complete (with creation location)

```json
{
  "creationLat": -1.255062,
  "creationLng": 36.7470765,
  "creationAt": "2026-02-24T10:42:10.445Z",
  "creationAddress": "Kaumoni Road, Nairobi, Nairobi, Kenya"
}
```

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
| PATCH | /profile/me | Yes | Update my profile (partial, deep-merge) |
| PUT | /profile/me | Yes | Replace my profile |
| GET | /profile/me/preferences | Yes | Get preferences |
| PUT | /profile/me/preferences | Yes | Update preferences |
| GET | /profile/:userId | Yes | Get profile by id |
| GET | /profile/:userId/summary | Yes | Get summary by id |
| POST | /profile/me/photos/upload-url | Yes | Get presigned S3 upload URLs |
| DELETE | /profile/me/photos/:key | Yes | Delete a photo |
| POST | /security/location | Yes | Record location (security pattern) |
| GET | /discovery/recommended | Yes | ML-scored recommended profiles |
| GET | /discovery/filter-options | Yes | Filter options for Explore tab (respects strict preferences) — see [BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md](./BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md) |
| GET | /discovery/compatibility/:id | Yes | Full compatibility breakdown |
| POST | /discovery/feedback | Yes | Record interaction for ML training |
| GET | /discovery/search | Yes | Search profiles |
| GET | /discovery/nearby | Yes | Nearby profiles |
| POST | /interests | Yes | Send interest |
| GET | /interests/received | Yes | Received interests |
| GET | /interests/sent | Yes | Sent interests |
| POST | /interests/:interestId/accept | Yes | Accept interest |
| POST | /interests/:interestId/decline | Yes | Decline interest |
| DELETE | /interests/:interestId | Yes | Withdraw interest |
| GET | /shortlist | Yes | Get shortlist |
| POST | /shortlist/:userId | Yes | Add to shortlist |
| DELETE | /shortlist/:userId | Yes | Remove from shortlist |
| GET | /shortlist/:userId/check | Yes | Check if shortlisted |
| POST | /chat/threads | Yes | Get or create thread |
| GET | /chat/threads | Yes | List threads |
| GET | /chat/threads/:threadId/messages | Yes | Get messages |
| POST | /chat/threads/:threadId/messages | Yes | Send message |
| POST | /chat/threads/:threadId/read | Yes | Mark read |
| GET | /subscription/me | Yes | Get subscription |
| POST | /subscription/purchase | Yes | Purchase |
| POST | /subscription/restore | Yes | Restore purchases |
| GET | /subscription/entitlements | Yes | Get entitlements |
