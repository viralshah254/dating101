# Connect your frontend to the Saathi backend

Use this doc to wire your app (Flutter, React Native, web, etc.) to the Saathi API. All request/response shapes and error codes you need are below.

---

## 1. Base URL and headers

| Item | Value |
|------|--------|
| **Base URL (prod)** | `https://api.saathi.app` |
| **Base URL (local)** | `http://localhost:3000` |
| **Content-Type** | `application/json` for all request/response bodies |
| **Auth** | `Authorization: Bearer <accessToken>` on every request **except** send-otp, verify-otp, refresh |

Use an env variable for the base URL (e.g. `API_BASE_URL`) and switch for local vs prod.

---

## 2. Error format

Every error response has this shape:

```json
{
  "code": "ERROR_CODE",
  "message": "Human-readable message",
  "details": {}
}
```

- **code** — Use for branching (e.g. `PROFILE_NOT_FOUND`, `INTRO_LIMIT`).
- **message** — Show in toasts or error text.
- **details** — Optional; often field errors for `VALIDATION_ERROR`.

**Handle in your client:**

- **401** — Try refresh once, retry request. If refresh returns 401, clear tokens and go to login.
- **404** + `PROFILE_NOT_FOUND` — No profile yet → show profile setup/onboarding.
- **400** + `VALIDATION_ERROR` — Show `details` on the form.
- **403** — Show `message`; use `code` for actions (e.g. `INTRO_LIMIT` → "Match to continue or upgrade", `PREMIUM_REQUIRED` → upgrade prompt, `CONNECTION_REQUIRED` → "Send or accept an interest first").

---

## 3. Auth (phone OTP)

### 3.1 Send OTP

```http
POST /auth/send-otp
Content-Type: application/json
```

**Request**

```json
{
  "countryCode": "+91",
  "phone": "9876543210"
}
```

**Response 200**

```json
{
  "verificationId": "ver_abc123",
  "expiresInSeconds": 300
}
```

Store `verificationId`; show OTP input. **Local dev (mock SMS):** OTP code is always **`1111`**.

---

### 3.2 Verify OTP (login)

```http
POST /auth/verify-otp
Content-Type: application/json
```

**Request**

```json
{
  "verificationId": "ver_abc123",
  "code": "1234"
}
```

**Response 200**

```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "expiresIn": 3600,
  "userId": "usr_abc123",
  "isNewUser": true
}
```

Store `accessToken`, `refreshToken`, `userId` (e.g. secure storage). If `isNewUser === true`, show onboarding; else go to home. Then call `GET /profile/me` — if 404 with `PROFILE_NOT_FOUND`, show profile setup.

---

### 3.3 Refresh token

When any request returns **401**:

```http
POST /auth/refresh
Content-Type: application/json
```

**Request**

```json
{
  "refreshToken": "<stored_refresh_token>"
}
```

**Response 200**

```json
{
  "accessToken": "eyJ...",
  "expiresIn": 3600
}
```

Replace stored access token and retry the original request.

---

### 3.4 Sign out

```http
POST /auth/sign-out
Authorization: Bearer <accessToken>
```

No body. Then clear tokens and `userId` on the client. Optional: `DELETE /profile/me/fcm-token` to remove push token.

---

## 4. After login (recommended)

| Call | Purpose |
|------|---------|
| `GET /profile/me` | Check if profile exists; 404 → onboarding. |
| `GET /subscription/entitlements` | Feature flags (e.g. `canSendMessage`, `dailyInterestLimit`, `canSeeWhoShortlistedYou`). |
| `POST /profile/me/fcm-token` | Register push token: body `{ "fcmToken": "..." }`. |

---

## 5. Profile

| Action | Method | Path | Body / query |
|--------|--------|------|----------------|
| Get my profile | GET | `/profile/me` | — |
| Update my profile | PATCH | `/profile/me` | Partial profile object |
| Get another user's profile | GET | `/profile/:userId` | — |
| Get summary (cards, chat header) | GET | `/profile/:userId/summary` | — |

**GET /profile/:userId/summary** is used for the **chat list and thread header** (name, photo, compatibility). Response includes at least: `id`, `name`, `age`, `city`, `imageUrl` (first photo URL), `verified`, `bio`, `interests`, and optionally `compatibilityScore`, `matchReason`, etc.

---

