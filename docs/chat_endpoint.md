# Shubhmilan — Chat API (Backend Endpoints)

Backend specification for **chat threads and messages**. Dating and matrimony use **separate** threads: no mixing. The frontend always passes `mode` (`dating` or `matrimony`) when listing and creating threads.

---

## Base URL & conventions

| Item | Value |
|------|--------|
| **Base URL** | `https://api.saathi.app` (use `http://localhost:3000` for local dev) |
| **Content-Type** | `application/json` for all request and response bodies |
| **Authorization** | `Authorization: Bearer <accessToken>` for all chat endpoints |

### Error responses

Use the standard shape:

```json
{
  "code": "ERROR_CODE",
  "message": "Human-readable message",
  "details": {}
}
```

---

## Core rule: mode (dating vs matrimony)

- **Dating** and **matrimony** chats are **separate**. A thread belongs to exactly one mode.
- **GET /chat/threads** must accept a `mode` query parameter. Return only threads for that mode.
- **POST /chat/threads** must accept a `mode` in the body. Create (or return) a thread for that mode. If a thread already exists for the same user pair and mode, return that thread; otherwise create one.
- The frontend never mixes threads across modes. When the user switches app mode, they see a different thread list.

---

## 1. List threads

```http
GET /chat/threads?limit=50&mode=dating
```

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| limit | number | No | Max threads to return (default 50). |
| cursor | string | No | Pagination cursor for next page. |
| **mode** | string | **Yes** | `"dating"` or `"matrimony"`. Only threads for this mode are returned. |

**Success** `200 OK`

```json
{
  "threads": [
    {
      "id": "thread_abc",
      "otherUserId": "usr_xyz",
      "otherName": "Priya Sharma",
      "lastMessage": "Sure, let's do the coffee spot you mentioned.",
      "lastMessageAt": "2025-03-01T14:30:00Z",
      "unreadCount": 2,
      "mode": "dating"
    }
  ],
  "nextCursor": null
}
```

| Field | Type | Description |
|-------|------|-------------|
| id | string | Thread id (used for messages and read). |
| otherUserId | string | The other participant’s user id. |
| otherName | string | Display name of the other user. |
| lastMessage | string \| null | Preview of last message (or null). |
| lastMessageAt | string \| null | ISO 8601 datetime of last message. |
| unreadCount | number | Unread message count for current user. |
| mode | string | `"dating"` or `"matrimony"`. |

---

## 2. Get or create thread

```http
POST /chat/threads
Content-Type: application/json
```

**Request body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| otherUserId | string | Yes | The other participant’s user id. |
| **mode** | string | **Yes** | `"dating"` or `"matrimony"`. Thread is created for this mode. |

**Example**

```json
{
  "otherUserId": "usr_xyz",
  "mode": "matrimony"
}
```

**Success** `200 OK` or `201 Created`

```json
{
  "id": "thread_abc"
}
```

- If a thread already exists for this user pair and mode, return `200` with that thread’s `id`.
- Otherwise create a new thread for that mode and return `201` with the new `id`.

**Errors**

| HTTP | code | When |
|------|------|------|
| 403 | PREMIUM_REQUIRED | Messaging gated (e.g. free male user). |
| 403 | DAILY_LIMIT | Free tier daily message limit reached. |
| 404 | NOT_FOUND | otherUserId invalid or no profile. |
| 400 | VALIDATION_ERROR | Missing otherUserId or mode. |

---

## 3. Get messages

```http
GET /chat/threads/:threadId/messages?limit=50&cursor=msg_xyz
```

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| limit | number | No | Max messages (default 50). |
| cursor | string | No | Pagination cursor for older messages. |

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

`cursor` is used to load older messages (e.g. “load more” above the list).

---

## 4. Send message

```http
POST /chat/threads/:threadId/messages
Content-Type: application/json
```

**Request body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| text | string | Yes | Message content. |
| adCompletionToken | string | No | Sent by the app after a free user watches an ad; backend can validate and allow one send. |

**When to require an ad (403 AD_REQUIRED)**

