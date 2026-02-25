# Saathi — Interactions, Interests & Visitors API

Backend specification for profile interactions: expressing interest, priority interest, shortlisting, profile visits (visitors), and the notifications/mutual-match flows that tie them together.

---

## Table of contents

1. [Overview & terminology](#1-overview--terminology)
2. [Data model](#2-data-model)
3. [API endpoints](#3-api-endpoints)
4. [Interest flow](#4-interest-flow)
5. [Priority interest flow](#5-priority-interest-flow)
6. [Shortlist flow](#6-shortlist-flow)
7. [Profile visit / visitors flow](#7-profile-visit--visitors-flow)
8. [Mutual match detection](#8-mutual-match-detection)
9. [Notifications](#9-notifications)
10. [Rate limits & abuse prevention](#10-rate-limits--abuse-prevention)
11. [Database schema](#11-database-schema)
12. [Frontend integration notes](#12-frontend-integration-notes)

---

## 1. Overview & terminology

| Term | Meaning |
|------|---------|
| **Interest** | User A signals they like User B. Free for everyone. |
| **Priority Interest** | A boosted interest — placed at the top of B's request inbox. Limited per day (free: 1/day, premium: 5/day). |
| **Shortlist** | User A saves User B for later review. Private — B is **not** notified. |
| **Profile Visit** | User A opens User B's full profile. B can see A in their "Visitors" tab. |
| **Mutual Match** | Both A and B have expressed interest (or priority) in each other. Unlocks messaging. |

### Core principle

When User A expresses interest or priority interest in User B, the backend automatically creates a **request** in B's inbox. B can then **accept** (creating a mutual match) or **decline**. This is not a silent like — the other person always knows.

---

## 2. Data model

### 2.1 Interaction record

```typescript
interface Interaction {
  id: string;                  // uuid
  fromUserId: string;          // who initiated
  toUserId: string;            // who received
  type: 'interest' | 'priority_interest' | 'shortlist' | 'visit';
  status: 'pending' | 'accepted' | 'declined' | 'withdrawn';
  message?: string;            // optional intro message (priority only)
  createdAt: DateTime;
  updatedAt: DateTime;
  expiresAt?: DateTime;        // interest expires after 30 days if no response
  seenByRecipient: boolean;    // has B seen this in their requests tab
  metadata?: {
    source: string;            // 'recommended' | 'search' | 'visitors' | 'explore'
    compatibilityScore?: number;
  };
}
```

### 2.2 Shortlist record

```typescript
interface Shortlist {
  id: string;
  userId: string;              // who shortlisted
  profileId: string;           // who was shortlisted
  createdAt: DateTime;
  note?: string;               // optional private note
}
```

### 2.3 Profile visit record

```typescript
interface ProfileVisit {
  id: string;
  visitorId: string;           // who viewed
  profileId: string;           // whose profile was viewed
  visitedAt: DateTime;
  source: string;              // 'recommended' | 'search' | 'visitors' | 'explore'
  durationMs?: number;         // how long they spent on the profile
}
```

### 2.4 Mutual match record

```typescript
interface MutualMatch {
  id: string;
  userAId: string;
  userBId: string;
  matchedAt: DateTime;
  interactionAId: string;      // A's interest/priority_interest
  interactionBId: string;      // B's accept
  chatThreadId?: string;       // auto-created chat thread
}
```

---

## 3. API endpoints

### 3.1 Express interest

```
POST /interactions/interest
```

**Request body:**

```json
{
  "toUserId": "usr_abc123",
  "source": "recommended"
}
```

**Response `201 Created`:**

```json
{
  "interactionId": "int_xyz",
  "type": "interest",
  "status": "pending",
  "createdAt": "2026-02-23T10:00:00Z",
  "mutualMatch": false
}
```

If B has already expressed interest in A, this immediately becomes a mutual match:

```json
{
  "interactionId": "int_xyz",
  "type": "interest",
  "status": "accepted",
  "createdAt": "2026-02-23T10:00:00Z",
  "mutualMatch": true,
  "matchId": "match_abc",
  "chatThreadId": "thread_123"
}
```

**Errors:**

| Code | Meaning |
|------|---------|
| `ALREADY_SENT` | Interest already pending/accepted for this pair |
| `SELF_INTERACTION` | Cannot express interest in yourself |
| `USER_BLOCKED` | One party has blocked the other |
| `PROFILE_INCOMPLETE` | Sender's profile is too incomplete (<30% completeness) |

---

### 3.2 Express priority interest

```
POST /interactions/priority-interest
```

**Request body:**

```json
{
  "toUserId": "usr_abc123",
  "message": "Hi! I noticed we share similar values and interests.",
  "source": "recommended"
}
```

**Response `201 Created`:**

```json
{
  "interactionId": "int_xyz",
  "type": "priority_interest",
  "status": "pending",
  "createdAt": "2026-02-23T10:00:00Z",
  "mutualMatch": false,
  "priorityRemaining": 4
}
```

**Additional errors:**

| Code | Meaning |
|------|---------|
| `PRIORITY_LIMIT_REACHED` | Daily priority interest limit exhausted |
| `UPGRADE_REQUIRED` | Free tier used their 1 daily priority, prompt upgrade |

**Limits:**

| Tier | Daily limit |
|------|-------------|
| Free | 1 |
| Silver | 3 |
| Gold | 5 |
| Platinum | 10 |

---

### 3.3 Respond to interest (accept / decline)

```
PATCH /interactions/:interactionId
```

**Request body:**

```json
{
  "action": "accept"
}
```

or

```json
{
  "action": "decline"
}
```

**Response `200 OK` (accept):**

```json
{
  "interactionId": "int_xyz",
  "status": "accepted",
  "mutualMatch": true,
  "matchId": "match_abc",
  "chatThreadId": "thread_123"
}
```

**Response `200 OK` (decline):**

```json
{
  "interactionId": "int_xyz",
  "status": "declined"
}
```

---

### 3.4 Withdraw interest

```
DELETE /interactions/:interactionId
```

Only the **sender** can withdraw, and only while `status == 'pending'`.

**Response `200 OK`:**

```json
{
  "interactionId": "int_xyz",
  "status": "withdrawn"
}
```

---

### 3.5 Get received interests (requests inbox)

```
GET /interactions/received?status=pending&page=1&limit=20
```

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `status` | string | `pending` | `pending`, `accepted`, `declined`, `all` |
| `page` | int | 1 | Page number |
| `limit` | int | 20 | Items per page |
| `type` | string | `all` | `interest`, `priority_interest`, `all` |

Priority interests appear **first** in the list, sorted by `createdAt` desc within each group.

**Response `200 OK`:**

```json
{
  "interactions": [
    {
      "interactionId": "int_xyz",
      "type": "priority_interest",
      "fromUser": {
        "id": "usr_abc",
        "name": "Priya S",
        "age": 27,
        "imageUrl": "https://...",
        "city": "Mumbai",
        "religion": "Hindu",
        "occupation": "Software Engineer",
        "compatibilityScore": 0.82,
        "verified": true
      },
      "message": "Hi! I noticed we share similar values.",
      "createdAt": "2026-02-23T10:00:00Z",
      "seenByRecipient": false
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "hasMore": false
  }
}
```

---

### 3.6 Get sent interests

```
GET /interactions/sent?status=pending&page=1&limit=20
```

Same query params and response shape as received, but `toUser` instead of `fromUser`.

---

### 3.7 Shortlist a profile

```
POST /shortlist
```

**Request body:**

```json
{
  "profileId": "usr_abc123",
  "note": "Good family background"
}
```

**Response `201 Created`:**

```json
{
  "shortlistId": "sl_xyz",
  "profileId": "usr_abc123",
  "createdAt": "2026-02-23T10:00:00Z"
}
```

Shortlisting is **private** — the other user is never notified.

---

### 3.8 Remove from shortlist

```
DELETE /shortlist/:profileId
```

**Response `200 OK`:**

```json
{ "removed": true }
```

---

### 3.9 Get shortlisted profiles

```
GET /shortlist?page=1&limit=20
```

**Response `200 OK`:**

```json
{
  "profiles": [
    {
      "shortlistId": "sl_xyz",
      "profile": {
        "id": "usr_abc",
        "name": "Ananya R",
        "age": 25,
        "imageUrl": "https://...",
        "city": "Delhi",
        "religion": "Hindu",
        "compatibilityScore": 0.75,
        "verified": true
      },
      "note": "Good family background",
      "createdAt": "2026-02-23T10:00:00Z"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 3, "hasMore": false }
}
```

---

### 3.10 Record profile visit

```
POST /visits
```

Called automatically by the frontend when a user opens someone's full profile.

**Request body:**

```json
{
  "profileId": "usr_abc123",
  "source": "recommended",
  "durationMs": 45000
}
```

**Response `201 Created`:**

```json
{
  "visitId": "vis_xyz",
  "profileId": "usr_abc123",
  "visitedAt": "2026-02-23T10:00:00Z"
}
```

**Deduplication:** Multiple visits from the same user to the same profile within 24 hours count as a single visit (update `durationMs` and `visitedAt`).

---

### 3.11 Get my visitors

```
GET /visits/received?page=1&limit=20
```

**Response `200 OK`:**

```json
{
  "visitors": [
    {
      "visitId": "vis_xyz",
      "visitor": {
        "id": "usr_abc",
        "name": "Rahul M",
        "age": 28,
        "imageUrl": "https://...",
        "city": "Bangalore",
        "religion": "Hindu",
        "occupation": "Doctor",
        "compatibilityScore": 0.68,
        "verified": false
      },
      "visitedAt": "2026-02-23T10:00:00Z",
      "source": "recommended"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 12, "hasMore": false },
  "newCount": 3
}
```

`newCount` = visitors since the user last opened the Visitors tab.

**Free tier:** Shows visitor count + blurred profiles. Premium shows full details.

---

### 3.12 Mark visitors as seen

```
POST /visits/mark-seen
```

Called when user opens the Visitors tab. Resets `newCount` to 0.

**Response `200 OK`:**

```json
{ "markedAt": "2026-02-23T10:01:00Z" }
```

---

## 4. Interest flow

```
User A taps "Interested" on User B's card
            │
            ▼
  POST /interactions/interest
            │
            ├── B already sent interest to A?
            │       │
            │       YES ──► Auto-accept both ──► Create MutualMatch
            │       │                              ──► Create ChatThread
            │       │                              ──► Notify both: "It's a match!"
            │       │
            │       NO ──► Create Interaction(pending)
            │              ──► Notify B: "Someone is interested in you"
            │              ──► Appears in B's Requests tab
            │
            ▼
    B opens Requests tab
            │
            ├── B taps Accept
            │       ──► PATCH /interactions/:id { action: "accept" }
            │       ──► Create MutualMatch + ChatThread
            │       ──► Notify A: "Your interest was accepted!"
            │
            └── B taps Decline
                    ──► PATCH /interactions/:id { action: "decline" }
                    ──► Notify A: "Your interest was declined" (optional, configurable)
```

---

## 5. Priority interest flow

Same as interest flow, but:

1. The interaction has `type: 'priority_interest'`
2. It appears **at the top** of B's requests inbox, above regular interests
3. It includes an optional intro `message` visible to B
4. It is rate-limited per tier (see section 3.2)
5. B sees a visual indicator that this is a priority/boosted request
6. Push notification text is different: "Someone sent you a priority interest!"

---

## 6. Shortlist flow

```
User A taps "Save" on User B's card
            │
            ▼
  POST /shortlist { profileId: B }
            │
            ▼
  B is NOT notified (shortlisting is private)
  A sees B in their Shortlist tab
  A can remove B via DELETE /shortlist/:profileId
```

---

## 7. Profile visit / visitors flow

```
User A taps on User B's profile card (opens full profile)
            │
            ▼
  Frontend calls POST /visits { profileId: B, source: "recommended" }
            │
            ▼
  Backend records the visit (deduplicated per 24h window)
            │
            ▼
  B can see A in their "Visitors" tab: GET /visits/received
  B sees newCount badge on the Visitors tab
  When B opens Visitors tab: POST /visits/mark-seen
```

**Privacy setting:** Users can opt out of appearing in others' visitor lists via:

```
PATCH /profile/me/privacy
```

```json
{
  "showInVisitors": false
}
```

When `showInVisitors: false`, the user's visits are still recorded for analytics but are hidden from the visited profile's visitor list.

---

## 8. Mutual match detection

A mutual match is created when **both** users have expressed interest (or priority interest) in each other. This can happen:

1. **At interest time:** A sends interest → backend checks if B already sent interest to A → if yes, auto-match
2. **At accept time:** B accepts A's pending interest → create match

### On mutual match creation:

1. Create `MutualMatch` record
2. Auto-create a `ChatThread` for the pair
3. Send push notification to both users
4. Update both interactions to `status: 'accepted'`

### Get mutual matches

```
GET /matches?page=1&limit=20
```

**Response `200 OK`:**

```json
{
  "matches": [
    {
      "matchId": "match_abc",
      "matchedAt": "2026-02-23T10:00:00Z",
      "profile": {
        "id": "usr_abc",
        "name": "Priya S",
        "age": 27,
        "imageUrl": "https://...",
        "city": "Mumbai",
        "compatibilityScore": 0.82,
        "verified": true
      },
      "chatThreadId": "thread_123",
      "lastMessage": {
        "text": "Hi! Nice to meet you",
        "sentAt": "2026-02-23T10:05:00Z"
      }
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 8, "hasMore": false }
}
```

### Unmatch

```
DELETE /matches/:matchId
```

Deletes the match and optionally archives the chat thread.

---

## 9. Notifications

| Event | Recipient | Push title | Push body |
|-------|-----------|-----------|-----------|
| Interest received | B | New interest | `{A.name} is interested in your profile` |
| Priority interest received | B | Priority interest! | `{A.name} sent you a priority interest` |
| Interest accepted | A | Interest accepted | `{B.name} accepted your interest!` |
| Interest declined | A | (optional) | `Your interest was not accepted` |
| Mutual match | Both | It's a match! | `You and {other.name} matched!` |
| Profile visited | B | New visitor | `Someone viewed your profile` |

All notifications should include a deep link to the relevant screen (requests tab, match detail, etc.).

Users can configure notification preferences:

```
PATCH /profile/me/notifications
```

```json
{
  "interestReceived": true,
  "priorityInterestReceived": true,
  "interestAccepted": true,
  "interestDeclined": false,
  "mutualMatch": true,
  "profileVisited": true
}
```

---

## 10. Rate limits & abuse prevention

| Action | Free tier | Silver | Gold | Platinum |
|--------|-----------|--------|------|----------|
| Interests per day | 10 | 25 | 50 | Unlimited |
| Priority interests per day | 1 | 3 | 5 | 10 |
| Shortlist capacity | 25 | 100 | 250 | Unlimited |
| View visitors | Count only | Last 5 | Full list | Full list + analytics |

### Cooldown rules

- After declining an interest from User A, A cannot re-send interest to the same user for **30 days**
- After withdrawing an interest, the sender cannot re-send for **7 days**
- Blocked users cannot interact in any way

### Spam detection

Flag accounts that:
- Send 50+ interests in 1 hour
- Get declined by 80%+ of recipients
- Copy-paste the same message to 10+ priority interests

---

## 11. Database schema

### `interactions` table

```sql
CREATE TABLE interactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id    UUID NOT NULL REFERENCES users(id),
  to_user_id      UUID NOT NULL REFERENCES users(id),
  type            VARCHAR(20) NOT NULL CHECK (type IN ('interest', 'priority_interest')),
  status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'accepted', 'declined', 'withdrawn')),
  message         TEXT,
  source          VARCHAR(30),
  compatibility_score DECIMAL(4,3),
  seen_by_recipient BOOLEAN DEFAULT FALSE,
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT unique_active_interest UNIQUE (from_user_id, to_user_id, type)
    WHERE status IN ('pending', 'accepted'),
  CONSTRAINT no_self_interest CHECK (from_user_id != to_user_id)
);

CREATE INDEX idx_interactions_to_user ON interactions(to_user_id, status, created_at DESC);
CREATE INDEX idx_interactions_from_user ON interactions(from_user_id, status, created_at DESC);
```

### `shortlists` table

```sql
CREATE TABLE shortlists (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id),
  profile_id  UUID NOT NULL REFERENCES users(id),
  note        TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT unique_shortlist UNIQUE (user_id, profile_id),
  CONSTRAINT no_self_shortlist CHECK (user_id != profile_id)
);

CREATE INDEX idx_shortlists_user ON shortlists(user_id, created_at DESC);
```

### `profile_visits` table

```sql
CREATE TABLE profile_visits (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visitor_id  UUID NOT NULL REFERENCES users(id),
  profile_id  UUID NOT NULL REFERENCES users(id),
  source      VARCHAR(30),
  duration_ms INTEGER,
  visited_at  TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT no_self_visit CHECK (visitor_id != profile_id)
);

CREATE INDEX idx_visits_profile ON profile_visits(profile_id, visited_at DESC);
CREATE INDEX idx_visits_dedup ON profile_visits(visitor_id, profile_id, visited_at DESC);
```

### `mutual_matches` table

```sql
CREATE TABLE mutual_matches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id       UUID NOT NULL REFERENCES users(id),
  user_b_id       UUID NOT NULL REFERENCES users(id),
  interaction_a_id UUID REFERENCES interactions(id),
  interaction_b_id UUID REFERENCES interactions(id),
  chat_thread_id  UUID,
  matched_at      TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT unique_match UNIQUE (
    LEAST(user_a_id, user_b_id),
    GREATEST(user_a_id, user_b_id)
  )
);

CREATE INDEX idx_matches_user_a ON mutual_matches(user_a_id, matched_at DESC);
CREATE INDEX idx_matches_user_b ON mutual_matches(user_b_id, matched_at DESC);
```

### `visitor_seen_cursor` table

```sql
CREATE TABLE visitor_seen_cursor (
  user_id     UUID PRIMARY KEY REFERENCES users(id),
  last_seen_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 12. Frontend integration notes

### Auto-recording profile visits

The frontend should call `POST /visits` whenever a user opens a full profile screen. This is already wired in `FullProfileScreen` — just needs the API call added:

```dart
// In FullProfileScreen.build(), after profile loads:
ref.read(discoveryRepositoryProvider).sendFeedback(
  candidateId: profile.id,
  action: 'view',
  source: 'recommended',
);
// AND record the visit:
ref.read(visitRepositoryProvider).recordVisit(
  profileId: profile.id,
  source: 'recommended',
);
```

### Visitors tab data source

The "Visitors" tab in the matches screen should call `GET /visits/received` instead of the current nearby endpoint. The frontend currently uses `matchesNearbyProvider` as a placeholder.

### Shortlist tab data source

The Shortlist screen should call `GET /shortlist` to show saved profiles.

### Requests screen data source

The Requests screen should call `GET /interactions/received?status=pending` and show accept/decline actions.

### Action button mapping

| Button | API call |
|--------|----------|
| "Interested" | `POST /interactions/interest` |
| "Priority" | `POST /interactions/priority-interest` |
| "Save" | `POST /shortlist` |
| "Message" | Requires mutual match — show "Express interest first" if no match |

### Quick reference — all endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/interactions/interest` | Express interest |
| `POST` | `/interactions/priority-interest` | Priority interest (boosted) |
| `PATCH` | `/interactions/:id` | Accept or decline interest |
| `DELETE` | `/interactions/:id` | Withdraw pending interest |
| `GET` | `/interactions/received` | Incoming requests inbox |
| `GET` | `/interactions/sent` | Sent interests |
| `POST` | `/shortlist` | Shortlist a profile |
| `DELETE` | `/shortlist/:profileId` | Remove from shortlist |
| `GET` | `/shortlist` | Get shortlisted profiles |
| `POST` | `/visits` | Record a profile visit |
| `GET` | `/visits/received` | Get my visitors |
| `POST` | `/visits/mark-seen` | Mark visitors as seen |
| `GET` | `/matches` | Get mutual matches |
| `DELETE` | `/matches/:matchId` | Unmatch |
| `PATCH` | `/profile/me/privacy` | Privacy settings (showInVisitors) |
| `PATCH` | `/profile/me/notifications` | Notification preferences |
