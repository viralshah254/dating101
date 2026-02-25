# Saathi — Backend API Requirements (Master Checklist)

This document is the **single source of truth** for which APIs the backend must build. Use it to plan sprints, track implementation, and ensure the frontend can integrate correctly.

**Detailed specs** for each area are in the linked docs; this file gives the full list and quick reference.

---

## Document map

| Doc | Contents |
|-----|----------|
| **[BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md)** | Auth (OTP, refresh, sign-out), Profile (CRUD, photos, preferences), Security (location), base URL, errors, pagination, ProfileSummary DTO |
| **[BACKEND_INTERACTIONS_AND_VISITORS.md](./BACKEND_INTERACTIONS_AND_VISITORS.md)** | Interest, priority interest, shortlist, profile visits, visitors list, mutual matches, accept/decline, notifications, rate limits, DB schema |
| **[BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md](./BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md)** | Explore tab filter options, strict preferences, `GET /discovery/filter-options` |
| **[MATCHING_AND_COMPATIBILITY.md](./MATCHING_AND_COMPATIBILITY.md)** | ML matching pipeline, recommended endpoint, compatibility scoring, match reasons, feedback loop |
| **[BACKEND_VALIDATION_RULES.md](./BACKEND_VALIDATION_RULES.md)** | Profile validation: required/optional fields, enums, age from DoB |

---

## 1. Auth

