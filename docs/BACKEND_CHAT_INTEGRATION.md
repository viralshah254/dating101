# Backend integration: Chat (connect the app)

Use this doc together with **[chat_endpoint.md](./chat_endpoint.md)** to wire your backend so the Shubhmilan app’s chat works end‑to‑end.

---

## 1. Endpoints the app calls

| Method | Path | When the app calls it | Notes |
|--------|------|------------------------|--------|
| **GET** | `/chat/threads?limit=50&mode=dating` or `mode=matrimony` | Chats list screen; after opening/leaving a thread | **Must return `unreadCount` per thread.** |
| **POST** | `/chat/threads` | When user taps “Message” (create or get thread) | Body: `{ "otherUserId": "usr_xxx", "mode": "dating" \| "matrimony" }`. Return `{ "id": "thread_yyy" }`. |
| **GET** | `/chat/threads/:threadId/messages?limit=50` | When user opens a thread; after sending a message | Return `{ "messages": [ ... ], "nextCursor": null }`. |
| **POST** | `/chat/threads/:threadId/messages` | When user sends a message | Body: `{ "text": "..." }`; optional `adCompletionToken` after free user watches ad. **Match threads: do not require ad** — see §5. |
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

- **Request:** `{ "text": "..." }`; optional **`adCompletionToken`** when the user has just watched an ad (free users, non‑match threads).
- **Success:** 201 with created message (same shape as above) or empty body; the app refetches messages.
- **403 PREMIUM_REQUIRED:** App shows “Messaging requires premium” and an Upgrade action; no crash.
- **403 AD_REQUIRED:** App shows watch‑ad flow and resends with `adCompletionToken`. Use only for **non‑match** threads; see §5.

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

## 5. Match threads: no ad required

For **POST /chat/threads/:threadId/messages**:

- If the two participants are **matched** (mutual interest / connection in your backend), **do not** return 403 AD_REQUIRED. Allow free users to send messages in that thread without `adCompletionToken`.
- Return **403 AD_REQUIRED** (and require `adCompletionToken`) only when the user is free **and** the thread is **not** a match thread (e.g. cold outreach or pre‑match).

So: **matches should not have to watch ads** to send messages. The app already skips showing the ad when the other user is a match; the backend must allow the request without `adCompletionToken` for match threads.

---

## 5a. Send message from profile (dating) — message requests & 5/day ad limit

When a user taps **Message** on a dating profile (full profile screen):

- **Premium users:** App calls **POST /chat/threads** with `otherUserId` and `mode: "dating"`, then opens the thread. No ad.
- **Free users:** App shows a gate: “Watch ad to send message (up to 5 per day)” or “Upgrade to Premium”. If they tap **Watch ad**, the app plays an interstitial, then ensures interest is sent (POST /interactions/interest if not already), then **POST /chat/threads** with `otherUserId` and `mode: "dating"`, then opens the thread with an **initialAdToken** in the URL. The **first message** sent in that thread is submitted with **`adCompletionToken`** in **POST /chat/threads/:threadId/messages**. The backend should treat that as a **message request** (dating) for the recipient, not as a direct chat, until they accept.

**Backend requirements:**

1. **POST /chat/threads**  
   - Body: `{ "otherUserId": "...", "mode": "dating" }`.  
   - For free users the app may call this **after** they watch an ad; the thread is created so they can type. The actual “send” happens on **POST /chat/threads/:threadId/messages** with `adCompletionToken`.

2. **POST /chat/threads/:threadId/messages**  
   - When a **free** user sends the **first** message in a **non-match** thread (e.g. from profile), the app sends **`adCompletionToken`** in the body.  
   - Backend should:  
     - Enforce **max 5 such “ad-send” messages per user per day** for dating (e.g. by counting sends that included `adCompletionToken` in the last 24h).  
     - If over limit, return **403** with code **`DAILY_MESSAGE_AD_LIMIT_REACHED`** and a message like “You've used your 5 free message sends today.”  
     - Otherwise, accept the message and create/store it as a **message request** (dating) for the recipient so it appears in their **message requests** (e.g. GET /chat/message-requests or equivalent for dating).  
   - **Match threads:** Do **not** require `adCompletionToken` and do **not** count toward the 5/day limit; allow sends as in §5.

