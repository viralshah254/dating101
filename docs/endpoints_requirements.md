# Saathi — Endpoint Requirements (Counts, Priority Message, and Integration)

This document specifies **API requirements** for the features that power nav badges, priority interest with message, and a seamless chat flow. Use it together with [new_endpoints.md](./new_endpoints.md) and [chat_endpoint.md](./chat_endpoint.md).

---

## 1. Counts for navigation badges

The app shows **badge counts** on the bottom nav for:

- **Requests** — number of **pending received** interest/priority-interest requests.
- **Shortlist** — number of **people who shortlisted you** (for the “Shortlisted you” tab).
- **Chats** — **total unread messages** across all threads.

### How the frontend gets counts

| Badge | Source | Backend requirement |
|-------|--------|----------------------|
| **Requests** | **`GET /interactions/received/count?status=pending`** → `{ "count": N }`. | Backend must implement this lightweight endpoint. Full list still from `GET /interactions/received` when the user opens the Requests tab. |
| **Shortlist** | **`GET /shortlist/received/count`** → `{ "count": N }`. | Backend must implement this lightweight endpoint. Full list still from `GET /shortlist/received` when the user opens the Shortlisted you tab. |
| **Chats** | `GET /chat/threads?mode=...` → frontend **sums** `unreadCount` of each thread. | Each thread in the response **must** include **`unreadCount`** (number of unread messages for the current user in that thread). |

### Count endpoints (required for badges)

The frontend uses these for nav badges only; full lists are loaded when the user opens the tab.

```http
GET /interactions/received/count?status=pending
→ { "count": 5 }

GET /shortlist/received/count
→ { "count": 3 }
```

---

## 2. Priority interest with optional message

When a user sends a **priority interest**, the app shows a **popup** to add an optional message, then calls:

```http
POST /interactions/priority-interest
Content-Type: application/json
```

**Request body**

| Field    | Type   | Required | Description                          |
|----------|--------|----------|--------------------------------------|
| toUserId | string | Yes      | Target user id.                      |
| message  | string | No       | Optional intro message from the user. |
| source   | string | No       | e.g. `"recommended"`, `"search"`.   |

**Backend must:**

- Accept and store **`message`** when provided.
- Return it (or expose it) in **GET /interactions/received** so the recipient sees the message (e.g. in the request card and in the Requests/Chat requests tab).
- On **accept**, if a chat thread is created, the backend may optionally post that message as the first message in the thread (so the recipient sees it in chat). If not, the frontend may send it via **POST /chat/threads/:threadId/messages** after opening the thread.

**Response** (unchanged): `201 Created` with `interactionId`, `mutualMatch`, `matchId`, `chatThreadId` (when applicable), `priorityRemaining`.

---

## 3. After priority interest — message icon and chat

- Once the sender has sent a **priority interest**, the match card shows a **Message** icon (instead of the star) so they can open the conversation.
- Tapping **Message** calls **POST /chat/threads** with `otherUserId` and `mode`, then navigates to **GET /chat/threads/:threadId/messages** (see [chat_endpoint.md](./chat_endpoint.md)).
- Backend must support **POST /chat/threads** with `otherUserId` and `mode`; create or return existing thread; return `id` so the frontend can open that thread.

---

## 4. Checklist for backend

| # | Requirement | Endpoint / behaviour |
|---|-------------|----------------------|
| 1 | Requests badge count | **`GET /interactions/received/count?status=pending`** returning `{ "count": N }`. |
| 2 | Shortlist badge count | **`GET /shortlist/received/count`** returning `{ "count": N }`. |
| 3 | Chats unread badge | `GET /chat/threads` includes **`unreadCount`** per thread; frontend sums them. |
| 4 | Priority interest message | `POST /interactions/priority-interest` accepts optional **`message`**; store and expose in GET received (and optionally as first chat message on accept). |
| 5 | Create thread for message | `POST /chat/threads` with `otherUserId` and `mode`; return `id` for navigation. |

---

## 5. Related docs

- [new_endpoints.md](./new_endpoints.md) — full list of endpoints.
- [chat_endpoint.md](./chat_endpoint.md) — chat threads and messages (mode, unreadCount).
- [BACKEND_INTERACTIONS_AND_VISITORS.md](./BACKEND_INTERACTIONS_AND_VISITORS.md) — interactions and shortlist behaviour in detail.
