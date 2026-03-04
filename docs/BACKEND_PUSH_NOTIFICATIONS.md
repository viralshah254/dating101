# Shubhmilan Backend — Push Notifications (Firebase Cloud Messaging)

**Purpose:** Feed this document to Cursor when implementing backend push notifications. The Flutter app uses Firebase Cloud Messaging (FCM); the backend is responsible for **sending** all push notifications when server-side events occur. The frontend only registers the device token and handles taps (deep links).

---

## 1. Frontend vs backend responsibilities

| Responsibility | Owner |
|----------------|--------|
| Request notification permission (iOS/Android) | **Frontend** |
| Get FCM device token | **Frontend** |
| Register FCM token with backend (POST /profile/me/fcm-token) | **Frontend** |
| Send push when interest/match/message/visit happens | **Backend** |
| Respect user notification preferences | **Backend** |
| Handle notification tap and navigate (deep link) | **Frontend** |
| Delete token on logout (optional) | **Frontend** (deleteToken); **Backend** may support DELETE device |

All **sending** of push notifications is done by the backend. The frontend never sends push; it only registers the token and reacts to incoming messages.

---

## 2. Device token registration

The Flutter app calls this after login when the user reaches the main shell.

### Endpoint

```http
POST /profile/me/fcm-token
Content-Type: application/json
Authorization: Bearer <accessToken>
```

**Request body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| fcmToken | string | Yes | FCM device token from the client. |

**Example**

```json
{
  "fcmToken": "dG9rZW4uZXhhbXBsZS5mY20..."
}
```

**Success:** `200 OK` or `204 No Content` (body optional).

**Behaviour**

- Store the token for the current user. Prefer one token per user per device (upsert by userId + optional deviceId if you track multiple devices).
- When sending a push, look up the recipient’s stored FCM token(s) and use Firebase Admin SDK to send the message.
- If the client sends a new token (e.g. after reinstall), overwrite or add for that user/device.

**Optional:** Support `DELETE /profile/me/fcm-token` with body `{ "fcmToken": "..." }` or no body (delete current device) for logout cleanup.

---

## 3. When to send push (backend-only)

Send a push only when the **recipient’s** notification preference for that type is enabled (see §6). Default to `true` for any new preference key.

| Event | Recipient | Preference key | Push title | Push body |
|-------|-----------|----------------|------------|-----------|
| Interest received | B (target of interest) | interestReceived | New interest | `{A.name} is interested in your profile` |
| Priority interest received | B | priorityInterestReceived | Priority interest! | `{A.name} sent you a priority interest` |
| Interest accepted | A (sender of interest) | interestAccepted | Interest accepted | `{B.name} accepted your interest!` |
| Interest declined | A | interestDeclined | (optional) | Your interest was not accepted |
| Mutual match created | Both A and B | mutualMatch | It's a match! | You and `{other.name}` matched! |
| Profile visited | B (profile owner) | profileVisited | New visitor | Someone viewed your profile |
| **New chat message** | Recipient of message | newMessage | `{senderName}` | Preview of message text (e.g. first 50 chars) |

- **Interest/priority interest:** When A sends interest (or priority interest) to B, send push to B.
- **Interest accepted/declined:** When B accepts or declines A’s interest, send push to A.
- **Mutual match:** When a mutual match is created (both interested or B accepted), send push to **both** users.
- **Profile visited:** When A opens B’s full profile, backend records visit (existing behaviour); send push to B.
- **New message:** When a message is stored in a chat thread, send push to the **other** participant (not the sender). Respect `newMessage` preference.

---

## 4. FCM payload format

Use **data-only** or **notification + data** messages so the Flutter app can open the correct screen when the user taps.

### Recommended: notification + data

- **notification:** title and body for the system tray.
- **data:** key-value map for deep linking. All values must be strings.

**Data payload (all optional; include what the route needs)**

| Key | Description | Example |
|-----|-------------|--------|
| type | Event type (see below) | `new_message` |
| screen | Target tab/screen | `chats`, `requests`, `matches`, `visitors` |
| threadId | Chat thread id | `thread_abc` |
| otherUserId | Other participant’s user id (for chat) | `usr_xyz` |
| profileId | Profile to open | `usr_abc` |
| interactionId | Interaction id (e.g. for requests) | `int_123` |
| matchId | Match id | `match_abc` |

**Type values:** `interest_received`, `priority_interest_received`, `interest_accepted`, `interest_declined`, `mutual_match`, `profile_visited`, `new_message`, `contact_request_accepted`, `contact_request_declined`.

