# Saathi — New & Required Endpoints (Backend Reference)

This document lists **all endpoints** the Saathi frontend expects the backend to implement. Use it as the single reference for building or updating APIs. For detailed request/response shapes and flows, see the linked spec docs.

**Related docs:**  
[BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) · [BACKEND_INTERACTIONS_AND_VISITORS.md](./BACKEND_INTERACTIONS_AND_VISITORS.md) · [BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md](./BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md) · [BACKEND_API_REQUIREMENTS.md](./BACKEND_API_REQUIREMENTS.md)

---

## Conventions

- **Auth:** “Yes” = `Authorization: Bearer <accessToken>` required.
- **Errors:** Use `{ "code": "ERROR_CODE", "message": "...", "details": {} }` and appropriate HTTP status.
- **ProfileSummary:** All list endpoints that return profiles must include `age` (from DoB), `sharedInterests` (array), and standard fields (`id`, `name`, `imageUrl`, `city`, etc.).

---

## 1. Auth

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/auth/send-otp` | No | Send OTP. Body: `countryCode`, `phone`. |
| POST | `/auth/verify-otp` | No | Verify OTP; return `accessToken`, `refreshToken`, `userId`, `isNewUser`. |
| POST | `/auth/refresh` | No | Refresh access token. Body or header: `refreshToken`. |
| POST | `/auth/sign-out` | Yes | Sign out / invalidate session. |

---

## 2. Profile

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/profile/me` | Yes | Current user full profile. |
| PATCH | `/profile/me` | Yes | Partial profile update (deep-merge). |
| PUT | `/profile/me` | Yes | Replace full profile. |
| GET | `/profile/me/preferences` | Yes | Partner preferences. |
| PUT | `/profile/me/preferences` | Yes | Update partner preferences. |
| GET | `/profile/:userId` | Yes | Another user’s full profile. |
| GET | `/profile/:userId/summary` | Yes | ProfileSummary for cards/lists. |
| POST | `/profile/me/photos/upload-url` | Yes | Presigned S3 upload URL(s). |
| DELETE | `/profile/me/photos/:key` | Yes | Delete photo by S3 key. |
| PATCH | `/profile/me/privacy` | Yes | Privacy (e.g. `showInVisitors`). |
| PATCH | `/profile/me/notifications` | Yes | Notification preferences. |
| POST | `/profile/me/fcm-token` | Yes | Register FCM device token for push. Body: `{ "fcmToken": "..." }`. See [BACKEND_PUSH_NOTIFICATIONS.md](./BACKEND_PUSH_NOTIFICATIONS.md). |

---

## 3. Discovery (Matches feed, search, filters)

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/discovery/recommended` | Yes | Recommended profiles. Query: `mode`, `limit`, `cursor`. Include `sharedInterests`, `age`. |
| GET | `/discovery/search` | Yes | Search with filters. Query: `ageMin`, `ageMax`, `city`, `religion`, `education`, `heightMinCm`, `limit`, `cursor`. Respect strict preferences server-side. |
| GET | `/discovery/nearby` | Yes | Profiles by location. Query: `lat`, `lng`, `radiusKm`, `limit`. |
| GET | `/discovery/filter-options` | Yes | Filter options and defaults for Explore tab; respect strict preferences. See [BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md](./BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md). |
| GET | `/discovery/compatibility/:candidateId` | Yes | Compatibility breakdown (score, label, breakdown, matchReasons, preferenceAlignment). |
| POST | `/discovery/feedback` | Yes | Record interaction for ML. Body: `candidateId`, `action`, `timeSpentMs`, `source`. |

---

## 4. Interactions (Interest, priority interest, requests inbox)

The app uses **“Interested”** and **“Priority interest”** (no success snackbars; priority is highlighted in the Requests screen). Received/sent lists must expose `type` so the UI can show a “Priority interest” badge.

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/interactions/interest` | Yes | Express interest. Body: `toUserId`, `source?`. Auto-match if they already liked you. |
| POST | `/interactions/priority-interest` | Yes | Priority (boosted) interest. Body: `toUserId`, `message?`, `source?`. Rate-limited by tier. |
| PATCH | `/interactions/:interactionId` | Yes | Accept or decline. Body: `action: "accept" \| "decline"`. On accept, return `mutualMatch`, `matchId`, `chatThreadId` when applicable. |
| DELETE | `/interactions/:interactionId` | Yes | Withdraw own pending interest (sender only). |
| GET | `/interactions/received` | Yes | **Requests inbox.** Query: `status`, `type`, `page`, `limit`. **Must return `type` per item** (`interest` \| `priority_interest`) so the app can highlight priority. Sort priority interests first. Response: `interactions[]` with `interactionId`, `type`, `fromUser` (ProfileSummary), `message?`, `createdAt`, `seenByRecipient`, `status`. |
| GET | `/interactions/sent` | Yes | Sent interests. Query: `status`, `page`, `limit`. Response: `interactions[]` with `interactionId`, `type`, `toUser` (ProfileSummary), `message?`, `createdAt`, `status`. |

