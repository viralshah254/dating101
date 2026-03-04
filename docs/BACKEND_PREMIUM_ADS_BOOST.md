# Backend: Premium vs Free, Ads, Message Requests, Boost

This document specifies backend APIs and behavior for:

- **Premium vs Free** feature gating (including priority interests, messaging, shortlist, requests)
- **Ad-gated actions** (free users watch ad to unlock one-off actions)
- **Message requests** (free users’ messages go to “requests”; premium goes direct)
- **Profile boost** (purchasable; profile shown on top during peak hours)
- **User badge** (expose `isPremium` on profile/summary for UI badge)

---

## 1. Premium vs Free — Summary

| Feature | Free | Premium |
|--------|------|--------|
| **Priority interests** | 0/day by default; **watch ad** to send one (or subscribe) | **10/day** |
| **Messaging** | Watch ad → send as **message request** (recipient must accept to chat) | Send as **normal message** (no request step) |
| **Shortlist “Shortlisted you”** | Cannot see who shortlisted you | Can see who shortlisted you |
| **View requests (inbox)** | Cannot see requests list | Can see requests list |
| **Per-request view/accept** | N/A (no access to requests) | Can view & respond; **watch ad** once per request (except phone number) before viewing/accepting |
| **Profile boost** | No | Can **purchase** boosts; profile boosted 1 hr/day during peak, shown on top |
| **Badge** | Shown as “Free” on profile | Shown as “Premium” on profile |

---

## 2. Subscription & Entitlements (extended)

### 2.1 GET /subscription/me

**Success** `200 OK` — existing shape. No change.

```json
{
  "tier": "none",
  "expiresAt": null,
  "isActive": false
}
```

- `tier`: `"none"` | `"premium"`
- Backend must ensure profile/summary responses include **isPremium** derived from this (see §6).

---

### 2.2 GET /subscription/entitlements (extended)

**Success** `200 OK` — extend response with the following fields.

**Existing** (keep as-is where already defined):

- `tier`, `gender`, `canSendMessage`, `canSeeWhoLikedYou`, `canSeeWhoShortlistedYou`, `dailyInterestLimit`, `dailyMessageLimit`, `hasPriorityDiscovery`, `canSuperlike`, etc.

**New / updated fields:**

| Field | Type | Description |
|-------|------|-------------|
| `dailyPriorityInterestLimit` | number | **10** for premium; **0** for free (free can still send via ad — see §3). |
| `canSendMessageDirect` | boolean | If true, messages go to **normal chat** (no request). Premium only. |
| `canSeeRequestsInbox` | boolean | If true, user can see the “Requests” (received) list. Premium only. |
| `canSeeWhoShortlistedYou` | boolean | Already exists; “Shortlisted you” tab is premium-only. |
| `requiresAdPerRequestToView` | boolean | If true, user must “watch ad” (backend receives ad token) once per request before viewing/accepting that request. Typically true for premium when viewing contact/photo-view requests (phone number can be excluded per product). |

**Example extended response (premium):**

```json
{
  "tier": "premium",
  "gender": "male",
  "canSendMessage": true,
  "canSendMessageDirect": true,
  "canSeeWhoShortlistedYou": true,
  "canSeeRequestsInbox": true,
  "requiresAdPerRequestToView": true,
  "dailyInterestLimit": 999,
  "dailyMessageLimit": 999,
  "dailyPriorityInterestLimit": 10,
  "hasPriorityDiscovery": true,
  "canBoostProfile": true
}
```

**Example (free):**

```json
{
  "tier": "none",
  "gender": "male",
  "canSendMessage": false,
  "canSendMessageDirect": false,
  "canSeeWhoShortlistedYou": false,
  "canSeeRequestsInbox": false,
  "dailyInterestLimit": 10,
  "dailyMessageLimit": 0,
  "dailyPriorityInterestLimit": 0
}
```

---

## 3. Priority interests (daily limit + ad unlock)

