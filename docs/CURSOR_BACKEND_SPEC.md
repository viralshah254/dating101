# Saathi Backend — Cursor spec: connect frontend to this API

**Purpose:** Feed this document to Cursor when implementing or fixing the frontend connection to the Saathi backend. Use it to generate API client code, auth flow, discovery feed, profile screens, and error handling.

**Backend repo context:** This is the Saathi dating/matrimony backend. Base URL: production `https://api.saathi.app`, local `http://localhost:3000`. All JSON; auth via `Authorization: Bearer <accessToken>` except for send-otp, verify-otp, refresh.

---

## 1. Config and API client

- **Base URL:** Read from env (e.g. `EXPO_PUBLIC_API_URL`, `VITE_API_URL`, `NEXT_PUBLIC_API_URL`). Fallback for local: `http://localhost:3000`.
- **Headers:** Every request: `Content-Type: application/json`. Authenticated requests: add `Authorization: Bearer <accessToken>`.
- **Errors:** Response body is always `{ code: string, message: string, details?: Record<string, unknown> }`. HTTP status 4xx/5xx. Use `code` for branching (e.g. `PROFILE_NOT_FOUND`), `message` for user-facing text.
- **401:** Call refresh once, then retry the request. If refresh returns 401, clear tokens and redirect to login.

Implement a single API helper that:
- Accepts `path`, `method`, `body?`, `token?`.
- Uses the base URL and headers above.
- On 4xx/5xx, throws or returns a rejected promise with `{ status, code, message, details }`.
- Parses JSON for both success and error bodies.

---

## 2. Auth flow (phone OTP)

**Endpoints (no auth):**

- `POST /auth/send-otp`
  Body: `{ countryCode: string, phone: string }`
  Response: `{ verificationId: string, expiresInSeconds: number }`

- `POST /auth/verify-otp`
  Body: `{ verificationId: string, code: string }`
  Response: `{ accessToken: string, refreshToken: string, expiresIn: number, userId: string, isNewUser: boolean }`

- `POST /auth/refresh`
  Body: `{ refreshToken: string }`
  Response: `{ accessToken: string, expiresIn: number }`

**With token:**

- `POST /auth/sign-out`
  Headers: `Authorization: Bearer <accessToken>`
  Response: `{}`

**Implementation:**

1. Login screen: call send-otp with country code + phone; store `verificationId`; show OTP input.
2. On verify: call verify-otp with `verificationId` and user-entered `code`. Store `accessToken`, `refreshToken`, `userId` in secure storage. If `isNewUser === true`, go to onboarding; else go to home (or next step).
3. After login, call `GET /profile/me` (see below). If 404 and `code === "PROFILE_NOT_FOUND"`, show profile setup (onboarding) instead of home.
4. Sign out: call `POST /auth/sign-out` with current access token, then clear all stored tokens and userId.

**Local dev:** When backend uses mock SMS, OTP code is always `1111`.

---

## 3. Types (TypeScript) — copy these for the frontend

```ts
// API error (when !res.ok)
export interface ApiError {
  status: number;
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

// Auth
export interface SendOtpResponse {
  verificationId: string;
  expiresInSeconds: number;
}
export interface VerifyOtpResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  userId: string;
  isNewUser: boolean;
}
export interface RefreshResponse {
  accessToken: string;
  expiresIn: number;
}

// Profile summary (cards, lists)
export interface ProfileSummary {
  id: string;
  name: string;
  age: number | null;
  city: string | null;
  imageUrl: string | null;
  distanceKm: number | null;
  verified: boolean;
  matchReason: string | null;
  bio: string;
  promptAnswer: string | null;
  interests: string[];
  motherTongue: string | null;
  occupation: string | null;
  heightCm: number | null;
  religion: string | null;
  community: string | null;
  educationDegree: string | null;
  maritalStatus: string | null;
  diet: string | null;
  incomeLabel: string | null;
  employer: string | null;
  familyType: string | null;
  photoCount: number;
}

// Recommended feed item (includes compatibility)
export interface RecommendedProfile extends ProfileSummary {
  compatibilityScore?: number;
  compatibilityLabel?: string;
  matchReasons?: string[];
  breakdown?: {
    basics: number;
    culture: number;
    lifestyle: number;
    career: number;
    interests: number;
    family: number;
    location: number;
  };
}

// Recommended response
export interface RecommendedResponse {
  profiles: RecommendedProfile[];
  nextCursor: string | null;
}

// Compatibility for one profile
export interface CompatibilityResponse {
  candidateId: string;
  compatibilityScore: number;
  compatibilityLabel: string;
  matchReasons: string[];
  breakdown: {
    basics: number;
    culture: number;
    lifestyle: number;
    career: number;
    interests: number;
    family: number;
    location: number;
  };
  preferenceAlignment: Record<string, string>;
}

// Feedback
export interface FeedbackBody {
  candidateId: string;
  action: "like" | "pass" | "superlike" | "block" | "report" | "view";
  timeSpentMs?: number;
  source?: "recommended" | "search" | "nearby";
}

// Discovery preferences (for prefill)
export interface DiscoveryPreferencesResponse {
  current: {
    ageMin?: number;
    ageMax?: number;
    preferredReligions?: string[];
    preferredMotherTongues?: string[];
    strictFilters?: Record<string, boolean>;
  };
  suggestions: unknown[];
}

// Paginated list (generic)
export interface Paginated<T> {
  nextCursor: string | null;
  [key: string]: T[] | string | null | undefined;
}
```