**Frontend behaviour:**  
- No success snackbars for interest/priority; errors only.  
- Requests screen shows Received / Sent tabs; priority interests are visually highlighted (e.g. “Priority interest” badge).  
- Accept navigates to chat when `chatThreadId` is returned.

---

## 5. Shortlist

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/shortlist` | Yes | Add to shortlist. Body: `profileId`, `note?`. Private (no notification to other user). |
| DELETE | `/shortlist/:profileId` | Yes | Remove from shortlist. Path uses `profileId` (or `userId`). |
| GET | `/shortlist` | Yes | My shortlisted profiles. Query: `page`, `limit`. Response: `profiles[]` where each item has nested `profile` (ProfileSummary) and optional `shortlistId`, `note`, `createdAt`. |
| GET | `/shortlist/received` | Yes | **People who shortlisted me** (premium). Returns minimal list for “Shortlisted you” tab. Response: e.g. `profiles[]` with `profileId`, `firstName`, `age` (and optionally blurred/limited data for non‑premium). See [BACKEND_INTERACTIONS_AND_VISITORS.md](./BACKEND_INTERACTIONS_AND_VISITORS.md) if extended. |

**Note:** The app’s Shortlist screen has two tabs: “Shortlisted” (my list) and “Shortlisted you” (who shortlisted me). The latter requires an endpoint such as `GET /shortlist/received` (or equivalent) returning minimal fields; entitlement `canSeeWhoShortlistedYou` gates full visibility.

---

## 6. Visitors (profile views)

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/visits` | Yes | Record profile view. Body: `profileId`, `source`, `durationMs?`. Dedupe by 24h. |
| GET | `/visits/received` | Yes | List who viewed my profile. Query: `page`, `limit`. Response: `visitors[]` (each with `visitId`, `visitor` ProfileSummary, `visitedAt`, `source`), `newCount`. |
| POST | `/visits/mark-seen` | Yes | Mark visitors as seen; reset `newCount`. |

---

## 7. Mutual matches

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/matches` | Yes | List mutual matches. Query: `page`, `limit`. Include `chatThreadId`, `lastMessage` where applicable. |
| DELETE | `/matches/:matchId` | Yes | Unmatch (optionally archive chat). |

---

## 8. Chat

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/chat/threads` | Yes | Get or create thread. Body: `otherUserId`. Return `threadId`. |
| GET | `/chat/threads` | Yes | List threads. Query: `limit`, `cursor`. |
| GET | `/chat/threads/:threadId/messages` | Yes | Messages. Query: `limit`, `cursor`. |
| POST | `/chat/threads/:threadId/messages` | Yes | Send message. Body: `text`. |
| POST | `/chat/threads/:threadId/read` | Yes | Mark thread as read. |

---

## 9. Subscription & entitlements

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/subscription/me` | Yes | Current subscription status. |
| POST | `/subscription/purchase` | Yes | Purchase (product id, receipt). |
| POST | `/subscription/restore` | Yes | Restore purchases. |
| GET | `/subscription/entitlements` | Yes | Feature flags: e.g. `canSendMessage`, `canSeeWhoShortlistedYou`, `priorityInterestLimit`. |

---

## 10. Security & privacy

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/security/location` | Yes | Record location. Body: `lat`, `lng`, `address?`. |

---

## 11. Checklist (copy for tracking)