- **Premium:** **10** priority interests per day. Backend decrements and returns `priorityRemaining` in response.
- **Free:** **0** by default. Free users are not limited by recipient — each time they “watch an ad” they get **one** more priority interest; backend accepts an **ad completion token** per send (one send per valid token, including another to the same user).

### 3.1 POST /interactions/priority-interest (existing, extended)

**Request body (existing + optional):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| toUserId | string | Yes | Target user ID |
| message | string | No | Optional message |
| source | string | No | e.g. `"discovery"`, `"shortlist"` |
| **adCompletionToken** | string | No | If present, client claims user watched an ad; backend allows **one** priority interest for free users when this is valid. |

**Backend logic:**

- If user is premium: use daily cap (e.g. 10/day); decrement and return `priorityRemaining`.
- If user is free and **no** `adCompletionToken`: respond **403** with code `PREMIUM_OR_AD_REQUIRED` (or similar).
- If user is free **with** valid `adCompletionToken`: allow this one send (even if they already sent priority interest to this recipient before); mark token as used; return success and e.g. `priorityRemaining: 0` for free. Do not return `ALREADY_SENT` when a new ad token is provided — each ad grants one more send.

**Response:** Existing shape; include `priorityRemaining` (daily remaining for premium; 0 for free after ad use).

---

## 4. Messaging: direct vs message request

- **Premium:** Sending a message creates a **normal** chat message; recipient sees it in Chats.
- **Free:** Sending a message creates a **message request**; recipient sees it in “Requests” (or “Chat requests”) and must **accept** before messages go to normal chat.

Backend must:

1. Know whether the **sender** is premium (subscription state).
2. If premium → create message in thread as today (no request).
3. If free → create a **message request** for that thread/recipient; optionally require **adCompletionToken** in the send-message call so free users can only send after watching an ad.

### 4.1 POST /chat/threads/:threadId/messages (extended)

**Request body (existing + optional):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| text | string | Yes | Message text |
| **adCompletionToken** | string | No | Required for **free** users; client sends after user watches ad. Ignored for premium. |

**App flow:** Free users can tap "Message" after sending priority interest; they see "Watch ad or Subscribe". If they watch an ad, the app creates the thread (POST /chat/threads), opens the chat screen, and sends the first message with the same `adCompletionToken` so the backend accepts it as a message request.

**Backend:**

- If sender is **premium:** create message in thread; return 200.
- If sender is **free:**  
  - If `adCompletionToken` missing or invalid → **403** `AD_REQUIRED` (or `PREMIUM_OR_AD_REQUIRED`).  
  - If valid → create **message request** (see §4.2); recipient sees it in requests and can accept to move to normal chat.

### 4.2 Message requests (inbox)

- **List:** Endpoint for “message requests” (e.g. **GET /chat/message-requests** or include in existing requests/inbox). Returns list of pending message requests (sender, threadId, preview, time).
- **Accept:** **POST /chat/message-requests/:id/accept** (or similar). Moves thread to normal chat for both users.
- **Decline:** **POST /chat/message-requests/:id/decline**. Optional.

Only users with **canSeeRequestsInbox** (premium) can call the list endpoint. Free users do not see the requests list (they only send into it).

---

## 5. View requests (inbox) + ad per request

- **Who can see requests:** Only premium (`canSeeRequestsInbox`).
- **Per-request behavior:** For each request (e.g. contact request, photo-view request, or interest), before the recipient can **view full details** and **accept**, they must complete one “ad view” (backend receives token once per request).

**Suggested:**

- **POST /requests/:requestId/unlock** (or **POST /contact-requests/:id/unlock**, etc.)  
  Body: `{ "adCompletionToken": "..." }`  
  Response: 200 and full request payload (or flag `unlocked: true`).  
  Backend stores that this user has “unlocked” this request (so no repeat ad for same request).

- **Accept/decline** endpoints (existing) may require request to be “unlocked” first, or you can allow accept only after unlock.

**Phone number:** Product may allow showing phone number without ad; backend can have a separate flag or endpoint so that only “view contact (phone)” is exempt.

---

