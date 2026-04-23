# Shubhmilan Backend — Push Notifications (Firebase Cloud Messaging)

**Last updated:** 2026-04-23  
**Purpose:** Reference document for the complete push notification contract between backend (`push.ts`) and Flutter client (`notification_service.dart`, `notification_deep_link.dart`).

---

## 1. Responsibilities

| Responsibility | Owner |
|----------------|--------|
| Request notification permission (iOS/Android 13+) | **Frontend** |
| Get FCM device token, handle `onTokenRefresh` | **Frontend** |
| Register FCM token with backend (`POST /profile/me/fcm-token`) | **Frontend** (on shell mount) |
| Send push when server events occur | **Backend** |
| Respect user notification preferences | **Backend** |
| Handle foreground/background/cold-start taps and navigate | **Frontend** |
| Clean up token on logout | **Backend** (prunes invalid tokens automatically) |

All push **sending** is done by the backend. The frontend registers tokens and reacts to taps.

---

## 2. Device token registration

```http
POST /profile/me/fcm-token
Authorization: Bearer <accessToken>
Content-Type: application/json

{ "fcmToken": "<FCM token from FirebaseMessaging.getToken()>" }
```

- Called automatically by `registerFcmTokenProvider` when the logged-in user enters the main shell.
- Called again after `onTokenRefresh` fires.
- Upserts by `(userId, token)` — multiple devices are supported.
- Stale/invalid tokens are pruned automatically when FCM returns `messaging/registration-token-not-registered`.

---

## 3. Complete push payload contract

Every push emits a `notification` block (title/body for the system tray) and a `data` map for deep-linking. **All `data` values are strings.**

### Core data fields

| Key | Type | Description |
|-----|------|-------------|
| `type` | string | Notification reason (see table below) |
| `screen` | string | Fallback/hint for the client (see §4) |
| `threadId` | string | Chat thread ID (for message/chat pushes) |
| `otherUserId` | string | Other participant's user ID |
| `profileId` | string | Profile to open on tap |
| `interactionId` | string | Interest/interaction ID |
| `matchId` | string | Mutual match ID |
| `threadMode` | string | `"dating"` or `"matrimony"` — controls which mode shell the chat opens in |
| `messageRequestId` | string | Message request ID |
| `verificationType` | string | `"id"` or `"education"` (verification pushes) |

### Push reasons

| `type` | Recipient | Pref key | `screen` | Other data fields |
|--------|-----------|----------|----------|-------------------|
| `interest_received` | Profile target | `interestReceived` | `requests` | — |
| `priority_interest_received` | Profile target | `priorityInterestReceived` | `requests` | — |
| `interest_accepted` | Interest sender | `interestAccepted` | `matches` | — |
| `interest_declined` | Interest sender | `interestDeclined` | `matches` | — |
| `interest_reminder` | Profile target | `interestReminderReceived` | `requests` | `profileId`, `interactionId` |
| `interest_reminder_prompt` | Interest sender | `interestReminderPrompt` | `likes` | `interactionId`, `profileId` |
| `mutual_match` | Both users | `mutualMatch` | `matches` | `otherUserId`, `threadId`?, `matchId`? |
| `new_message` | Message recipient | `newMessage` | *(via threadId)* | `threadId`, `otherUserId`, `threadMode` |
| `message_request` | Request recipient | `messageRequestReceived` | *(via threadId)* | `threadId`, `otherUserId`, `threadMode`, `messageRequestId` |
| `message_request_accepted` | Request sender | `messageRequestAccepted` | *(via threadId)* | `threadId`, `otherUserId`, `threadMode` |
| `message_request_declined` | Request sender | `messageRequestDeclined` | `requests` | — |
| `profile_visited` | Profile owner | `profileVisited` | `visitors` | — |
| `shortlisted_you` | Shortlisted user | `shortlistedYou` | `shortlist` | `profileId` |
| `contact_request_accepted` | Requester | `contactRequestAccepted` | `profile` | `profileId`, `otherUserId` |
| `contact_request_declined` | Requester | `contactRequestDeclined` | `matches` | — |
| `photo_view_request` | Photo owner | `photoViewRequestReceived` | `requests` | `profileId` |
| `photo_view_accepted` | Requester | `photoViewRequestAccepted` | `profile` | `profileId`, `otherUserId` |
| `photo_view_declined` | Requester | `photoViewRequestDeclined` | `notifications` | — |
| `morning_reminder` | User | `morningReminder` | `matches` | — |
| `inactive_reminder` | User | `inactiveReminder` | `matches` | — |
| `admin_message` | User | *(no pref gate)* | `notifications` | — |
| `admin_warning` | User | *(no pref gate)* | `notifications` | — |
| `verification_approved` | User | *(no pref gate)* | `profile_settings` | `verificationType` |
| `verification_rejected` | User | *(no pref gate)* | `profile_settings` | `verificationType` |

> **Admin and verification pushes always deliver** — they do not check notification preferences.

---

## 4. Flutter deep-link routing (`notification_deep_link.dart`)

The function `notificationDataToPath(data, appMode: mode)` converts FCM `data` into a GoRouter path.

### Resolution order

1. If `screen` field is set, map it directly:
   - `requests` → `/requests`
   - `chats` → `/chats` (dating) or `/likes` (matrimony)
   - `matches` → `/`
   - `visitors` → `/likes?tab=visitors` (dating) or `/notifications` (matrimony)
   - `likes` → `/likes?tab=you_liked`
   - `profile_settings` → `/profile-settings`
   - `notifications` → `/notifications`
   - `shortlist` → `/chats` (dating) or `/chats` (matrimony)
   - `profile` + `profileId` → `/profile/:profileId`
   - `chat` → `/chat/:threadId?otherUserId=...&threadMode=...`
