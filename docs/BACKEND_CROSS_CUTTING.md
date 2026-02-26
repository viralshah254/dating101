# Backend: Cross-cutting features

This document specifies backend contracts for **notifications**, **privacy**, **account**, **profile boost**, **referral**, **deep links**, and **chat icebreakers**. The Flutter app implements the corresponding UI; the backend must support these endpoints and behaviours for full integration.

---

## 1. Notifications and engagement

### 1.1 Notification settings UI

The app has a **Notification preferences** screen (Profile & Settings → Notifications) where users turn on/off categories:

| Preference key | Description |
|----------------|-------------|
| `interestReceived` | New interest received |
| `priorityInterestReceived` | Priority interest received |
| `interestAccepted` | Someone accepted your interest |
| `interestDeclined` | Someone declined your interest |
| `mutualMatch` | New mutual match |
| `profileVisited` | Someone viewed your profile |
| `newMessage` | New chat message |

**Backend:**

- **PATCH /profile/me/notifications** — Update preferences. Body: `{ "interestReceived": true, "newMessage": true, ... }`. Returns updated flags. See [BACKEND_API_REFERENCE.md §6c.2](BACKEND_API_REFERENCE.md#6c-profile-privacy--notifications).
- **GET /profile/me/notifications** (recommended) — Return current notification preferences so the app can pre-fill the settings screen. Response shape same as PATCH response, e.g. `{ "interestReceived": true, "priorityInterestReceived": true, ... }`. If not implemented, the app uses default values when opening the sheet.

FCM token registration: **POST /profile/me/fcm-token** (body: `{ "fcmToken": "..." }`). See [BACKEND_PUSH_NOTIFICATIONS.md](BACKEND_PUSH_NOTIFICATIONS.md).

### 1.2 Deep links

When the user **taps a push notification**, the app must open the right screen and, for shell routes, the **correct tab**.

| Intent | Path | Backend `data` suggestion |
|--------|------|---------------------------|
| Chat thread | `/chat/:threadId` | `type: "new_message"`, `threadId`, `otherUserId` |
| Chats list | `/chats` | `screen: "chats"` |
| Requests | `/community` | `screen: "requests"` |
| Matches | `/` | `screen: "matches"` |
| Profile | `/profile/:id` | `profileId` |
| Shortlist | `/community` (or shortlist tab) | `screen: "shortlist"` (if supported) |
| Visitors | `/community` | `screen: "visitors"` |

Backend must send **data** (and optionally **notification**) in the FCM payload so the client can build the path. The app uses `notificationDataToPath()` to map `data` → path, then navigates (and when path is `/chats`, `/community`, `/`, `/profile-settings`, the shell switches to the matching branch). See [BACKEND_PUSH_NOTIFICATIONS.md §4](BACKEND_PUSH_NOTIFICATIONS.md#4-fcm-payload-format).

---

## 2. Safety and privacy

### 2.1 Block & report

- **Block:** POST /safety/block — body: `blockedUserId`, `reason`, `source?`. Reason codes: `spam`, `harassment`, `inappropriate_content`, `fake_profile`, `other`.
- **Report:** POST /safety/report — body: `reportedUserId`, `reason`, `details?`, `source?`. Reason codes: `spam`, `harassment`, `inappropriate_photos`, `fake_profile`, `scam`, `other`.
- **Blocked list:** GET /safety/blocked — list blocked users with minimal profile.
- **Unblock:** DELETE /safety/blocked/:userId.

Full contract: [BACKEND_SECURITY_BLOCK_REPORT.md](BACKEND_SECURITY_BLOCK_REPORT.md). The app exposes Block and Report from the **profile menu** (full profile) and **chat thread** (header menu).

After block, the app shows “Blocked” and the user can **Unblock** from Settings → Privacy & safety → Blocked users.

### 2.2 Privacy controls

The app needs:

1. **Who can see my profile**  
   - `everyone` — visible in discovery to all.  
   - `only_matches` — only mutual matches can see full profile.  
   - `only_after_interest` — visible after at least one interest (sent or received).

2. **Hide from discovery**  
   - Boolean: when `true`, profile is excluded from discovery/recommended/explore (and optionally from search). Reversible (e.g. “Pause my profile” / “Hide from discovery temporarily”).

**Backend (to implement):**

| Method | Path | Description |
|--------|------|-------------|
| PATCH | /profile/me/privacy | Extend body to accept `profileVisibility?: "everyone" \| "only_matches" \| "only_after_interest"` and `hideFromDiscovery?: boolean`. Return updated values. |

Current behaviour: app already sends `showInVisitors` via PATCH /profile/me/privacy. Add the above fields to the same endpoint and response.

**Response shape (example):**

```json
{
  "showInVisitors": true,
  "profileVisibility": "everyone",
  "hideFromDiscovery": false
}
```

**GET /profile/me** (or GET /profile/me/privacy if added) — Return current privacy flags so the settings screen can show the correct state.

---

## 3. Chat list and icebreakers

### 3.1 Chat list

- **GET /chat/threads?mode=...** — Returns threads with `lastMessage`, `lastMessageAt`, `unreadCount`. The app shows unread badge and last message preview. See [BACKEND_API_REFERENCE.md §7](BACKEND_API_REFERENCE.md#7-chat-api) and [BACKEND_CHAT_INTEGRATION.md](BACKEND_CHAT_INTEGRATION.md).
- From the **Requests** tab (chat requests), the app shows “Accept” / “Decline” and “Express interest” or “Accept request” where relevant; accept can open the thread.

### 3.2 Icebreakers / suggestions

The app may show **suggestion chips** (e.g. “Hi!”, “How are you?”, “Tell me about yourself”) so users can send a first message easily.

**Backend (optional):**

- **GET /chat/suggestions** or include in **GET /chat/threads** or **GET /profile/:id/summary** — Return an array of suggested first-message strings, e.g. `["Hi!", "How are you?", "What brings you here?"]`. Mode-aware (dating vs matrimony) if needed.
- If not implemented, the app can use a fixed list of suggestions.

---

## 4. Premium and growth

### 4.1 Paywall and benefits

- Mode-aware benefits (e.g. “See who liked you”, “Unlimited requests”, “Profile boost”) and **INR pricing** — see app paywall screen and [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).
- **GET /subscription/me** and **GET /subscription/entitlements** — Used to gate features. Backend returns tier and capability flags.

### 4.2 Profile boost

If the **profileBoost** feature flag is on, the app shows a “Boost profile” entry (e.g. in Settings or on profile). Backend:

- **POST /profile/me/boost** (or /subscription/boost) — Start a boost for the current user (e.g. 24–48 hours). Body optional: `{ "durationHours": 24 }`. Returns e.g. `{ "boostedUntil": "2025-03-02T12:00:00Z" }`.
- **GET /profile/me** or a dedicated **GET /profile/me/boost** — Return `boostedUntil?: string` (ISO 8601) so the app can show “Boosted until …” or “Boost profile”.
- Discovery/recommended logic should weight boosted profiles higher while `boostedUntil` is in the future.

### 4.3 Referral

- Referral screen exists; the app adds **“Invite friends”** from Profile/Settings.
- **Backend:** Endpoints for referral code, invite link, and status (pending/earned rewards). If not already present, provide at least:
  - **GET /referral** — Return `{ "code": "...", "inviteLink": "...", "pendingCount": 0, "earnedRewards": [] }`.
  - **POST /referral/invite** — Optional: record that user sent an invite (e.g. by channel).

---

## 5. Settings and account

### 5.1 Language selector

The app has **11 locales** (en, hi, bn, te, mr, ta, ur, gu, kn, ml, pa). “App language” is in Settings; the app persists the selected locale **locally** (e.g. SharedPreferences). No backend endpoint required for language preference unless you want to sync it (e.g. PATCH /profile/me with `preferredLocale`).

### 5.2 Mode switch (Dating / Matrimony)

Mode is stored **client-side** and can be switched from Settings with confirmation. No backend call required for the switch itself; subsequent API calls (e.g. discovery, chat) use the selected mode.

### 5.3 Account and data

The app shows **“Download my data”**, **“Deactivate account”**, and **“Delete account”** in a dedicated Account or Safety section.

**Backend:**

| Method | Path | Description |
|--------|------|-------------|
| POST | /account/export | Request a copy of the user’s data. Returns `{ "requestId": "...", "status": "pending", "message": "We'll email you when ready" }`. Backend generates a link (e.g. S3) and sends email when ready. |
| POST | /account/deactivate | Deactivate account (reversible). Body optional: `{ "reason": "..." }`. Auth token invalidated or marked inactive; profile hidden from discovery. |
| POST | /account/delete | Permanently delete account. Body optional: `{ "reason": "...", "password": "..." }` if required. Irreversible; purge PII and anonymise where needed. |

**Response conventions:**

- **Deactivate:** 200 + `{ "deactivatedAt": "..." }`. Optional: **POST /account/reactivate** to restore.
- **Delete:** 200 + `{ "deleted": true }`. 403 if not allowed (e.g. active subscription).

---

## 6. Quick reference

| Area | Endpoints / behaviour |
|------|------------------------|
| Notification prefs | PATCH /profile/me/notifications; optional GET /profile/me/notifications |
| FCM token | POST /profile/me/fcm-token; see BACKEND_PUSH_NOTIFICATIONS.md |
| Deep links | Include `data` (type, screen, threadId, profileId, etc.) in FCM payload |
| Block / report | POST /safety/block, POST /safety/report; GET/DELETE /safety/blocked |
| Privacy | PATCH /profile/me/privacy (extend with profileVisibility, hideFromDiscovery) |
| Chat list | GET /chat/threads (lastMessage, unreadCount); BACKEND_CHAT_INTEGRATION |
| Icebreakers | Optional GET /chat/suggestions or static app list |
| Profile boost | POST /profile/me/boost; return boostedUntil on profile or GET /profile/me/boost |
| Referral | GET /referral (code, link, status); optional POST /referral/invite |
| Account | POST /account/export, POST /account/deactivate, POST /account/delete |

---

## 7. Related docs

- [BACKEND_PUSH_NOTIFICATIONS.md](BACKEND_PUSH_NOTIFICATIONS.md) — FCM, payload format, deep link data.
- [BACKEND_SECURITY_BLOCK_REPORT.md](BACKEND_SECURITY_BLOCK_REPORT.md) — Block, report, blocked list.
- [BACKEND_API_REFERENCE.md](BACKEND_API_REFERENCE.md) — Full API reference.
- [BACKEND_CHAT_INTEGRATION.md](BACKEND_CHAT_INTEGRATION.md) — Chat list, threads, messages.
- [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) — Mode-aware paywall, mode switch, language.