### Deep link paths (Flutter app)

The app uses these paths. Build `data` so the client can build the same path. When the user taps a notification, the app calls `router.go(path)` so that **shell routes** (`/chats`, `/community`, `/`, `/profile-settings`) switch to the correct tab; use the paths above so the correct branch is selected.

| Intent | Path | data suggestion |
|--------|------|------------------|
| Chat thread | `/chat/:threadId?otherUserId=...` | type: `new_message`, threadId, otherUserId |
| Chats list | `/chats` | screen: `chats` |
| Requests inbox | `/requests` | screen: `requests` or type: `interest_received` / `priority_interest_received` |
| Matches | `/` (home) | screen: `matches` |
| Profile | `/profile/:id` | profileId |
| Visitors | `/community` | screen: `visitors` |
| Contact request accepted | `/profile/:id` or `/` | type: `contact_request_accepted`, profileId |
| Contact request declined | `/` | type: `contact_request_declined` |

Example for **new message:**

```json
{
  "notification": {
    "title": "Priya",
    "body": "Hey! Are we still on for tomorrow?"
  },
  "data": {
    "type": "new_message",
    "threadId": "thread_abc",
    "otherUserId": "usr_priya"
  }
}
```

Example for **mutual match:**

```json
{
  "notification": {
    "title": "It's a match!",
    "body": "You and Priya matched!"
  },
  "data": {
    "type": "mutual_match",
    "screen": "matches"
  }
}
```

Example for **profile visited:**

```json
{
  "notification": {
    "title": "New visitor",
    "body": "Someone viewed your profile"
  },
  "data": {
    "type": "profile_visited",
    "screen": "visitors"
  }
}
```

---

## 5. Sending via Firebase Admin SDK

- Use the **Firebase Admin SDK** (e.g. Node.js `firebase-admin`, or your backend’s FCM API) with a **server key** or **service account**.
- Recipient: use the stored **FCM token** for the target user (and optionally platform: Android vs iOS if you use different options).
- Always include the `data` map for deep linking; include `notification` for visibility in tray.
- For Android, you may need to set `android.channel_id` if the app uses a specific channel.

---

## 6. User notification preferences

The app already has:

```http
PATCH /profile/me/notifications
```

**Request body (all optional booleans):**

| Key | Description | Default |
|-----|-------------|--------|
| interestReceived | Push when someone sends you interest | true |
| priorityInterestReceived | Push when someone sends priority interest | true |
| interestAccepted | Push when someone accepts your interest | true |
| interestDeclined | Push when someone declines your interest | false |
| mutualMatch | Push when you get a mutual match | true |
| profileVisited | Push when someone views your profile | true |
| newMessage | Push when you receive a new chat message | true |
| contactRequestAccepted | Push when someone accepts your contact request | true |
| contactRequestDeclined | Push when someone declines your contact request | false |

Before sending a push for an event, check the recipient’s stored preferences and skip if the corresponding key is `false`.

---

## 7. Checklist for backend

| # | Task |
|---|------|
| 1 | Implement `POST /profile/me/fcm-token` to store FCM token per user/device. |
| 2 | Integrate Firebase Admin SDK (or FCM HTTP v1 API) to send messages. |
| 3 | On **interest** (and **priority interest**): send push to recipient; respect `interestReceived` / `priorityInterestReceived`. |
| 4 | On **accept/decline**: send push to sender; respect `interestAccepted` / `interestDeclined`. |
| 5 | On **mutual match**: send push to both users; respect `mutualMatch`. |
| 6 | On **profile visit** (when recording visit): send push to profile owner; respect `profileVisited`. |
| 7 | On **new chat message**: send push to the other participant; respect `newMessage`. Include `threadId` and `otherUserId` in `data`. |
| 8 | On **contact request accepted/declined**: send push to the requester; respect `contactRequestAccepted` / `contactRequestDeclined`. Include `profileId` for accepted. |
| 9 | Store and honour notification preferences from `PATCH /profile/me/notifications` (including `newMessage`, `contactRequestAccepted`, `contactRequestDeclined`). |
| 10 | (Optional) Implement `DELETE /profile/me/fcm-token` for logout. |

---

## 8. Related docs

- [BACKEND_INTERACTIONS_AND_VISITORS.md](./BACKEND_INTERACTIONS_AND_VISITORS.md) — interactions, visits, matches, §9 notifications table.
- [chat_endpoint.md](./chat_endpoint.md) — chat threads and messages (for `new_message` trigger).
- [new_endpoints.md](./new_endpoints.md) — list of endpoints including notifications.
