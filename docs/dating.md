# Dating Mode: Profile View, Photos, Compatibility & Actions

This document describes backend expectations for **dating mode** profile view, multiple photos, compatibility score, shared interests, and the **Pass / Like / Super like** actions. These actions are **dating-only** (not used in matrimony).

---

## 1. Pass / Like / Super like are dating-only

- **Matrimony**: The app uses “Express Interest”, “Priority Interest”, “Send Intro” etc. No Pass / Like / Super like buttons.
- **Dating**: The app shows **Pass**, **Super like**, and **Like** on:
  - Discovery swipe cards
  - Full profile screen (when viewing a profile in dating mode)

Backend should:
- Accept **mode** on discovery feedback and interactions (see `march new.md`). When `mode=dating`, store and filter by dating; when `mode=matrimony`, use matrimony flows only.
- **POST /discovery/feedback** with `action: 'pass'` and `mode: 'dating'` when user taps Pass (from discovery or profile view).
- **POST /interactions/interest** and **POST /interactions/priority-interest** with `mode: 'dating'` for Like and Super like. No change to request shape beyond the existing `mode` parameter.

---

## 2. Profile summary for dating (multiple photos, compatibility, interests)

The app uses **GET /profile/:id/summary** when opening a profile in **dating** mode (and for discovery cards). To support “pictures and more pics”, compatibility, and highlighted shared interests, the summary response should include:

### 2.1 Multiple photos

| Field        | Type     | Description |
|-------------|----------|-------------|
| **imageUrl** | string  | Primary/legacy single image URL (optional if photoUrls present). |
| **photoUrls** | string[] | **Preferred.** All profile photo URLs in order. Used for hero image and “more pics” strip on profile. |

- If **photoUrls** is present and non-empty, the app uses it for the hero and for a horizontal photo strip when there is more than one photo.
- If only **imageUrl** is present, the app shows a single image. Supporting **photoUrls** in the summary response is required for “more pics” on the profile view.

### 2.2 Compatibility (for profile view and cards)

| Field                 | Type   | Description |
|-----------------------|--------|-------------|
| **compatibilityScore** | number | 0–1 score (e.g. 0.6 for 60%). Optional; can be computed per (viewer, profile). |
| **compatibilityLabel** | string | Short label, e.g. "Good match", "Great match". Optional. |

- If the backend can compute compatibility at summary time (e.g. from shared interests, preferences), returning these avoids an extra compatibility call when opening the profile.
- The app also calls **GET /discovery/compatibility/:candidateId** (or equivalent) when needed; if the summary already includes compatibility, the profile screen can use it and optionally refresh from the compatibility endpoint.

### 2.3 Shared interests (for highlighting)

| Field                | Type     | Description |
|----------------------|----------|-------------|
| **interests**        | string[] | All interests for the profile. |
| **sharedInterests**  | string[] | Subset of **interests** that the **current viewer** shares with this profile. |

- The app highlights chips for interests that appear in **sharedInterests** (e.g. filled/accent style) and shows the rest with a neutral style.
- Backend should compute **sharedInterests** for the authenticated viewer when returning the summary.

### 2.4 Example summary fragment (dating)

```json
{
  "id": "...",
  "name": "Preeti Mehta",
  "age": 33,
  "city": "Surat",
  "imageUrl": "https://...",
  "photoUrls": ["https://.../1.jpg", "https://.../2.jpg", "https://.../3.jpg"],
  "bio": "...",
  "interests": ["Cooking", "Movies", "Dancing", "Reading", "Travel"],
  "sharedInterests": ["Cooking", "Movies", "Dancing", "Reading"],
  "compatibilityScore": 0.6,
  "compatibilityLabel": "Good match"
}
```

---

## 3. Compatibility endpoint (optional fallback)

When the summary does not include compatibility (or the app wants a fresh value), it may call a dedicated compatibility endpoint, e.g.:

- **GET /discovery/compatibility/:candidateId** (or **GET /profile/:id/compatibility**)

Response shape (align with existing discovery compatibility if present):

- **compatibilityScore** (number 0–1)
- **compatibilityLabel** (string)
- **matchReasons** (string[])
- **breakdown** (object, optional) – e.g. interests, preferences

The app’s `compatibilityProvider` uses this for the profile screen when the summary has no score.

---

## 4. Visits (profile view)

When the user opens a profile, the app sends:

- **POST /visits**
  - **profileId**: string
  - **source**: e.g. `"profile_view"` (or `"discovery"` when coming from the card)

Backend may:
- Dedupe by (viewer, profileId, source) within a short window (e.g. same session or same minute) to avoid double-counting if the client triggers the request twice.
- Use visits for analytics and “who viewed you” in dating/matches.

---

## 5. Summary table

| Area | Requirement |
|------|-------------|
| Pass / Like / Super like | Dating-only in the UI; backend accepts **mode** on feedback and interactions (see `march new.md`). |
| GET /profile/:id/summary | For dating, support **photoUrls** (array), **compatibilityScore**, **compatibilityLabel**, **sharedInterests**. |
| Compatibility endpoint | Optional; used when summary has no compatibility. Return score, label, matchReasons, breakdown. |
| POST /visits | Optional dedupe for same (viewer, profileId, source) in a short time window. |

Implementing the above aligns the backend with the app’s dating profile view: multiple photos, compatibility pill, highlighted shared interests, and Pass / Like / Super like actions only in dating mode.

---

## 6. Send message from profile (dating)

On the **dating** full profile screen, the app shows a **Message** button (no shortlist button). When the user taps it:

- **Premium** (or female, per entitlements): App creates/opens the thread and they can send normally.
- **Free** (e.g. male): App shows a gate: “Watch ad to send message (up to 5 per day)” or “Upgrade to Premium”. After they watch an ad, the app sends interest if needed, creates the thread, and opens the chat; the **first message** is sent with **`adCompletionToken`**. That message should go to the **recipient’s message requests** (dating), not straight to the main chat list.

Backend should:

- **POST /chat/threads/:threadId/messages** with **`adCompletionToken`**: treat as a message request (dating); enforce **max 5 per user per day**; if over limit return **403** with code **`DAILY_MESSAGE_AD_LIMIT_REACHED`**.
- Expose **message requests** (e.g. GET /chat/message-requests?mode=dating) and **accept/decline** so the recipient can see and act on these requests.

See **BACKEND_CHAT_INTEGRATION.md** §5a for full details.
