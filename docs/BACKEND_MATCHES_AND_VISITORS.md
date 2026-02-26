# Saathi — Matches & Visitors: Backend Contract

Backend behaviour for **mutual matches** (Matches tab) and **visitors** (mark-seen). Implemented per this contract.

**Related:** [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) (Matches, Visitors), [BACKEND_INTERACTIONS_AND_VISITORS.md](./BACKEND_INTERACTIONS_AND_VISITORS.md).

---

## 1. Mutual match definition

A **mutual match** exists when **both users have expressed interest in each other**. Either type counts:

- **Interest** — `POST /interactions/interest`
- **Priority interest** — `POST /interactions/priority-interest`

So a match is created when:

- User A has sent **interest or priority interest** to User B, **and**
- User B has sent **interest or priority interest** to User A (in either order, or via **accept**).

**Backend behaviour (implemented):**

1. When **A expresses interest** to B: if B has already expressed interest (or priority) to A → create **MutualMatch**, create **ChatThread**, return `mutualMatch: true`, `matchId`, `chatThreadId`.
2. When **A expresses priority interest** to B: same check; if B has already expressed interest (or priority) to A → create match and thread, return `mutualMatch: true`, `matchId`, `chatThreadId`.
3. When **B accepts A's interest** → create match and thread if not already created, return `mutualMatch: true`, `matchId`, `chatThreadId`.
4. **GET /matches** returns only these mutual matches (both have expressed interest in each other).

---

## 2. GET /matches — Response shape

```http
GET /matches?page=1&limit=20
Authorization: Bearer <accessToken>
```

**Success** `200 OK`:

```json
{
  "matches": [
    {
      "matchId": "match_abc",
      "matchedAt": "2026-02-23T10:00:00Z",
      "profile": {
        "id": "usr_def",
        "name": "Priya S",
        "age": 27,
        "city": "Mumbai",
        "imageUrl": "https://...",
        "matchReasons": ["Lives in Mumbai", "Same religion — Hindu"]
      },
      "chatThreadId": "thread_xyz",
      "lastMessage": "Hi!",
      "lastMessageAt": "2026-02-23T10:05:00Z"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 5, "hasMore": false }
}
```

- **matches** — Mutual matches only.
- **profile** — Other user's summary with **matchReasons** (array) for "Why matched" chips.
- **chatThreadId** — For opening the thread when the user taps "Message".
- **lastMessage** / **lastMessageAt** — Last message text and timestamp (optional preview).

---

## 3. POST /visits/mark-seen — Empty body

The backend **accepts**:

- No body, or
- Body `{}`

when `Content-Type: application/json` is set. It does **not** return 400/500 for "body cannot be empty".

**Response** `200 OK`:

```json
{ "markedAt": "2026-02-23T10:01:00Z" }
```

After this, **GET /visits/received** for that user returns **`newCount: 0`** (or the count reflects "seen" visitors).

**Implementation:** Global JSON parser treats empty body as `{}`; route does not require a body.

---

## 4. Checklist (backend)

| Item | Status |
|------|--------|
| Mutual match on interest when reverse exists | ✅ |
| Mutual match on **priority interest** when reverse exists | ✅ |
| Mutual match on **accept** (create match + thread) | ✅ |
| GET /matches: profile with matchReasons, chatThreadId, lastMessage, lastMessageAt | ✅ |
| POST /visits/mark-seen: accept no body or `{}`, return 200 + markedAt | ✅ |

---

## 5. Frontend connection (app → endpoints)

The app is wired to these endpoints as follows.

| Endpoint | App usage |
|----------|-----------|
| **GET /matches** | `MatchesRepository.getMatches()` → **ApiMatchesRepository** (`lib/data/repositories_api/api_matches_repository.dart`). Used by **mutualMatchesProvider** (`lib/features/matches/providers/matches_providers.dart`). Matches tab and matched-user IDs (to exclude from Explore) read from this provider. |
| **DELETE /matches/:matchId** | `MatchesRepository.unmatch(matchId)` → **ApiMatchesRepository**. Unmatch action from Matches tab. |
| **GET /visits/received** | `VisitsRepository.getVisitors()` → **ApiVisitsRepository** (`lib/data/repositories_api/api_visits_repository.dart`). Used by **visitorsProvider** (matches_providers.dart). Visitors tab content. |
| **POST /visits/mark-seen** | `VisitsRepository.markVisitorsSeen()` → **ApiVisitsRepository**. Called after fetching visitors (e.g. when user opens Visitors tab). Sends body `{}` so backend accepts the request. |

**Repository selection:** In `lib/core/providers/repository_providers.dart`, `matchesRepositoryProvider` and `visitsRepositoryProvider` use **ApiMatchesRepository** / **ApiVisitsRepository** when not using the fake backend (`useFakeBackend: false`).
