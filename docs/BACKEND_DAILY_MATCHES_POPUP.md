# Backend: Daily 9 Matches Pop-up (Matrimony)

**Purpose:** Provide 9 smart-selected potential matches for matrimony users to see once per day on first app open. Users can deselect individuals and send a **free interest** to all selected in one action.

---

## 1. Overview

| Concern | Behavior |
|---------|----------|
| **When** | First time user opens app each day (matrimony mode) |
| **Unless** | User has dismissed/ignored this feature (opt-out stored client-side) |
| **Content** | 9 potential matches: photo, name, age, location |
| **Interaction** | User can deselect individuals; send free interest to selected |
| **Selection** | Smart: based on preferences, compatibility, not already contacted |

---

## 2. API Endpoints

### 2.1 Get daily matches

```http
GET /matrimony/daily-matches?limit=9
Authorization: Bearer <accessToken>
```

**Query:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| limit | number | 9 | Max profiles to return (default 9) |

**Response 200 OK:**

```json
{
  "profiles": [
    {
      "id": "usr_abc",
      "name": "Anjali Verma",
      "age": 35,
      "city": "Hyderabad",
      "country": "India",
      "imageUrl": "https://...",
      "occupation": "Consultant",
      "profileManagedBy": "guardian"
    }
  ]
}
```

**Fields per profile (minimal for pop-up):**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | string | Yes | Profile ID |
| name | string | Yes | Display name |
| age | number | Yes | Age |
| city | string | No | Current city |
| country | string | No | Current country |
| imageUrl | string | No | Primary photo URL |
| occupation | string | No | Job title |
| profileManagedBy | string | No | `"guardian"` when managed by family |

**Smart selection rules:**

1. **Exclude** profiles the user has already sent interest to.
2. **Exclude** blocked users and users who blocked the viewer.
3. **Prefer** profiles matching partner preferences (age, religion, location, education, diet).
4. **Prefer** higher compatibility score (if available).
5. **Prefer** profiles with complete photos and about-me.
6. **Diversity:** Avoid clustering (e.g. same city/community only).
7. **Limit:** Return up to `limit` (default 9).

If fewer than 9 qualify, return what's available. Empty array is valid.

---

### 2.2 Send interest (existing)

Users send interest to selected profiles via the existing endpoint:

```http
POST /interests
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "toUserId": "usr_abc"
}
```

**Batch behavior:** Frontend calls this once per selected profile. Backend may optionally support:

```http
POST /interests/batch
{
  "toUserIds": ["usr_abc", "usr_def", "usr_ghi"]
}
```

If batch is not implemented, frontend sends sequential `POST /interests` for each selected profile.

---

## 3. Client-side logic

| Concern | Implementation |
|---------|-----------------|
| **When to show** | On MatchesScreen mount, when mode is matrimony |
| **Frequency** | At most once per calendar day |
| **Storage** | `daily_matches_last_shown_date` (YYYY-MM-DD) in SharedPreferences |
| **Dismiss** | User can tap "Maybe later" / "Skip" → `daily_matches_dismissed_date` = today; do not show again until next day |
| **After send** | Mark as shown for today; do not show again until next day |

**Show condition:**

```
show = (mode == matrimony)
       AND (lastShownDate != today)
       AND (user has not permanently disabled — optional)
       AND (GET /matrimony/daily-matches returns non-empty)
```

---

## 4. UI flow

1. User opens app in matrimony mode.
2. If `shouldShowDailyMatches()` → fetch `GET /matrimony/daily-matches`.
3. If profiles non-empty → show modal with 9 cards (photo, name, age, location).
4. Each card has a checkbox (default selected). User can deselect.
5. Primary CTA: **"Send free interest"** (or "Express interest to X") → send to selected.
6. Secondary: **"Maybe later"** → dismiss, mark shown for today.
7. On send: call `POST /interests` for each selected; close modal; mark shown.

---

## 5. Database / backend notes

- Reuse existing `Profile` and discovery/matching logic.
- Query should exclude `interactions` where `from_user_id = currentUser` and `type IN ('interest', 'priority_interest')` and `to_user_id IN (...)`.
- Use `Profile.currentCity`, `currentCountry` for location display.
- `profileManagedBy` can come from `Profile.roleManagingProfile` or equivalent.

---

## 6. Checklist for backend

| # | Task |
|---|------|
| 1 | Implement `GET /matrimony/daily-matches` with smart selection |
| 2 | Return minimal profile fields: id, name, age, city, country, imageUrl, occupation, profileManagedBy |
| 3 | Exclude already-sent interests, blocked users |
| 4 | (Optional) Implement `POST /interests/batch` for bulk send |

---

## 7. Related docs

- [BACKEND_INTEREST_REMINDERS.md](./BACKEND_INTEREST_REMINDERS.md) — Interest flow, reminders
- Matrimony discovery/matching — partner preferences, compatibility