---

## 4. Profile and app entry

- **GET /profile/me**
  Auth: required.
  Success 200: body is full UserProfile (id, name, gender, age, dateOfBirth, currentCity, aboutMe, photoUrls, interests, matrimonyExtensions, partnerPreferences, etc.).
  Error 404 with `code: "PROFILE_NOT_FOUND"`: user has no profile → show profile setup flow.

**Implementation:** On app load (after restoring tokens), call GET /profile/me. If 200, go to main app (e.g. home). If 404 PROFILE_NOT_FOUND, go to onboarding. If 401, try refresh then retry; if refresh fails, go to login.

- **PATCH /profile/me**
  Auth: required. Body: partial profile (only fields that changed). Backend merges. Use for step-by-step profile setup and edits.

- **PUT /profile/me**
  Auth: required. Body: full profile. Use for initial profile creation (first time). Can return 201 (created) or 200 (replaced).

- **GET /profile/me/preferences**
  Auth: required. Returns partner preferences (ageMin, ageMax, genderPreference, preferredReligions, preferredMotherTongues, strictFilters, etc.).

- **PUT /profile/me/preferences**
  Auth: required. Body: full partner preferences object. Use when user saves "Partner preferences" screen.

- **GET /profile/:userId**
  Auth: required. Returns full profile for another user (for profile detail screen).

- **GET /profile/:userId/summary**
  Auth: required. Returns ProfileSummary for cards/lists.

---

## 5. Discovery and matching (main feed)

**Recommended feed (with compatibility):**

- **GET /discovery/recommended**
  Query: `mode` (required: `"dating"` | `"matrimony"`), `limit` (optional, default 20, max 50), `cursor` (optional, for next page).
  Auth: required.
  Response: `{ profiles: RecommendedProfile[], nextCursor: string | null }`.

**Implementation:**

- Store `mode` in app state or user settings (dating vs matrimony).
- First load: `GET /discovery/recommended?mode=<mode>&limit=20`. No cursor.
- Append `profiles` to the feed. Show on each card: `imageUrl`, `name`, `age`, `city`, `bio`, `compatibilityScore` / `compatibilityLabel`, and up to 3 `matchReasons`.
- "Load more": if `nextCursor` is not null, call again with `cursor=<nextCursor>`, append new profiles, update stored cursor (or use last profile id as cursor per backend).
- When user swipes/clicks Like or Pass: call feedback (see below), then remove that profile from local state and optionally fetch more so the list stays full.

**Compatibility for one profile:**

- **GET /discovery/compatibility/:candidateId**
  Query: `mode` (optional, same as above). Auth: required.
  Response: `CompatibilityResponse` (score, label, matchReasons, breakdown, preferenceAlignment).

**Implementation:** When user opens a full profile screen for `candidateId`, call this and show "Why you match" (matchReasons + breakdown). Use `preferenceAlignment` for checkmarks or short labels (match, close, within_range, no_preference, mismatch, same_city).

**Feedback (like / pass / block):**

- **POST /discovery/feedback**
  Auth: required. Body: `FeedbackBody` — `candidateId` (required), `action` (required: "like" | "pass" | "superlike" | "block" | "report" | "view"), `timeSpentMs` (optional), `source` (optional: "recommended" | "search" | "nearby").

**Implementation:** On Like / Pass / Block (and optionally on open, with action "view"), call this with the current profile's `id` as `candidateId` and the chosen `action`. Optionally send `timeSpentMs` if you track time on screen. Then remove that profile from the feed and, if needed, load more.