## 6. Chat

**Rules:** A thread exists only when there's an **interest** (pending or accepted) in either direction or a **mutual match**. Free users can send **one intro message** per thread before matching; after match, both can message without limit.

### 6.1 List threads

```http
GET /chat/threads?mode=dating&limit=50
Authorization: Bearer <accessToken>
```

**Query:** `mode` is **required** (`dating` or `matrimony`). Optional: `limit`, `cursor`.

**Response 200**

```json
{
  "threads": [
    {
      "id": "thread_abc",
      "otherUserId": "usr_def",
      "otherName": "Priya",
      "lastMessage": "Hi!",
      "lastMessageAt": "2025-03-01T14:30:00Z",
      "unreadCount": 2,
      "mode": "dating"
    }
  ],
  "nextCursor": null
}
```

**Important:** Sum `unreadCount` across threads for the Chats tab badge. After the user opens a thread, call **POST .../read** so the next list returns `unreadCount: 0` for that thread.

---

### 6.2 Get or create thread (tap "Message")

```http
POST /chat/threads
Content-Type: application/json
Authorization: Bearer <accessToken>
```

**Request**

```json
{
  "otherUserId": "usr_xyz",
  "mode": "dating"
}
```

**Response 200 (existing)** or **201 (new)**

```json
{
  "id": "thread_abc",
  "threadId": "thread_abc"
}
```

Use `id` (or `threadId`) to open the thread: `GET /chat/threads/:threadId/messages`.

**Errors:** 403 `CONNECTION_REQUIRED` if there's no interest or match — show "Send or accept an interest first".

---

### 6.3 Get messages

```http
GET /chat/threads/:threadId/messages?limit=50
Authorization: Bearer <accessToken>
```

Optional query: `cursor` for older messages.

**Response 200**

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

### 6.4 Send message

```http
POST /chat/threads/:threadId/messages
Content-Type: application/json
Authorization: Bearer <accessToken>
```

**Request**

```json
{
  "text": "Hello!"
}
```

**Response 201**

```json
{
  "id": "msg_001",
  "senderId": "usr_abc",
  "text": "Hello!",
  "sentAt": "2025-03-01T14:30:00Z",
  "isVoiceNote": false
}
```

**Errors:**

- 403 **INTRO_LIMIT** — Free user already sent one intro in this thread and not matched. Show "Match to continue or upgrade".
- 403 **PREMIUM_REQUIRED** — Reserved; treat like upgrade prompt if needed.

---

### 6.5 Mark thread read (when user opens thread)

```http
POST /chat/threads/:threadId/read
Authorization: Bearer <accessToken>
```

No body. **Critical:** Call this when the user **opens** the thread. The next **GET /chat/threads** will return that thread with **`unreadCount: 0`** so the badge and list update.

**Response 200**

```json
{
  "markedAt": "2025-03-01T14:35:00Z"
}
```

---

## 7. Interactions (interest / requests)

| Action | Method | Path | Body |
|--------|--------|------|------|
| Express interest | POST | `/interactions/interest` | `{ "toUserId": "usr_xyz", "source": "recommended" }` |
| Priority interest | POST | `/interactions/priority-interest` | `{ "toUserId": "usr_xyz", "message": "Hi!", "source": "search" }` |
| Accept / decline | PATCH | `/interactions/:interactionId` | `{ "action": "accept" }` or `"decline"` |
| Withdraw | DELETE | `/interactions/:interactionId` | — |
| Requests inbox | GET | `/interactions/received?status=pending` | — |
| **Requests badge count** | GET | `/interactions/received/count?status=pending` | — |
| Sent | GET | `/interactions/sent` | — |

**GET /interactions/received/count?status=pending** → `{ "count": 5 }`. Use for nav badge.

**GET /interactions/received** → `{ "interactions": [ ... ], "pagination": { ... } }`. Each item has `interactionId`, `type` (`interest` | `priority_interest`), `status`, `createdAt`, `fromUser`, and optional `message`.

---

## 8. Shortlist

| Action | Method | Path | Body |
|--------|--------|------|------|
| My shortlist | GET | `/shortlist` | — |
| Add | POST | `/shortlist` | `{ "profileId": "usr_xyz", "note": "..." }` |
| Remove | DELETE | `/shortlist/:profileId` | — |
| Who shortlisted me | GET | `/shortlist/received` | — |
| **Shortlist badge count** | GET | `/shortlist/received/count` | — |

