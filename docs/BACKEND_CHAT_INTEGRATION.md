# Backend integration: Chat (connect the app)

Use this doc together with **[chat_endpoint.md](./chat_endpoint.md)** to wire your backend so the Saathi app’s chat works end‑to‑end.

---

## 1. Endpoints the app calls

| Method | Path | When the app calls it | Notes |
|--------|------|------------------------|--------|
| **GET** | `/chat/threads?limit=50&mode=dating` or `mode=matrimony` | Chats list screen; after opening/leaving a thread | **Must return `unreadCount` per thread.** |
| **POST** | `/chat/threads` | When user taps “Message” (create or get thread) | Body: `{ "otherUserId": "usr_xxx", "mode": "dating" \| "matrimony" }`. Return `{ "id": "thread_yyy" }`. |
| **GET** | `/chat/threads/:threadId/messages?limit=50` | When user opens a thread; after sending a message | Return `{ "messages": [ ... ], "nextCursor": null }`. |
| **POST** | `/chat/threads/:threadId/messages` | When user sends a message | Body: `{ "text": "..." }`. Can return **403 PREMIUM_REQUIRED** to gate messaging. |
| **POST** | `/chat/threads/:threadId/read` | When user **opens** the thread (once per open) | **Critical:** after this, next **GET /chat/threads** must return that thread with **`unreadCount: 0`** (so the badge and list count update). |

---

## 2. Response shapes the app expects

### GET /chat/threads

- **Response:** `{ "threads": [ ... ], "nextCursor": null }`
- **Each thread** must include:
  - `id` (string) — thread id
  - `otherUserId` (string) — other participant’s user id
  - `otherName` (string) — display name for list/header
  - `lastMessage` (string | null) — last message preview
  - `lastMessageAt` (string | null) — ISO 8601
  - **`unreadCount` (number)** — **must be 0 for a thread after the user has opened it** (see §3).
  - `mode` (string, optional)

The app also accepts snake_case equivalents (e.g. `other_user_id`, `unread_count`, `last_message_at`).

### GET /chat/threads/:threadId/messages

- **Response:** `{ "messages": [ ... ], "nextCursor": null }`
- **Each message:** `id`, `senderId`, `text`, `sentAt` (ISO 8601), `isVoiceNote` (optional, default false).  
  The app also accepts `sender_id`, `createdAt` / `timestamp`, `content` instead of `text`.

### POST /chat/threads/:threadId/messages

- **Request:** `{ "text": "..." }`
- **Success:** 201 with created message (same shape as above) or empty body; the app refetches messages.
- **403 PREMIUM_REQUIRED:** App shows “Messaging requires premium” and an Upgrade action; no crash.

---

## 3. Mark as read and unread count (must work together)

1. User opens a thread → app calls **POST /chat/threads/:threadId/read** (no body).
2. Your backend must mark that thread as “read” for the current user so that:
3. The **next GET /chat/threads** returns that thread with **`unreadCount: 0`**.

If `unreadCount` is not set to 0 after read, the chat list and the Chats tab badge will not clear. The app refetches the thread list when the user leaves the thread, so the backend only needs to persist read state and return the updated count.

---

## 4. Profile summary for chat UI (photo, name, compatibility)

The **chat list** and **thread header** show the other user’s **photo**, **name**, and **compatibility score** by calling:

- **GET** `/profile/:userId/summary`  
  with `userId = otherUserId` from the thread.

So for chat to look correct, your backend must expose a **profile summary** for the other participant (e.g. `GET /profile/:userId/summary`) that returns at least:

- `name`, `imageUrl` (or first photo URL), and optionally `compatibilityScore` (0–1), `city`, etc.

If this endpoint is missing or returns 404, the app falls back to initials and “Chat” / “Active now” only.

---

## 5. Full spec and error codes

- **Full request/response and DTOs:** [chat_endpoint.md](./chat_endpoint.md)
- **Auth:** All requests use `Authorization: Bearer <accessToken>`.
- **Content-Type:** `application/json` for bodies.
- **Errors:** `{ "code": "PREMIUM_REQUIRED", "message": "Messaging requires premium" }` (and similar) so the app can show the right message and Upgrade.

---

## 6. Quick checklist for backend

- [ ] **GET /chat/threads** accepts `mode` (dating | matrimony) and returns `threads[]` with **`unreadCount`** per thread.
- [ ] **POST /chat/threads** accepts `otherUserId` + `mode`, returns existing or new thread `id`.
- [ ] **GET /chat/threads/:threadId/messages** returns `messages[]` (id, senderId, text, sentAt, isVoiceNote).
- [ ] **POST /chat/threads/:threadId/messages** accepts `text`; returns 201 or 403 PREMIUM_REQUIRED.
- [ ] **POST /chat/threads/:threadId/read** marks the thread read for the current user. The client may send an empty JSON body `{}`; the backend must accept it (do not require a non-empty body when `Content-Type: application/json` is set).
- [ ] **Next GET /chat/threads** after read returns that thread with **`unreadCount: 0`**.
- [ ] **GET /profile/:userId/summary** (or equivalent) returns name and photo (and optionally compatibility) for the other user so the chat list and header show photo and score.

Once these are in place, the app’s chat list, thread screen, send message, read state, and unread counts will connect correctly.
