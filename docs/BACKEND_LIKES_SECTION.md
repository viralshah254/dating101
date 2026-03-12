# Backend: Likes Section (Dating)

The **Likes** tab in the app (dating mode) replaces the former Communities tab. It has three sub-sections, each backed by existing or documented endpoints.

---

## 1. Overview

The Likes screen shows three tabs:

| Tab           | Description                    | Endpoint(s) used                          |
|---------------|--------------------------------|------------------------------------------|
| **Liked you** | People who have liked you      | GET /interactions/received                |
| **Visitors**  | People who saw your profile    | GET /visits/received                     |
| **You liked** | People you have liked          | GET /interactions/sent                   |

All are scoped to the current **mode** (dating) when the backend supports it.

---

## 2. Liked you — People who have liked you

**GET /interactions/received**

Returns the list of users who have sent interest (like) or priority interest (super like) to the current user.

**Recommended for free users:** Return **200** with the list so the app can show who liked you with **blurred photos** and name/age (like the Visitors tab). Each item can include minimal `otherUser` data (id, name, age; optional placeholder or no image). Free users can then tap to “Watch ad to unlock one” (2/week) or upgrade. If you return **403 PREMIUM_REQUIRED** instead, the app shows a friendly gate (Upgrade + “Watch ad to unlock one”) and any already-unlocked profiles; no list is shown until the user unlocks or upgrades.

| Query   | Type   | Required | Description |
|---------|--------|----------|-------------|
| status  | string | No       | e.g. `pending`. Default used by app: `pending`. |
| type    | string | No       | e.g. `all`, `interest`, `priority_interest`. App uses `all`. |
| page    | number | No       | Pagination. |
| limit   | number | No       | Page size. App uses 50. |
| **mode**| string | No       | **`dating`** \| `matrimony`. When present, return only received interests for this mode. |

**Response:** List of interaction items. Each item should include at least:

- `interactionId`, `otherUser` (profile summary), `type` (`interest` | `priority_interest`), `createdAt`, optional `message`.

The app displays `otherUser` (name, photo, city) and navigates to full profile on tap. **Profile summary must include at least one of `imageUrl` (string) or `photoUrls` (array of strings)** so the request card can show the user’s avatar; if both are missing, the app shows an initial placeholder.

**See also:** `march new.md` §4.4 (Get received interactions).

---

## 3. Visitors — People who saw your profile

**GET /visits/received**

Returns the list of users who have viewed the current user’s profile (profile visits).

| Query  | Type   | Required | Description |
|--------|--------|----------|-------------|
| page   | number | No       | Pagination. |
| limit  | number | No       | Page size. App uses 50. |

**Response:** e.g.

```json
{
  "visitors": [
    {
      "visitId": "string",
      "visitor": { /* profile summary */ },
      "visitedAt": "ISO8601",
      "source": "profile_view"
    }
  ],
  "newCount": 0
}
```

- **visitors**: Array of visit entries; each has `visitId`, `visitor` (profile summary), `visitedAt`, optional `source`.
- **newCount**: Optional; count of “new” (e.g. unread) visitors for badge. Can be reset when the client calls **POST /visits/mark-seen**.

**POST /visits/mark-seen**  
Optional. Called when the user opens the Likes tab (Visitors section) so the backend can reset `newCount` and/or mark visitors as seen.

### 3.1 Visitors for free users (blurred list + unlock)

The app shows the **Visitors** list to all users. For **free (non‑premium) users**:

- **GET /visits/received** should return **200** with the list of visitors so the app can show **name and age** and **blurred photos** (the app blurs images in the UI when not unlocked).
- Each item must include at least: **visitId**, **visitor** (with **id**, **name**, **age**; **imageUrl** or **photoUrls** optional for free users so the app can show a blurred or placeholder image).
- Do **not** return 403 for free users if you want the app to show the “who visited” list with blurred pics and name/age. If you return 403 PREMIUM_REQUIRED, the app shows an upgrade/unlock message and no list.

**Unlock one visitor (watch ad, 2 per week)**

**POST /visits/unlock-one**

Allows a free user to unlock one visitor profile after watching an ad. Enforce **2 unlocks per week** per user.

| Field               | Type   | Required | Description |
|---------------------|--------|----------|-------------|
| visitId             | string | Yes      | The visit to unlock (from GET /visits/received). |
| adCompletionToken   | string | Yes      | Token from the client after the user completed the ad. |

**Response (200):**

| Field                     | Type   | Description |
|---------------------------|--------|-------------|
| visitId                   | string | Same as request. |
| visitor                   | object | Full profile summary for the unlocked visitor (including photo URLs). |
| unlocksRemainingThisWeek  | int    | Remaining ad-unlocks for the current week (0–2). |
| visitorUnlocksResetAt      | string | ISO8601; when the weekly quota resets. Optional. |

**Errors:**

- **403 VISITOR_UNLOCKS_LIMIT_REACHED** when the user has already used 2 unlocks this week. Optional body: `{ "visitorUnlocksResetAt": "ISO8601" }` so the app can show “Try again after …”.

After a successful unlock, the app allows the user to open that profile (full profile with photos). Premium users do not need to call unlock-one; they can view all visitors without limit.

**See also:** `dating.md` §4 (Visits).

---

## 4. You liked — People you have liked

**GET /interactions/sent**

Returns the list of users the current user has sent interest (like) or priority interest (super like) to.

| Query   | Type   | Required | Description |
|---------|--------|----------|-------------|
| status  | string | No       | e.g. `pending`. App uses `pending`. |
| page    | number | No       | Pagination. |
| limit   | number | No       | Page size. App uses 50. |
| **mode**| string | No       | **`dating`** \| `matrimony`. When present, return only sent interests for this mode. |

**Response:** Same shape as received: list of interaction items with `otherUser` (profile summary), `type`, `createdAt`, etc. The profile summary must include **`imageUrl` and/or `photoUrls`** so the app can show the avatar on each card (see §2 above).

**See also:** `march new.md` §4.3 (Get sent interactions).

---

## 5. Summary

| Section    | Method | Path                     | Mode param | Notes |
|------------|--------|--------------------------|------------|--------|
| Liked you  | GET    | /interactions/received   | Yes        | Dating only in app; filter by `mode=dating`. |
| Visitors   | GET    | /visits/received         | No         | Return 200 with list (name, age, visitId; optional images) for free users so app can show blurred list. |
| Visitors   | POST   | /visits/unlock-one       | No         | Unlock one visitor after ad; 2 per week; return visitor + unlocksRemainingThisWeek. |
| Visitors   | POST   | /visits/mark-seen        | No         | Reset newCount when user opens Visitors tab. |
| You liked  | GET    | /interactions/sent       | Yes        | Filter by `mode=dating`. |

Implementing these endpoints (and the existing POST /visits for recording profile views) supports the Likes tab with “Liked you”, “Visitors” (blurred list + ad unlock 2/week or premium), and “You liked” as described above.
