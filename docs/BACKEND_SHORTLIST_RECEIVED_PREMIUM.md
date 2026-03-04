# Shortlist “Who shortlisted you” — Premium Gate & Unlock (5/week)

Free users see a premium gate for “Shortlisted you” with **blurred profile cards** and an option to **watch an ad to unlock one** profile. The backend enforces a limit of **5 unlocks per week**; after that, the “Watch ad” option is hidden until the next week.

---

## 1. GET /shortlist/received (free users)

For **non‑premium** users, return **403** with a body that includes count and (optionally) the ad‑unlock quota for the week:

```json
{
  "code": "PREMIUM_REQUIRED",
  "message": "Only premium users can see who shortlisted them",
  "count": 3,
  "shortlistUnlocksRemainingThisWeek": 5,
  "shortlistUnlocksResetAt": "2026-03-07T00:00:00.000Z"
}
```

**Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `code` | string | yes | `"PREMIUM_REQUIRED"` |
| `message` | string | yes | User-facing message |
| `count` | integer | no | Number of people who shortlisted the user. Frontend shows this many **blurred** cards only when **count > 0**. If omitted or 0, no blurred cards are shown. |
| `shortlistUnlocksRemainingThisWeek` | integer | no | How many “watch ad to unlock” uses the user has left this week (max 5). If omitted, frontend assumes 5. |
| `shortlistUnlocksResetAt` | string (ISO 8601) | no | When the weekly quota resets. Shown as “Unlocks reset next week” when remaining is 0. |

**Behaviour:**

- **Premium users:** return **200** with the full list (e.g. `profiles: [{ profileId, firstName, age, name, imageUrl, ... }]`) as today.
- **Free users:** return **403** with the body above so the app can show the gate, blurred cards (when `count > 0`), and “Watch ad to unlock” only when `shortlistUnlocksRemainingThisWeek > 0`.

---

## 2. POST /shortlist/received/unlock-one

After the user watches an ad, the app calls this to unlock **one** “who shortlisted you” profile. The backend must enforce **5 unlocks per week** per user.

**Request**

- **Method:** `POST`
- **Path:** `/shortlist/received/unlock-one`
- **Body:**

```json
{
  "adCompletionToken": "uuid-from-client-after-ad"
}
```

- **`adCompletionToken`** (string, required): Opaque token from the client after the user completed an ad. Validate (e.g. with your ad provider or short‑lived store) so unlocks are only granted after a real ad view.

**Response (success, one profile unlocked)**

- **Status:** `200`
- **Body:**

```json
{
  "entry": {
    "profileId": "user-id",
    "firstName": "Priya",
    "age": 27,
    "name": "Priya S.",
    "imageUrl": "https://..."
  },
  "unlocksRemainingThisWeek": 4,
  "resetsAt": "2026-03-07T00:00:00.000Z"
}
```

Alternatively you can return `profile` instead of `entry`; frontend accepts either.

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `entry` or `profile` | object | The unlocked “who shortlisted you” entry (at least `profileId`, `firstName`, `age`; optional `name`, `imageUrl`). |
| `unlocksRemainingThisWeek` | integer | Remaining ad‑unlocks for this week (0–5). Frontend hides “Watch ad” when this is 0. |
| `resetsAt` | string (ISO 8601) | When the weekly quota resets. |

**Response (quota exhausted — 5 unlocks already used this week)**

- **Status:** `403`
- **Body:**

```json
{
  "code": "SHORTLIST_UNLOCKS_LIMIT_REACHED",
  "message": "You've used all 5 unlocks this week",
  "shortlistUnlocksResetAt": "2026-03-07T00:00:00.000Z"
}
```

Frontend will hide the “Watch ad to unlock” option and can show “Unlocks reset next week” using `shortlistUnlocksResetAt`.

**Other errors**

- **401** Unauthorized
- **403** e.g. invalid or already-used ad token
- **404** No one has shortlisted the user (nothing to unlock)

---

## 3. GET /shortlist/received/count

Used for the “Shortlist” badge (e.g. “1” on the tab). For free users you can:

- Return **200** with `{ "count": N }` so the badge still shows, or  
- Return **403** with the same `PREMIUM_REQUIRED` body as GET /shortlist/received.

Frontend does not require count for the gate; it only needs **count** in the **GET /shortlist/received** 403 body to decide how many blurred cards to show.

---

## 4. Backend rules (summary)

1. **Weekly limit:** Each user has at most **5** “watch ad to unlock” uses per calendar week (or your chosen 7‑day window). After 5, return 403 `SHORTLIST_UNLOCKS_LIMIT_REACHED` and include `shortlistUnlocksResetAt`.
2. **Count in 403:** In the GET /shortlist/received 403 response, include **count** (number of people who shortlisted the user) so the app can show that many blurred cards. Only show blurred cards when **count > 0**.
3. **Quota in 403:** Include **shortlistUnlocksRemainingThisWeek** and **shortlistUnlocksResetAt** in the 403 body so the app can show “X unlocks left this week” and hide “Watch ad” when remaining is 0.
4. **Unlock-one:** Validate `adCompletionToken`, decrement the user’s weekly counter, return one full entry and the updated `unlocksRemainingThisWeek` and `resetsAt`.

Frontend will:

- Show blurred cards only when `count > 0`.
- Show “Watch ad to unlock” only when `shortlistUnlocksRemainingThisWeek > 0`.
- After 403 `SHORTLIST_UNLOCKS_LIMIT_REACHED`, hide the button and show “Unlocks reset next week” until the next period.