**Discovery preferences (prefill):**

- **GET /discovery/preferences**
  Auth: required. Response: `DiscoveryPreferencesResponse` (current prefs + suggestions). Use `current` to prefill the "Partner preferences" or "Discovery settings" screen.

---

## 6. Other endpoints (concise)

- **POST /security/location** — Body: `{ lat: number, lng: number, address?: string }`. Call when you have location (e.g. once per day or on app open).
- **GET /discovery/search** — Query: ageMin, ageMax, city, religion, education, heightMinCm, limit, cursor. Auth required. Same response shape as recommended (profiles + nextCursor).
- **GET /discovery/nearby** — Query: lat, lng, radiusKm?, limit, cursor. Auth required. Same response shape.
- **POST /interests** — Body: `{ toUserId: string, message?: string }`. Auth required. 201 returns interest object.
- **GET /interests/received**, **GET /interests/sent** — Query: limit, cursor. Auth required. Response: `{ interests: Interest[], nextCursor }`.
- **POST /interests/:interestId/accept**, **POST /interests/:interestId/decline** — Auth required.
- **DELETE /interests/:interestId** — Auth required. 204.
- **GET /shortlist**, **POST /shortlist/:userId**, **DELETE /shortlist/:userId**, **GET /shortlist/:userId/check** — Auth required. Shortlist returns profiles + nextCursor.
- **POST /chat/threads** — Body: `{ otherUserId: string }`. Returns `{ id: threadId }`. Use for "Message" from profile.
- **GET /chat/threads** — Query: limit. Returns `{ threads: ChatThreadSummary[] }`.
- **GET /chat/threads/:threadId/messages** — Query: limit, cursor. Returns `{ messages: ChatMessage[], nextCursor }`.
- **POST /chat/threads/:threadId/messages** — Body: `{ text: string }`. Auth required.
- **POST /chat/threads/:threadId/read** — Auth required. Mark read.
- **GET /subscription/me** — Auth required. Returns tier, expiresAt, isActive.
- **GET /subscription/entitlements** — Auth required. Returns flags like canSendMessage, dailyInterestLimit, etc. Use to show/disable features and limits.

---

## 7. Implementation checklist for Cursor

When connecting the frontend to this backend:

1. **Env:** Add `API_BASE_URL` (or framework equivalent) with value `http://localhost:3000` for dev and `https://api.saathi.app` for prod.
2. **API client:** One function or module that builds URL from base + path, sets Content-Type and optional Authorization, sends JSON body, parses JSON, and on !res.ok throws/rejects with `{ status, code, message, details }`.
3. **Auth storage:** Persist accessToken, refreshToken, userId (secure storage). On 401, call POST /auth/refresh with refreshToken; on success update accessToken and retry; on 401 from refresh, clear storage and redirect to login.
4. **Login:** send-otp → verify-otp → store tokens + userId → GET /profile/me. If 404 PROFILE_NOT_FOUND → onboarding; else → home.
5. **Onboarding:** Collect profile steps; use PUT /profile/me for first create, PATCH for updates. On "Partner preferences" use PUT /profile/me/preferences. Include creationLat, creationLng, creationAt, creationAddress in profile when available.
6. **Home / discovery:** GET /discovery/recommended?mode=<mode>&limit=20. Render RecommendedProfile cards with compatibilityScore, compatibilityLabel, matchReasons. Paginate with nextCursor.
7. **Profile action (like/pass/block):** POST /discovery/feedback with candidateId and action; then remove from list and optionally load more.
8. **Profile detail screen:** GET /profile/:userId for full profile; GET /discovery/compatibility/:candidateId for match reasons and breakdown. Show preferenceAlignment if desired.
9. **Errors:** Show API `message` to user; use `code` for PROFILE_NOT_FOUND (→ onboarding), VALIDATION_ERROR (→ field errors from details), 401 (→ refresh or logout).

---

## 8. Reference docs (same repo)

- **[BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md)** — Full request/response shapes, all endpoints, error codes, DTOs.
- **[FRONTEND_INTEGRATION_GUIDE.md](./FRONTEND_INTEGRATION_GUIDE.md)** — Human-oriented integration guide.
- **[MATCHING_AND_COMPATIBILITY.md](./MATCHING_AND_COMPATIBILITY.md)** — How recommended and compatibility scores are computed.

Use this file as the single source for Cursor when generating or editing frontend code that talks to the Saathi backend.