| # | Method | Path | Auth | Implemented |
|---|--------|------|------|-------------|
| 1 | POST | /auth/send-otp | No | ☐ |
| 2 | POST | /auth/verify-otp | No | ☐ |
| 3 | POST | /auth/refresh | No | ☐ |
| 4 | POST | /auth/sign-out | Yes | ☐ |
| 5 | GET | /profile/me | Yes | ☐ |
| 6 | PATCH | /profile/me | Yes | ☐ |
| 7 | PUT | /profile/me | Yes | ☐ |
| 8 | GET | /profile/me/preferences | Yes | ☐ |
| 9 | PUT | /profile/me/preferences | Yes | ☐ |
| 10 | GET | /profile/:userId | Yes | ☐ |
| 11 | GET | /profile/:userId/summary | Yes | ☐ |
| 12 | POST | /profile/me/photos/upload-url | Yes | ☐ |
| 13 | DELETE | /profile/me/photos/:key | Yes | ☐ |
| 14 | PATCH | /profile/me/privacy | Yes | ☐ |
| 15 | PATCH | /profile/me/notifications | Yes | ☐ |
| 16 | GET | /discovery/recommended | Yes | ☐ |
| 17 | GET | /discovery/search | Yes | ☐ |
| 18 | GET | /discovery/nearby | Yes | ☐ |
| 19 | GET | /discovery/filter-options | Yes | ☐ |
| 20 | GET | /discovery/compatibility/:id | Yes | ☐ |
| 21 | POST | /discovery/feedback | Yes | ☐ |
| 22 | POST | /interactions/interest | Yes | ☐ |
| 23 | POST | /interactions/priority-interest | Yes | ☐ |
| 24 | PATCH | /interactions/:interactionId | Yes | ☐ |
| 25 | DELETE | /interactions/:interactionId | Yes | ☐ |
| 26 | GET | /interactions/received | Yes | ☐ |
| 27 | GET | /interactions/sent | Yes | ☐ |
| 28 | POST | /shortlist | Yes | ☐ |
| 29 | DELETE | /shortlist/:profileId | Yes | ☐ |
| 30 | GET | /shortlist | Yes | ☐ |
| 31 | GET | /shortlist/received | Yes | ☐ |
| 32 | POST | /visits | Yes | ☐ |
| 33 | GET | /visits/received | Yes | ☐ |
| 34 | POST | /visits/mark-seen | Yes | ☐ |
| 35 | GET | /matches | Yes | ☐ |
| 36 | DELETE | /matches/:matchId | Yes | ☐ |
| 37 | POST | /chat/threads | Yes | ☐ |
| 38 | GET | /chat/threads | Yes | ☐ |
| 39 | GET | /chat/threads/:threadId/messages | Yes | ☐ |
| 40 | POST | /chat/threads/:threadId/messages | Yes | ☐ |
| 41 | POST | /chat/threads/:threadId/read | Yes | ☐ |
| 42 | GET | /subscription/me | Yes | ☐ |
| 43 | POST | /subscription/purchase | Yes | ☐ |
| 44 | POST | /subscription/restore | Yes | ☐ |
| 45 | GET | /subscription/entitlements | Yes | ☐ |
| 46 | POST | /security/location | Yes | ☐ |

---

## 12. Build order suggestion

1. **Auth** (send-otp, verify-otp, refresh, sign-out).  
2. **Profile** (GET/PATCH/PUT profile/me, GET profile/:id, summary, photos, privacy, notifications).  
3. **Discovery** (recommended, search, nearby, filter-options, compatibility, feedback).  
4. **Interactions** (interest, priority-interest, received, sent, accept/decline, withdraw).  
5. **Shortlist** (POST, DELETE, GET shortlist; **GET shortlist/received** for “Shortlisted you” tab).  
6. **Visitors** (POST visits, GET visits/received, mark-seen).  
7. **Matches** (GET matches, DELETE match).  
8. **Chat** (threads, messages, read).  
9. **Subscription & entitlements.**  
10. **Security** (location).

---

*Last updated to reflect: Requests screen (Received/Sent, priority highlight), shortlist icon and naming (“Priority interest”), no success snackbars for interest/shortlist, and required endpoint for “People who shortlisted me” (GET /shortlist/received).*