- For **free users** (e.g. non‑premium, or when your rules require an ad): you may return **403** with code **AD_REQUIRED** and message e.g. *"Free users must watch an ad to send a message. Send adCompletionToken after the ad completes."* so the app shows the watch‑ad flow and resends with `adCompletionToken`.
- **Exception — matched threads:** If the two users in this thread are **matched** (mutual interest / connection in your system), **do not** require an ad. Allow free users to send messages in that thread **without** `adCompletionToken`. Return 403 AD_REQUIRED only when the user is free **and** the thread is **not** a match thread.  
  So: **matches can message without watching ads.**

**Success** `201 Created` — body either:

- A single **ChatMessage** (same shape as in §3), or  
- A **message request** payload, e.g. `{ "messageRequestId": "...", "threadId": "...", "status": "pending" }`.

If you use a message-request / pending flow (e.g. `messageRequestId`, `status: "pending"`), you **must still** persist the message in the thread and return it from **GET /chat/threads/:threadId/messages** for the **sender** (see below). Otherwise the sender’s thread will show empty after the next fetch.

**Message persistence and who sees messages**

- **Sender side (unmatched or matched):** When you accept a message (with or without `adCompletionToken`), **persist it in this thread** and return it from **GET /chat/threads/:threadId/messages** for the **sender**. The sender must always see their own sent messages in the thread, even if the recipient has not yet accepted the request. This applies whether you return a ChatMessage in the POST body or a `messageRequestId`/`status: "pending"` object — in both cases, **GET .../messages for the sender must include this message**. If the backend does not add the message to the thread, the app will show it optimistically but the next fetch will return an empty list and the thread will look blank for the sender.
- **Recipient side (after accepting):** The thread may exist before the recipient accepts the interest/request (e.g. the sender opened the thread and sent messages). When the **recipient** accepts the interest/request, the **same thread** and **all its messages** must become visible to them so the conversation continues seamlessly. Ensure GET /chat/threads and GET /chat/threads/:threadId/messages for the recipient return this thread and its messages once the request is accepted.

**Errors**

| HTTP | code | When |
|------|------|------|
| 403 | PREMIUM_REQUIRED | User not allowed to send messages. |
| 403 | AD_REQUIRED | Free user sending in a **non‑match** thread without a valid `adCompletionToken`. Do **not** use for match threads. |
| 403 | DAILY_LIMIT | Daily message limit reached. |
| 404 | NOT_FOUND | threadId invalid. |

---

## 5. Mark thread read

```http
POST /chat/threads/:threadId/read
```

**Success** `200 OK` — body optional, e.g. `{}` or `{ "markedAt": "2025-03-01T14:35:00Z" }`.

Called when the user opens the thread so `unreadCount` for that thread can be reset.

---

## 6. DTOs

### ChatThreadSummary (thread list item)

| Field | Type | Description |
|-------|------|-------------|
| id | string | Thread id. |
| otherUserId | string | Other participant’s user id. |
| otherName | string | Display name. |
| lastMessage | string \| null | Last message preview. |
| lastMessageAt | string \| null | ISO 8601 datetime. |
| unreadCount | number | Unread count for current user. |
| mode | string | `"dating"` or `"matrimony"`. |

### ChatMessage

| Field | Type | Description |
|-------|------|-------------|
| id | string | Message id. |
| senderId | string | Author’s user id. |
| text | string | Content. |
| sentAt | string | ISO 8601 datetime. |
| isVoiceNote | boolean | Default false. |

---

## 7. Quick reference

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /chat/threads | Yes | List threads for `mode` (dating or matrimony). |
| POST | /chat/threads | Yes | Get or create thread; body: `otherUserId`, `mode`. |
| GET | /chat/threads/:threadId/messages | Yes | Get messages (paginated). |
| POST | /chat/threads/:threadId/messages | Yes | Send message; body: `text`. |
| POST | /chat/threads/:threadId/read | Yes | Mark thread as read. |

---

## 8. Frontend behaviour (for backend context)

- **Chat list** is always scoped by current app mode. No mixing of dating and matrimony threads.
- **Chat requests** tab in the app shows received interest requests (from the interactions API). Accepting an interest can create a mutual match and a chat thread; the frontend then opens the thread using the `chatThreadId` returned by the interactions API (and may call POST /chat/threads with `otherUserId` + `mode` if needed to ensure a thread exists).
- When opening a thread, the frontend passes `otherUserId` (e.g. as query param) so it can show the other user’s name and profile link without an extra round-trip.

---

*Last updated for mode-separated dating/matrimony chats and Chat list + Chat requests UI.*
