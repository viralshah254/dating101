# Interest Reminders — 2-Day No-Response Flow

**Purpose:** When an interest has gone unanswered for 2 days, remind both parties: the sender gets a prompt to "send a reminder," and the receiver gets a notification to check out the profile.

---

## 1. Overview

| Role | After 2 days | Action |
|------|--------------|--------|
| **Sender** (A showed interest in B) | Gets in-app prompt + optional push | Can tap "Send reminder" → triggers push to B |
| **Receiver** (B received interest, hasn't responded) | Gets push when A sends reminder | "A is interested in you! Check out their profile" → deep link to A's profile |

### Flow

```
Day 0: A sends interest to B
       → B gets "New interest" push (existing)
       → B sees in Requests / Likes inbox

Day 2: No response from B
       → Backend scheduled job finds pending interests older than 2 days
       → Sends push to A: "You showed interest in {B.name} 2 days ago. Send a reminder?"
       → A sees "Send reminder" button in You Liked tab (frontend shows based on createdAt)

A taps "Send reminder"
       → POST /interactions/:interactionId/remind
       → Backend sends push to B: "{A.name} is interested in you! Check out their profile"
       → Push data includes profileId: A's id for deep link

B taps notification
       → App opens /profile/{A.id}
       → B can view A's profile and accept/decline
```

---

## 2. Backend: Scheduled Job (Cron)

**Frequency:** Run daily (e.g. 10:00 UTC) or every 6–12 hours.

**Logic:**

1. Query `interactions` where:
   - `status = 'pending'`
   - `type IN ('interest', 'priority_interest')`
   - `created_at <= NOW() - INTERVAL '2 days'`
   - `reminder_sent_to_sender_at IS NULL` (see schema below)

2. For each such interaction:
   - Send push to **sender** (`from_user_id`):
     - Title: `Interest reminder`
     - Body: `You showed interest in {toUser.name} 2 days ago. Send a reminder?`
     - Data: `type: interest_reminder_prompt`, `interactionId`, `profileId` (toUser.id), `screen: likes`
   - Set `reminder_sent_to_sender_at = NOW()` to avoid duplicate pushes

**Push payload example (to sender):**

```json
{
  "notification": {
    "title": "Interest reminder",
    "body": "You showed interest in Priya 2 days ago. Send a reminder?"
  },
  "data": {
    "type": "interest_reminder_prompt",
    "interactionId": "int_xyz",
    "profileId": "usr_priya",
    "screen": "likes"
  }
}
```

---

## 3. Backend: Send Reminder API

**Endpoint:**

```
POST /interactions/:interactionId/remind
```

**Auth:** Required. Caller must be the **sender** (`from_user_id`) of the interaction.

**Preconditions:**

- Interaction exists
- `status = 'pending'`
- `created_at <= NOW() - INTERVAL '2 days'`
- Caller is `from_user_id`
- Rate limit: at most 1 reminder per interaction per 24 hours (optional; use `last_reminder_sent_at`)

**Response `200 OK`:**

```json
{
  "interactionId": "int_xyz",
  "reminderSent": true,
  "reminderSentAt": "2026-03-10T10:00:00Z"
}
```

**Side effect:** Send push to **receiver** (`to_user_id`):

- Title: `Someone is interested in you`
- Body: `{fromUser.name} is interested in you! Check out their profile`
- Data: `type: interest_reminder`, `profileId` (fromUser.id), `interactionId`

**Push payload example (to receiver):**

```json
{
  "notification": {
    "title": "Someone is interested in you",
    "body": "Rahul is interested in you! Check out their profile"
  },
  "data": {
    "type": "interest_reminder",
    "profileId": "usr_rahul",
    "interactionId": "int_xyz"
  }
}
```

**Errors:**

| Code | Meaning |
|------|---------|
| `404` | Interaction not found |
| `403` | Caller is not the sender |
| `400` | Interest is less than 2 days old |
| `400` | Interest already accepted/declined/withdrawn |
| `429` | Reminder already sent in last 24 hours (if rate limited) |

---

## 4. Database Schema Additions

Add to `interactions` table:

```sql
ALTER TABLE interactions
  ADD COLUMN reminder_sent_to_sender_at TIMESTAMPTZ,
  ADD COLUMN last_reminder_sent_at TIMESTAMPTZ;
```

- `reminder_sent_to_sender_at`: When the cron job sent the "send a reminder?" push to the sender.
- `last_reminder_sent_at`: When the sender last triggered a reminder to the receiver (for 24h rate limit).

---

## 5. Notification Preferences

Add to `PATCH /profile/me/notifications`:

| Key | Description | Default |
|-----|-------------|---------|
| interestReminderPrompt | Push when interest is 2+ days old (to sender) | true |
| interestReminderReceived | Push when someone sends you a reminder (to receiver) | true |

Check these before sending the respective pushes.

---

## 6. Frontend Integration

### Sender (You Liked / Sent tab)

- For each sent interaction with `status == 'pending'` and `createdAt` older than 2 days:
  - Show a "Send reminder" button or chip.
  - On tap: call `POST /interactions/:interactionId/remind`.
  - On success: show toast "Reminder sent to {name}"; optionally disable the button for 24h.

### Receiver

- Handle push with `type: interest_reminder` and `profileId`.
- On tap: navigate to `/profile/{profileId}` so the user can view the sender's profile and accept/decline.

### Deep link paths

| type | Path | Notes |
|------|------|-------|
| `interest_reminder_prompt` | `/likes` (You Liked tab) | Sender opens app to send reminder |
| `interest_reminder` | `/profile/{profileId}` | Receiver opens sender's profile |

---

## 7. Checklist for Backend

| # | Task |
|---|------|
| 1 | Add `reminder_sent_to_sender_at` and `last_reminder_sent_at` to `interactions` table |
| 2 | Implement scheduled job: find pending interests > 2 days, send "send a reminder?" push to sender |
| 3 | Implement `POST /interactions/:interactionId/remind` |
| 4 | On remind: send "X is interested in you" push to receiver with `profileId` |
| 5 | Add `interestReminderPrompt` and `interestReminderReceived` to notification preferences |
| 6 | (Optional) Enforce 24h rate limit per interaction for reminders |

---

## 8. Related Docs

- [BACKEND_INTERACTIONS_AND_VISITORS.md](./BACKEND_INTERACTIONS_AND_VISITORS.md)
- [BACKEND_PUSH_NOTIFICATIONS.md](./BACKEND_PUSH_NOTIFICATIONS.md)