**GET /shortlist/received/count** → `{ "count": 3 }`.

---

## 9. Visits and matches

| Action | Method | Path | Body |
|--------|--------|------|------|
| Record visit | POST | `/visits` | `{ "profileId": "usr_xyz", "source": "recommended", "durationMs": 5000 }` |
| My visitors | GET | `/visits/received` | — |
| Mark visitors seen | POST | `/visits/mark-seen` | — |
| Mutual matches | GET | `/matches` | — |
| Unmatch | DELETE | `/matches/:matchId` | — |

---

## 10. Notifications and privacy

| Action | Method | Path | Body |
|--------|--------|------|------|
| Register FCM token | POST | `/profile/me/fcm-token` | `{ "fcmToken": "..." }` |
| Remove FCM token | DELETE | `/profile/me/fcm-token` | Optional: `{ "fcmToken": "..." }` |
| Notification prefs | PATCH | `/profile/me/notifications` | `{ "interestReceived": true, "newMessage": true, ... }` |
| Privacy | PATCH | `/profile/me/privacy` | `{ "showInVisitors": true }` |

---

## 11. Profile photos (S3)

1. **Get upload URL(s):**  
   `POST /profile/me/photos/upload-url`  
   Body: `{ "count": 1 }` (or 2–5).  
   Response: `{ "urls": [ { "uploadUrl": "https://...", "key": "profiles/.../x.jpg", "photoUrl": "https://cdn.../x.jpg" } ] }`.

2. **Upload image:**  
   `PUT` to `urls[0].uploadUrl` with header `Content-Type: image/jpeg` and body = raw image bytes. No API auth on this request.

3. **Add to profile:**  
   `POST /profile/me/photos`  
   Body: `{ "key": "profiles/.../x.jpg" }`.  
   Response: `{ "photoUrl": "..." }`.

---

## 12. Discovery and subscription

| Action | Method | Path | Query / body |
|--------|--------|------|----------------|
| **Explore (everyone, then filter)** | GET | `/discovery/explore` | **`mode`** (required), `limit`, `cursor`. Optional filters: `ageMin`, `ageMax`, `city`, `religion`, `education`, `heightMinCm`. **No filters = show everyone** in mode. Same response shape as recommended. |
| Recommended feed | GET | `/discovery/recommended` | `mode`, `limit`, `cursor` |
| Search | GET | `/discovery/search` | Optional: ageMin, ageMax, city, religion, education, heightMinCm, limit, cursor |
| Filter options | GET | `/discovery/filter-options` | — |
| Subscription state | GET | `/subscription/me` | — |
| Entitlements | GET | `/subscription/entitlements` | — |

---

## 13. Quick endpoint table

| Method | Path | Auth | Notes |
|--------|------|------|------|
| POST | /auth/send-otp | No | Body: countryCode, phone |
| POST | /auth/verify-otp | No | Body: verificationId, code |
| POST | /auth/refresh | No | Body: refreshToken |
| POST | /auth/sign-out | Yes | — |
| GET | /profile/me | Yes | 404 → profile setup |
| PATCH | /profile/me | Yes | Partial profile |
| GET | /profile/:userId | Yes | Full profile |
| GET | /profile/:userId/summary | Yes | Chat list/header, cards |
| POST | /profile/me/photos/upload-url | Yes | Body: count |
| POST | /profile/me/photos | Yes | Body: key |
| DELETE | /profile/me/photos/:key | Yes | Key URL-encoded |
| POST | /profile/me/fcm-token | Yes | Body: fcmToken |
| DELETE | /profile/me/fcm-token | Yes | Body optional: fcmToken |
| PATCH | /profile/me/notifications | Yes | Booleans |
| PATCH | /profile/me/privacy | Yes | showInVisitors |
| GET | /chat/threads | Yes | Query: **mode** required, limit, cursor |
| POST | /chat/threads | Yes | Body: otherUserId, **mode** |
| GET | /chat/threads/:threadId/messages | Yes | Query: limit, cursor |
| POST | /chat/threads/:threadId/messages | Yes | Body: text |
| POST | /chat/threads/:threadId/read | Yes | When user opens thread |
| POST | /interactions/interest | Yes | Body: toUserId, source? |
| POST | /interactions/priority-interest | Yes | Body: toUserId, message?, source? |
| PATCH | /interactions/:interactionId | Yes | Body: action (accept \| decline) |
| DELETE | /interactions/:interactionId | Yes | — |
| GET | /interactions/received | Yes | Query: status, page, limit |
| GET | /interactions/received/count | Yes | Query: status=pending → badge |
| GET | /interactions/sent | Yes | — |
| GET | /shortlist | Yes | — |
| GET | /shortlist/received | Yes | — |
| GET | /shortlist/received/count | Yes | → badge |
| POST | /shortlist | Yes | Body: profileId, note? |
| DELETE | /shortlist/:profileId | Yes | — |
| POST | /visits | Yes | Body: profileId, source?, durationMs? |
| GET | /visits/received | Yes | — |
| POST | /visits/mark-seen | Yes | — |
| GET | /matches | Yes | — |
| DELETE | /matches/:matchId | Yes | — |
| GET | /discovery/explore | Yes | Query: **mode** (required), limit, cursor; optional: ageMin, ageMax, city, religion, education, heightMinCm. No filters = everyone. |
| GET | /discovery/recommended | Yes | Query: mode, limit, cursor |
| GET | /subscription/entitlements | Yes | Feature flags |
| GET | /subscription/me | Yes | — |