3. **Message requests (dating)**  
   - Messages sent by free users via ad (with `adCompletionToken`) should appear on the **recipient’s** side as **inbound** message requests (dating), and on the **sender’s** side as **outbound** message requests.  
   - **GET /chat/message-requests?mode=dating** (or `mode=matrimony`) must return both inbound and outbound requests. Each item should include **`isInbound`** (boolean) or **`direction`** (`"inbound"` | `"outbound"`) so the app can sort **inbound requests on top**.  
   - **GET /chat/message-requests/count?mode=dating** must return the **count of inbound** message requests for the current user (for recipient badge). Response: `{ "count": number }`.  
   - **Accept** / **decline** (e.g. **POST /chat/message-requests/:id/accept** and **decline**) so the recipient can move the thread to the main chat list or dismiss it.

**App flow (watch ad to message)**  
- When a free user taps “Watch ad to send message” on a profile, the app **likes the profile automatically** (POST /interactions/interest if not already sent), then creates the thread (POST /chat/threads) and **opens the chat screen** with an initial ad token. The first message they send uses `adCompletionToken` and becomes an **outbound message request** for the sender and **inbound** for the recipient.  
- **Ordering:** When listing message requests, **inbound must appear before outbound** (app sorts by `isInbound` / `direction`).

**Summary**

| Scenario | Backend behavior |
|----------|------------------|
| Free user sends first message from profile (with `adCompletionToken`) | Count toward 5/day; store as message request (dating) for recipient; sender sees outbound, recipient sees inbound. |
| Same user has already sent 5 such messages today | Return 403 `DAILY_MESSAGE_AD_LIMIT_REACHED`. |
| Premium user sends from profile | No `adCompletionToken`; allow send (direct or message request per your product rules). |
| Match thread (mutual interest) | Do not require `adCompletionToken`; do not count toward 5/day. |
| GET /chat/message-requests | Return list with `isInbound` or `direction`; GET /chat/message-requests/count returns inbound count for recipient badge. |

---

## 6. Full spec and error codes

- **Full request/response and DTOs:** [chat_endpoint.md](./chat_endpoint.md)
- **Auth:** All requests use `Authorization: Bearer <accessToken>`.
- **Content-Type:** `application/json` for bodies.
- **Errors:** `{ "code": "PREMIUM_REQUIRED", "message": "Messaging requires premium" }` (and similar) so the app can show the right message and Upgrade.

---

## 7. Quick checklist for backend

- [ ] **GET /chat/threads** accepts `mode` (dating | matrimony) and returns `threads[]` with **`unreadCount`** per thread.
- [ ] **POST /chat/threads** accepts `otherUserId` + `mode`, returns existing or new thread `id`.
- [ ] **GET /chat/threads/:threadId/messages** returns `messages[]` (id, senderId, text, sentAt, isVoiceNote).
- [ ] **POST /chat/threads/:threadId/messages** accepts `text` and optional `adCompletionToken`; returns 201, or 403 PREMIUM_REQUIRED / AD_REQUIRED. **For match threads, do not require ad** — allow send without token.
- [ ] **POST /chat/threads/:threadId/read** marks the thread read for the current user. The client may send an empty JSON body `{}`; the backend must accept it (do not require a non-empty body when `Content-Type: application/json` is set).
- [ ] **Next GET /chat/threads** after read returns that thread with **`unreadCount: 0`**.
- [ ] **GET /profile/:userId/summary** (or equivalent) returns name and photo (and optionally compatibility) for the other user so the chat list and header show photo and score.

Once these are in place, the app’s chat list, thread screen, send message, read state, and unread counts will connect correctly.