## 6. Profile boost

- Users can **purchase** boosts (IAP or in-app product).
- One boost = profile is **boosted for 1 hour per day during peak hours** (e.g. 18:00–22:00 local or server TZ) and shown **on top** of discovery/list.
- Multiple boosts can stack (e.g. 3 boosts = 3 hours per day for N days, or 1 hour for 3 days — define product rules).

### 6.1 Boost state

- **GET /boost/me** (or include in **GET /subscription/me**):  
  Returns e.g. `{ "activeUntil": "ISO8601", "hoursRemainingToday": 1, "peakWindowStart": "18:00", "peakWindowEnd": "22:00" }`.

- **POST /boost/purchase**  
  Body: `{ "platform": "ios"|"android", "receiptOrToken": "...", "productId": "boost_1h" }`  
  Response: updated boost state.

### 6.2 Discovery sort

- **GET /discovery/recommended** (and any list endpoints that feed the main stack):  
  Accept optional **sort** or default: **boosted first** (users currently in boost window), then by your existing relevance/recency.  
  So: `sort=default` → boosted profiles first, then rest.

---

## 7. User badge (isPremium)

So the app can show “Premium” or “Free” badge on profiles:

- **GET /profile/:userId** and **GET /profile/:userId/summary** must include **isPremium** (boolean) for the **profile owner** (not the viewer).  
  Derive from subscription tier: `tier === 'premium' && isActive`.

- **GET /discovery/recommended** and any list endpoints that return profile summaries must include **isPremium** in each profile/summary object.

**Example (summary):**

```json
{
  "id": "usr_abc",
  "name": "Jane",
  "age": 28,
  "isPremium": true,
  ...
}
```

---

## 8. Ad completion token (server-side)

Client will call “watch ad” (e.g. Google AdMob rewarded/interstitial); on completion, client sends an **opaque token** to the backend. Options:

1. **Client-generated:** App generates a UUID after ad completion and sends it. Backend stores “used” tokens (per user, per action type, per day) and rejects duplicates. No need for server–ad-network communication.
2. **Server-validated:** If you integrate server-side with the ad network, token could be a signed receipt from the ad SDK; backend verifies and marks used.

For MVP, (1) is enough: **adCompletionToken** = UUID from client; backend allows one use per token per user per action (e.g. one priority interest, one message send, one request unlock).

---

## 9. Error codes (summary)

| Code | When |
|------|------|
| `PREMIUM_REQUIRED` | Action requires premium (e.g. see shortlist, see requests). |
| `AD_REQUIRED` | Free user must watch ad and send `adCompletionToken`. |
| `PREMIUM_OR_AD_REQUIRED` | Free user can do action after ad (e.g. priority interest). |
| `DAILY_LIMIT` | Daily cap reached (e.g. priority interest 10/day for premium). |
| `INVALID_AD_TOKEN` | `adCompletionToken` missing, already used, or invalid. |

---

## 10. Checklist for backend

- [ ] Extend **GET /subscription/entitlements** with `dailyPriorityInterestLimit`, `canSendMessageDirect`, `canSeeRequestsInbox`, `requiresAdPerRequestToView`.
- [ ] **POST /interactions/priority-interest** accepts optional `adCompletionToken`; free user allowed one send when token valid.
- [ ] **POST /chat/threads/:threadId/messages** accepts optional `adCompletionToken`; free sender creates message request and requires valid token.
- [ ] Message-request list and accept/decline endpoints (e.g. **GET /chat/message-requests**, **POST .../accept**, **POST .../decline**).
- [ ] Request unlock: e.g. **POST /requests/:requestId/unlock** with `adCompletionToken`; record unlock per user/request.
- [ ] **GET /boost/me**, **POST /boost/purchase**; discovery sort puts boosted users first during peak window.
- [ ] **isPremium** on **GET /profile/:id**, **GET /profile/:id/summary**, and on every profile/summary in discovery and list APIs.

Once these are implemented, the app can wire premium/ free logic, ads, message requests, and boost as described in the product spec.