---

## 14. Common error codes

| code | HTTP | When |
|------|------|------|
| VALIDATION_ERROR | 400 | Invalid/missing body or query; check `details`. |
| PROFILE_NOT_FOUND | 404 | No profile for user → onboarding. |
| NOT_FOUND | 404 | Resource missing. |
| CONNECTION_REQUIRED | 403 | No interest or match; can't start chat. |
| INTRO_LIMIT | 403 | Free user already sent one intro in thread; match or upgrade. |
| PREMIUM_REQUIRED | 403 | Feature gated; show upgrade. |
| DAILY_LIMIT | 403 | Daily limit reached. |
| UNAUTHORIZED | 401 | Invalid/expired token → refresh or login. |

---

## 15. Flutter (this app) — how we’re connected

The Saathi Flutter app uses the endpoints above as follows:

| Area | Implementation |
|------|----------------|
| **Base URL** | `ApiClient.baseUrl` (e.g. from env / build config). |
| **Auth** | `ApiAuthRepository`: POST /auth/send-otp, /auth/verify-otp. `ApiClient` auto-refreshes on 401 via POST /auth/refresh. Sign-out: POST /auth/sign-out; then optional DELETE /profile/me/fcm-token (called before sign-out). |
| **Profile** | `ApiProfileRepository`: GET/PATCH /profile/me, GET /profile/:id, GET /profile/:id/summary, PATCH privacy/notifications, POST/DELETE fcm-token. |
| **Chat** | `ApiChatRepository`: GET /chat/threads (mode, limit), POST /chat/threads (otherUserId, mode), GET/POST .../messages, POST .../read. CONNECTION_REQUIRED on create thread → SnackBar “Send or accept an interest first”. INTRO_LIMIT / PREMIUM_REQUIRED on send message → SnackBar + Upgrade. |
| **Interactions** | `ApiInteractionsRepository`: POST interest, priority-interest; PATCH/DELETE /interactions/:id; GET received, received/count, sent. |
| **Shortlist** | `ApiShortlistRepository`: GET /shortlist, POST/DELETE /shortlist, GET /shortlist/received, /shortlist/received/count. |
| **Visits** | `ApiVisitsRepository`: POST /visits, GET /visits/received, POST /visits/mark-seen. |
| **Matches** | `ApiMatchesRepository`: GET /matches, DELETE /matches/:matchId. |
| **Discovery** | `ApiDiscoveryRepository`: GET /discovery/explore (Explore tab: mode + optional filters; no filters = everyone), /discovery/recommended, /search, /filter-options, compatibility, feedback. |
| **Subscription** | `ApiSubscriptionRepository`: GET /subscription/me, /entitlements; POST purchase, restore. |
| **Photos** | `PhotoUploadService`: POST /profile/me/photos/upload-url (count); PUT to presigned URL; then POST /profile/me/photos with key. |

For full request/response DTOs and more detail, see **[BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md)** and **[chat_endpoint.md](./chat_endpoint.md)**.