| Method | Path | Auth | Purpose | Spec |
|--------|------|------|---------|------|
| POST | `/auth/send-otp` | No | Send OTP to phone | [§1.1](./BACKEND_API_AUTH_AND_PROFILE.md#11-send-otp) |
| POST | `/auth/verify-otp` | No | Verify OTP, return access + refresh tokens | [§1.2](./BACKEND_API_AUTH_AND_PROFILE.md#12-verify-otp) |
| POST | `/auth/refresh` | No | Refresh access token (Bearer refresh token) | [§1.3](./BACKEND_API_AUTH_AND_PROFILE.md) |
| POST | `/auth/sign-out` | Yes | Sign out / invalidate session | [§1.4](./BACKEND_API_AUTH_AND_PROFILE.md) |

---

## 2. Profile

| Method | Path | Auth | Purpose | Spec |
|--------|------|------|---------|------|
| GET | `/profile/me` | Yes | Get current user's full profile | [§2.1](./BACKEND_API_AUTH_AND_PROFILE.md) |
| PATCH | `/profile/me` | Yes | Partial update (deep-merge) | [§2.2](./BACKEND_API_AUTH_AND_PROFILE.md) |
| PUT | `/profile/me` | Yes | Replace full profile | [§2.2](./BACKEND_API_AUTH_AND_PROFILE.md) |
| GET | `/profile/me/preferences` | Yes | Get partner preferences | [§2](./BACKEND_API_AUTH_AND_PROFILE.md) |
| PUT | `/profile/me/preferences` | Yes | Update partner preferences | [§2](./BACKEND_API_AUTH_AND_PROFILE.md) |
| GET | `/profile/:userId` | Yes | Get another user's full profile | [§2](./BACKEND_API_AUTH_AND_PROFILE.md) |
| GET | `/profile/:userId/summary` | Yes | Get ProfileSummary for cards/lists | [§9.6](./BACKEND_API_AUTH_AND_PROFILE.md#96-profilesummary) |
| POST | `/profile/me/photos/upload-url` | Yes | Get presigned S3 upload URL(s) | [§2.8](./BACKEND_API_AUTH_AND_PROFILE.md) |
| DELETE | `/profile/me/photos/:key` | Yes | Delete a photo by S3 key | [§2.9](./BACKEND_API_AUTH_AND_PROFILE.md) |

**ProfileSummary** in all discovery and profile responses must include **`sharedInterests`** (array of interests shared with the current user) and **`age`** computed from `dateOfBirth`. See [BACKEND_API_AUTH_AND_PROFILE.md §9.6](./BACKEND_API_AUTH_AND_PROFILE.md#96-profilesummary) and [BACKEND_VALIDATION_RULES.md](./BACKEND_VALIDATION_RULES.md).

---

## 3. Discovery (matches feed, search, compatibility)

| Method | Path | Auth | Purpose | Spec |
|--------|------|------|---------|------|
| GET | `/discovery/recommended` | Yes | ML-scored recommended profiles (For You tab). Query: `mode`, `limit`, `cursor`. Response must include `sharedInterests` and `age` per profile. | [BACKEND_API_AUTH_AND_PROFILE.md §4.1](./BACKEND_API_AUTH_AND_PROFILE.md), [MATCHING_AND_COMPATIBILITY.md](./MATCHING_AND_COMPATIBILITY.md) |
| GET | `/discovery/search` | Yes | Search with filters (Explore tab). Query: `ageMin`, `ageMax`, `city`, `religion`, `education`, `heightMinCm`, `limit`, `cursor`. Must respect strict preferences server-side. | [BACKEND_API_AUTH_AND_PROFILE.md §4.5](./BACKEND_API_AUTH_AND_PROFILE.md) |
| GET | `/discovery/nearby` | Yes | Profiles by location. Query: `lat`, `lng`, `radiusKm`, `limit` | [BACKEND_API_AUTH_AND_PROFILE.md §4.6](./BACKEND_API_AUTH_AND_PROFILE.md) |
| GET | `/discovery/filter-options` | Yes | Allowed filter options and defaults for Explore tab; respects user's strict preferences. | [BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md](./BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md) |
| GET | `/discovery/compatibility/:candidateId` | Yes | Full compatibility breakdown for a profile (score, label, breakdown, matchReasons, preferenceAlignment) | [BACKEND_API_AUTH_AND_PROFILE.md §4.2](./BACKEND_API_AUTH_AND_PROFILE.md), [MATCHING_AND_COMPATIBILITY.md](./MATCHING_AND_COMPATIBILITY.md) |
| POST | `/discovery/feedback` | Yes | Record interaction for ML (e.g. view, like, pass). Body: `candidateId`, `action`, `timeSpentMs`, `source` | [BACKEND_API_AUTH_AND_PROFILE.md §4.3](./BACKEND_API_AUTH_AND_PROFILE.md) |

---

## 4. Interactions (interest, priority interest, requests inbox)

| Method | Path | Auth | Purpose | Spec |
|--------|------|------|---------|------|
| POST | `/interactions/interest` | Yes | Express interest in a user. Body: `toUserId`, `source`. Auto-match if they already liked you. | [BACKEND_INTERACTIONS_AND_VISITORS.md §3.1](./BACKEND_INTERACTIONS_AND_VISITORS.md#31-express-interest) |
| POST | `/interactions/priority-interest` | Yes | Priority (boosted) interest. Body: `toUserId`, `message?`, `source`. Rate-limited by tier. | [BACKEND_INTERACTIONS_AND_VISITORS.md §3.2](./BACKEND_INTERACTIONS_AND_VISITORS.md#32-express-priority-interest) |
| PATCH | `/interactions/:interactionId` | Yes | Accept or decline. Body: `action: "accept" \| "decline"` | [BACKEND_INTERACTIONS_AND_VISITORS.md §3.3](./BACKEND_INTERACTIONS_AND_VISITORS.md#33-respond-to-interest-accept--decline) |
| DELETE | `/interactions/:interactionId` | Yes | Withdraw own pending interest | [BACKEND_INTERACTIONS_AND_VISITORS.md §3.4](./BACKEND_INTERACTIONS_AND_VISITORS.md#34-withdraw-interest) |
| GET | `/interactions/received` | Yes | Incoming requests (inbox). Query: `status`, `type`, `page`, `limit`. Priority interests first. | [BACKEND_INTERACTIONS_AND_VISITORS.md §3.5](./BACKEND_INTERACTIONS_AND_VISITORS.md#35-get-received-interests-requests-inbox) |
| GET | `/interactions/sent` | Yes | Sent interests. Query: `status`, `page`, `limit` | [BACKEND_INTERACTIONS_AND_VISITORS.md §3.6](./BACKEND_INTERACTIONS_AND_VISITORS.md#36-get-sent-interests) |

---

## 5. Shortlist

| Method | Path | Auth | Purpose | Spec |
|--------|------|------|---------|------|
| POST | `/shortlist` | Yes | Add profile to shortlist. Body: `profileId`, `note?`. Private (no notification to other user). | [BACKEND_INTERACTIONS_AND_VISITORS.md §3.7](./BACKEND_INTERACTIONS_AND_VISITORS.md#37-shortlist-a-profile) |
| DELETE | `/shortlist/:profileId` | Yes | Remove from shortlist | [BACKEND_INTERACTIONS_AND_VISITORS.md §3.8](./BACKEND_INTERACTIONS_AND_VISITORS.md#38-remove-from-shortlist) |
| GET | `/shortlist` | Yes | Get shortlisted profiles. Query: `page`, `limit` | [BACKEND_INTERACTIONS_AND_VISITORS.md §3.9](./BACKEND_INTERACTIONS_AND_VISITORS.md#39-get-shortlisted-profiles) |

---

## 6. Visitors (profile views)

| Method | Path | Auth | Purpose | Spec |
|--------|------|------|---------|------|
| POST | `/visits` | Yes | Record that current user viewed a profile. Body: `profileId`, `source`, `durationMs?`. Dedupe by 24h. | [BACKEND_INTERACTIONS_AND_VISITORS.md §3.10](./BACKEND_INTERACTIONS_AND_VISITORS.md#310-record-profile-visit) |
| GET | `/visits/received` | Yes | List users who viewed my profile (Visitors tab). Query: `page`, `limit`. Response: `visitors`, `newCount` | [BACKEND_INTERACTIONS_AND_VISITORS.md §3.11](./BACKEND_INTERACTIONS_AND_VISITORS.md#311-get-my-visitors) |
| POST | `/visits/mark-seen` | Yes | Mark visitors as seen (reset newCount) | [BACKEND_INTERACTIONS_AND_VISITORS.md §3.12](./BACKEND_INTERACTIONS_AND_VISITORS.md#312-mark-visitors-as-seen) |

---

## 7. Mutual matches

| Method | Path | Auth | Purpose | Spec |
|--------|------|------|---------|------|
| GET | `/matches` | Yes | List mutual matches. Query: `page`, `limit`. Include `chatThreadId`, `lastMessage` where applicable. | [BACKEND_INTERACTIONS_AND_VISITORS.md §8](./BACKEND_INTERACTIONS_AND_VISITORS.md#8-mutual-match-detection) |
| DELETE | `/matches/:matchId` | Yes | Unmatch (optionally archive chat) | [BACKEND_INTERACTIONS_AND_VISITORS.md §8](./BACKEND_INTERACTIONS_AND_VISITORS.md#8-mutual-match-detection) |

---

## 8. Chat

| Method | Path | Auth | Purpose | Spec |
|--------|------|------|---------|------|
| POST | `/chat/threads` | Yes | Get or create thread with another user. Body: `otherUserId`. Return `threadId`. | [BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) |
| GET | `/chat/threads` | Yes | List threads. Query: `limit`, `cursor` | [BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) |
| GET | `/chat/threads/:threadId/messages` | Yes | Get messages. Query: `limit`, `cursor` | [BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) |
| POST | `/chat/threads/:threadId/messages` | Yes | Send message. Body: `text` | [BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) |
| POST | `/chat/threads/:threadId/read` | Yes | Mark thread as read | [BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) |

---

## 9. Subscription & entitlements

| Method | Path | Auth | Purpose | Spec |
|--------|------|------|---------|------|
| GET | `/subscription/me` | Yes | Current subscription status | [BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) |
| POST | `/subscription/purchase` | Yes | Purchase subscription (product id, receipt) | [BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) |
| POST | `/subscription/restore` | Yes | Restore purchases | [BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) |
| GET | `/subscription/entitlements` | Yes | Entitlements (e.g. canSendMessage, priorityInterestLimit) | [BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) |

---

## 10. Security & privacy

| Method | Path | Auth | Purpose | Spec |
|--------|------|------|---------|------|
| POST | `/security/location` | Yes | Record user location (safety pattern). Body: `lat`, `lng`, `address?` | [BACKEND_API_AUTH_AND_PROFILE.md](./BACKEND_API_AUTH_AND_PROFILE.md) |
| PATCH | `/profile/me/privacy` | Yes | Privacy settings (e.g. `showInVisitors: boolean`) | [BACKEND_INTERACTIONS_AND_VISITORS.md §7](./BACKEND_INTERACTIONS_AND_VISITORS.md#7-profile-visit--visitors-flow) |
| PATCH | `/profile/me/notifications` | Yes | Notification preferences (interest received, match, etc.) | [BACKEND_INTERACTIONS_AND_VISITORS.md §9](./BACKEND_INTERACTIONS_AND_VISITORS.md#9-notifications) |

---

## 11. Full checklist (copy for tracking)

Use this table to tick off implemented endpoints. **Auth** = Bearer token required unless "No".

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
| 14 | GET | /discovery/recommended | Yes | ☐ |
| 15 | GET | /discovery/search | Yes | ☐ |
| 16 | GET | /discovery/nearby | Yes | ☐ |
| 17 | GET | /discovery/filter-options | Yes | ☐ |
| 18 | GET | /discovery/compatibility/:id | Yes | ☐ |
| 19 | POST | /discovery/feedback | Yes | ☐ |
| 20 | POST | /interactions/interest | Yes | ☐ |
| 21 | POST | /interactions/priority-interest | Yes | ☐ |
| 22 | PATCH | /interactions/:id | Yes | ☐ |
| 23 | DELETE | /interactions/:id | Yes | ☐ |
| 24 | GET | /interactions/received | Yes | ☐ |
| 25 | GET | /interactions/sent | Yes | ☐ |
| 26 | POST | /shortlist | Yes | ☐ |
| 27 | DELETE | /shortlist/:profileId | Yes | ☐ |
| 28 | GET | /shortlist | Yes | ☐ |
| 29 | POST | /visits | Yes | ☐ |
| 30 | GET | /visits/received | Yes | ☐ |
| 31 | POST | /visits/mark-seen | Yes | ☐ |
| 32 | GET | /matches | Yes | ☐ |
| 33 | DELETE | /matches/:matchId | Yes | ☐ |
| 34 | POST | /chat/threads | Yes | ☐ |
| 35 | GET | /chat/threads | Yes | ☐ |
| 36 | GET | /chat/threads/:threadId/messages | Yes | ☐ |
| 37 | POST | /chat/threads/:threadId/messages | Yes | ☐ |
| 38 | POST | /chat/threads/:threadId/read | Yes | ☐ |
| 39 | GET | /subscription/me | Yes | ☐ |
| 40 | POST | /subscription/purchase | Yes | ☐ |
| 41 | POST | /subscription/restore | Yes | ☐ |
| 42 | GET | /subscription/entitlements | Yes | ☐ |
| 43 | POST | /security/location | Yes | ☐ |
| 44 | PATCH | /profile/me/privacy | Yes | ☐ |
| 45 | PATCH | /profile/me/notifications | Yes | ☐ |

---

## 12. Build order suggestion

1. **Auth** (send-otp, verify-otp, refresh, sign-out) — required for everything.
2. **Profile** (GET/PATCH/PUT profile/me, GET profile/:id, summary, photos) — required for onboarding and profile screens.
3. **Discovery** (recommended, search, nearby) — required for Matches tabs. Ensure `age` and `sharedInterests` in responses.
4. **Compatibility** (GET discovery/compatibility/:id) — for profile detail screen.
5. **Interactions** (interest, priority-interest, received, sent, accept/decline, withdraw) — for Requests and match actions.
6. **Shortlist** (POST, DELETE, GET shortlist) — for Shortlist tab.
7. **Visitors** (POST visits, GET visits/received, mark-seen) — for Visitors tab.
8. **Matches** (GET matches, DELETE match) — for Matches tab and mutual match flow.
9. **Chat** (threads, messages, read) — for Chats tab.
10. **Filter options** (GET discovery/filter-options) — for Explore filters and strict preferences.
11. **Subscription & entitlements** — for paywall and feature gating.
12. **Security** (location) and **privacy/notifications** — for safety and settings.

---

## 13. Cross-cutting requirements

- **ProfileSummary** in discovery and profile endpoints must include:
  - **age** (computed from dateOfBirth; do not return null when DoB is set).
  - **sharedInterests** (array of interests the profile shares with the current user).
  - **compatibilityScore**, **compatibilityLabel**, **matchReasons**, **breakdown** when available.
- **Recommended** and **search** must respect user’s **strict preferences** server-side (see [BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md](./BACKEND_FILTER_OPTIONS_AND_PREFERENCES.md)).
- **Errors**: Use consistent shape `{ code, message, details? }` and appropriate HTTP status codes.
- **Pagination**: List endpoints use `limit` and `cursor`; response includes `nextCursor` (or `hasMore`).