2. Otherwise switch on `type`:

| `type` | Route |
|--------|-------|
| `new_message`, `message` | `/chat/:threadId?otherUserId=...&threadMode=...` or chat list |
| `message_request` | `<chatList>?tab=requests` |
| `message_request_accepted` | `/chat/:threadId?otherUserId=...&threadMode=...` |
| `message_request_declined` | `<chatList>?tab=requests` |
| `mutual_match`, `interest_accepted` | Chat thread if `threadId`, else `/` |
| `interest_received`, `priority_interest_received` | `/requests` |
| `interest_reminder` | `/profile/:profileId` or `/requests` |
| `interest_reminder_prompt` | `/likes?tab=you_liked` (dating) / shortlist (matrimony) |
| `interest_declined` | `/` |
| `profile_visited` | `/likes?tab=visitors` (dating) or `/notifications` (matrimony) |
| `contact_request_accepted` | `/profile/:profileId` or `/` |
| `contact_request_declined` | `/` |
| `shortlisted_you` | `/profile/:profileId` or shortlist |
| `photo_view_request` | `/requests` |
| `photo_view_accepted` | `/profile/:profileId` or `/requests` |
| `photo_view_declined` | `/notifications` |
| `morning_reminder`, `inactive_reminder` | `/` |
| `admin_message`, `admin_warning` | `/notifications` |
| `verification_approved`, `verification_rejected` | `/profile-settings` |
| *(anything else)* | `/notifications` |

### `threadMode` handling

When `threadMode` is present in the push payload, the client opens the chat thread in the correct mode shell (`dating` vs `matrimony`). The `threadMode` value is forwarded as a query parameter so the chat screen initializes in the right mode.

---

## 5. App lifecycle: foreground / background / cold start

| State | FCM behavior | App handling |
|-------|-------------|--------------|
| **Foreground (Android)** | FCM does **not** show a system banner | `notification_service.dart` shows a local notification via `flutter_local_notifications`, preserving full `data` payload for tap routing |
| **Foreground (iOS)** | FCM shows banner natively (configured via `setForegroundNotificationPresentationOptions`) | `onMessage` fires; iOS shows the banner |
| **Background** | System shows banner | Tap fires `onMessageOpenedApp` → `notificationDataToPath` → `router.go(path)` |
| **Cold start (terminated)** | System shows banner | Tap is stored via `getInitialMessage()` in `_coldStartTapData`. **Not navigated immediately.** `drainColdStartTap()` is called from `app.dart` after a 2.6 s delay, after the splash screen finishes and the router is in its final state. |

---

## 6. User notification preferences

```http
PATCH /profile/me/notifications
Authorization: Bearer <accessToken>
Content-Type: application/json
```

Partial update — only send keys you want to change.

| Pref key | Default | Description |
|----------|---------|-------------|
| `interestReceived` | `true` | Someone sent you interest |
| `priorityInterestReceived` | `true` | Someone sent priority interest |
| `interestAccepted` | `true` | Your interest was accepted |
| `interestDeclined` | `false` | Your interest was declined |
| `mutualMatch` | `true` | Mutual match created |
| `profileVisited` | `true` | Someone viewed your profile |
| `newMessage` | `true` | New chat message |
| `messageRequestReceived` | `true` | Inbound message request |
| `messageRequestAccepted` | `true` | Your message request was accepted |
| `messageRequestDeclined` | `false` | Your message request was declined |
| `interestReminderPrompt` | `true` | Prompt to send reminder for old interest |
| `interestReminderReceived` | `true` | Someone sent you a reminder |
| `shortlistedYou` | `true` | Added to someone's shortlist |
| `contactRequestAccepted` | `true` | Contact request accepted |
| `contactRequestDeclined` | `true` | Contact request declined |
| `photoViewRequestReceived` | `true` | Photo view request received |
| `photoViewRequestAccepted` | `true` | Photo view request accepted |
| `photoViewRequestDeclined` | `false` | Photo view request declined |
| `morningReminder` | `true` | Daily 7 AM motivation push |
| `inactiveReminder` | `true` | Re-engagement after 24h inactivity |

---

## 7. Dev test endpoints

Only available when `NODE_ENV=development` or `ALLOW_SIMPLE_PUSH_TEST=true`.

### Send single reason

```http
POST /internal/dev/push-test/reason
Content-Type: application/json

{
  "userId": "usr_xxx",        // optional — defaults to first user with FCM token
  "reason": "new_message",   // see §3 for all type values
  "threadId": "thread_abc",  // optional
  "otherUserId": "usr_yyy"   // optional
}
```

Valid `reason` values match all `type` values in §3 plus `raw`.

### Send all reasons (matrix)

```http
POST /internal/dev/push-test/matrix?userId=usr_xxx
```

Fires all push reasons sequentially with a 400 ms gap. Use this to test every notification in foreground, then put the app into background/killed state and re-send to validate the other states.

---

## 8. Related docs

- [BACKEND_INTERACTIONS_AND_VISITORS.md](./BACKEND_INTERACTIONS_AND_VISITORS.md) — interactions, visits, matches, §9 notifications table.
- [chat_endpoint.md](./chat_endpoint.md) — chat threads and messages (for `new_message` trigger).
- [new_endpoints.md](./new_endpoints.md) — list of endpoints including notifications.
