  # Requests Inbox — Premium Gate & Unlock One

  Frontend shows the requests inbox (Chats → Requests, or main Requests tab). For **non‑premium** users the backend can gate full access and support “watch ad to unlock one” flow.

  ---

  ## 1. GET /interactions/received (free users)

  **Current behaviour:** Some backends return `403` with body:

  ```json
  {
    "code": "PREMIUM_REQUIRED",
    "message": "Only premium users can view the requests inbox"
  }
  ```

  **Required for blurred UI:** Keep returning `403` for non‑premium, but include **count** and **inbox ad-unlock quota** so the app can show that many blurred placeholder cards and show/hide “Watch ad to unlock” (limit **2 per week**):

  ```json
  {
    "code": "PREMIUM_REQUIRED",
    "message": "Only premium users can view the requests inbox",
    "count": 5,
    "inboxUnlocksRemainingThisWeek": 2,
    "inboxUnlocksResetAt": "2026-03-07T00:00:00.000Z"
  }
  ```

  - **`count`** (integer, optional): Number of pending received interactions for this user.  
    Frontend shows that many blurred request cards only when **count > 0**. If omitted or 0, the app shows only the message and Subscribe CTA (no blurred cards).
  - **`inboxUnlocksRemainingThisWeek`** (integer, optional): How many “watch ad to unlock one request” the user has left this week. Backend must enforce **2 unlocks per week**. If omitted, frontend assumes 2.
  - **`inboxUnlocksResetAt`** (ISO 8601 string, optional): When the weekly quota resets. Frontend uses this to show “Unlocks reset next week” when remaining is 0.

  **Optional (later):** Return `200` for free users with a locked preview instead of `403`:

  ```json
  {
    "premiumRequired": true,
    "count": 5,
    "lockedPreview": [
      { "id": "interaction-id-1" },
      { "id": "interaction-id-2" }
    ]
  }
  ```

  - **`lockedPreview`**: Minimal list (e.g. IDs only or minimal fields) so the app could show avatars/names blurred. Not required for the current flow; the app works with `403` + `count` only.

  ---

  ## 2. POST /interactions/received/unlock-one

  After the user watches an ad, the app calls this to “unlock” **one** received interaction and show it (accept/decline).  
  **Backend must enforce a limit of 2 unlocks per user per week.** When the user has already used 2 unlocks this week, return `403` with code `INBOX_UNLOCKS_LIMIT_REACHED` (see Errors below).

  **Request**

  - **Method:** `POST`
  - **Path:** `/interactions/received/unlock-one`
  - **Body:**

  ```json
  {
    "adCompletionToken": "uuid-from-client-after-ad"
  }
  ```

  - **`adCompletionToken`** (string, required): Opaque token from the client after the user completed an ad. Backend can validate it (e.g. with your ad provider or a short‑lived store) to avoid granting unlocks without a real ad view.

  **Response (success, one interaction unlocked)**

  - **Status:** `200`
  - **Body:** One interaction plus **quota** so the app can show remaining unlocks and hide “Watch ad” when 0:

  ```json
  {
    "interaction": {
      "interactionId": "abc123",
      "type": "interest",
      "status": "pending",
      "message": null,
      "createdAt": "2026-02-28T04:38:06.731Z",
      "fromUser": {
        "id": "user-id",
        "name": "Name",
        "age": 30,
        "imageUrl": "https://...",
        "city": "Delhi",
        "religion": "Muslim",
        "occupation": "Lawyer"
      }
    },
    "unlocksRemainingThisWeek": 1,
    "resetsAt": "2026-03-07T00:00:00.000Z"
  }
  ```

  Alternatively you can return an array of one under `interactions` instead of `interaction`; frontend supports both. You must still include **`unlocksRemainingThisWeek`** and **`resetsAt`** so the app can remove the “Watch ad” button when the user has used their 2 unlocks this week. The **`fromUser`** object must include **`imageUrl`** and/or **`photoUrls`** so the app can show the requester’s photo on the card (see BACKEND_LIKES_SECTION.md / BACKEND_API_REFERENCE.md).

  Frontend parses the interaction and quota, shows that one request unblurred with Accept/Decline, and updates the remaining count (e.g. “Watch ad to unlock (1 left this week)” or “Unlocks reset next week” when 0).

  **Response (no request to unlock)**

  - **Status:** `404` or `200` with empty payload:
    - `404` with body `{ "code": "NO_PENDING_REQUESTS", "message": "..." }`, or  
    - `200` with `{ "interaction": null }` or `{ "interactions": [] }`.

  Frontend treats “no item” as “no request to unlock right now” and shows a short message.

  **Errors**

  - **401** Unauthorized
  - **403** — cases:
    - Ad token invalid or already used (any suitable `code`, e.g. `INVALID_TOKEN`).
    - **`INBOX_UNLOCKS_LIMIT_REACHED`**: User has already used their 2 unlocks this week. Body must include `message` and optionally `inboxUnlocksResetAt` (ISO 8601) so the app can show “Unlocks reset next week”. Example: `{ "code": "INBOX_UNLOCKS_LIMIT_REACHED", "message": "You've used all 2 request unlocks this week. Resets next week.", "inboxUnlocksResetAt": "2026-03-07T00:00:00.000Z" }`
  - **404** No pending received interaction to unlock (optional; see above)

  ---

  ## 3. GET /interactions/received/count

  Used for the “Requests” badge. For free users you can:

  - Return **200** with `{ "count": N }` so the badge shows “You have N requests” (recommended), or  
  - Return **403** with the same `PREMIUM_REQUIRED` body (and optional `count`) so the app can still show a badge or fallback.

  Frontend does not require count for the premium gate; it only needs `count` in the **GET /interactions/received** `403` body to decide how many blurred cards to show.

  ---

  ## 4. Frontend wiring summary

  | Scenario | Backend | Frontend |
  |----------|---------|----------|
  | GET /interactions/received (free) | 403 + `code`, `message`, optional `count`, `inboxUnlocksRemainingThisWeek`, `inboxUnlocksResetAt` | Shows premium gate: message, Subscribe CTA, N blurred cards when **count > 0**. “Watch ad to unlock” only when remaining > 0 (2/week); when 0, shows “Unlocks reset next week”. |
  | POST /interactions/received/unlock-one (after ad) | 200 + one interaction + `unlocksRemainingThisWeek`, `resetsAt`; or 403 `INBOX_UNLOCKS_LIMIT_REACHED` when 2/week used | Adds item to “unlocked” list, updates quota; on 403 limit, hides “Watch ad” and shows reset message. |
  | GET /interactions/received (premium) | 200 + full list | Same as today: full list, no gate. |

  ---

  ## 5. Ad token validation (backend)

  - **adCompletionToken** is generated by the app after the user completes an interstitial (e.g. UUID v4).
  - You can either:
    - **Trust the client** for now and allow one unlock per token (store used tokens per user and reject duplicates), or  
    - **Integrate with your ad provider** (e.g. server‑side callback or server‑to‑server verification) and only grant unlock when the ad was verified.

  If you do not implement unlock-one yet, return **501** or **404**; the app will show “No request to unlock right now” and the user can still use Subscribe.

  ---

  ## 6. Database: InboxAdUnlock (or equivalent)

  To enforce the **2 inbox unlocks per week** limit and to avoid **500 INTERNAL_ERROR** when counting used unlocks, ensure the database has a table to track ad-based unlocks (e.g. `InboxAdUnlock`). If your code calls `prisma.inboxAdUnlock.count()` (or similar) before this table exists, the API will return 500 and the app may show "Something went wrong" on the Requests tab or when fetching contact-requests count. Create and run the migration for this table before deploying the inbox unlock feature.
