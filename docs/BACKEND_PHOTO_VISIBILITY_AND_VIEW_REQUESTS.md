# Saathi — Photo Visibility & Request to View Pictures: Backend Contract

Backend behaviour for **hiding profile photos** (all or some) and **request-to-view-pictures**: a viewer requests access to see another user’s photos; the profile owner receives the request and can **Accept** or **Decline**. When accepted, the requester can see the full photos on that profile.

**Related:** [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) (§6f), [BACKEND_CONTACT_REQUESTS.md](./BACKEND_CONTACT_REQUESTS.md) (same accept/decline pattern), [BACKEND_PROFILE_SECTIONS.md](./BACKEND_PROFILE_SECTIONS.md) (preferences / profile payload).

---

## 1. Overview

- **Photo visibility preference:** A user can set who can see their profile photos:
  - **`everyone`** (default) — all viewers see all photos.
  - **`on_request`** — photos are hidden until the viewer’s “request to view pictures” is **accepted** by the profile owner.
  - **`none`** — photos are never shown to others (no request flow).

- **Optional: per-photo visibility**  
  If the product supports “hide some, show some”, the backend can store which photo IDs are **locked** (only visible after request is accepted). When `photoVisibility` is `on_request`, typically **all** photos are locked; alternatively, the profile can have `lockedPhotoIds: string[]` so only those require access.

- **Request to view pictures:**  
  - Viewer A opens User B’s profile; B has `photoVisibility: on_request`. A sees placeholders (or “Request to view pictures”).
  - A sends a **photo view request** (one per profile). B sees it in **Received** (e.g. a “Photo requests” tab or a unified requests inbox with type `photo_view`).
  - B can **Accept** or **Decline**. On **Accept**, A is granted access to B’s photos (for that profile); A’s next **GET /profile/:userId** (or summary) returns full `photoUrls` for B. On **Decline**, A sees “Request declined” and optionally “Request again” (rate-limited).

- **Notifications:**  
  Backend should **notify the requester** when their photo view request is accepted or declined (push and/or in-app), so they can reopen the profile and see photos or the declined state.

---

## 2. Photo visibility preference (profile / preferences)

Stored on the user’s profile or in a dedicated preferences resource. The app will send this when the user changes “Who can see my photos” in **Preferences** (or a dedicated “Privacy” / “Photo visibility” section).

### 2.1 Profile / preferences payload

**Option A — part of existing profile (recommended)**

Use **PATCH /profile/me** with one of the following shapes (backend chooses one and documents it).

**Shape 1: Single visibility level**

```json
{
  "photoVisibility": "everyone"
}
```

| Value        | Meaning |
|-------------|--------|
| `everyone`  | Default. All viewers see all my photos. |
| `on_request`| My photos are hidden until I accept a “request to view pictures”. |
| `none`      | I don’t show photos to anyone; no request flow. |

**Shape 2: Visibility + optional locked photo IDs**

```json
{
  "photoVisibility": "on_request",
  "lockedPhotoIds": ["photo_1", "photo_2"]
}
```

- When `photoVisibility` is `on_request`, if `lockedPhotoIds` is omitted, **all** photos are considered locked (only visible after request accepted).
- If `lockedPhotoIds` is present, only those photo IDs are locked; other photos remain visible to everyone.

**Option B — dedicated endpoint**

If you prefer not to extend the profile document:

```http
PATCH /profile/me/photo-visibility
Content-Type: application/json
Authorization: Bearer <accessToken>
```

**Body:** same as above, e.g. `{ "photoVisibility": "on_request" }` or `{ "photoVisibility": "on_request", "lockedPhotoIds": ["photo_1"] }`.

**Success** `200 OK` — no body required, or return the updated profile / preferences.

---

### 2.2 Returning visibility to the app (self)

- **GET /profile/me** (or preferences) must return the current user’s `photoVisibility` and, if supported, `lockedPhotoIds`, so the app can show the correct preference in settings and when editing.

---

### 2.3 Profile response when another user views (GET /profile/:userId)

When the caller is **not** the profile owner (viewer):

- If profile owner’s `photoVisibility` is **`everyone`**: return full `photoUrls` as today.
- If **`none`**: return **no** photo URLs for this profile (e.g. `photoUrls: []` or omit), and optionally a flag `photoVisibility: "none"` so the app can show “Photos hidden” without a request CTA.
- If **`on_request`**:
  - If the **viewer has been granted** access (previous photo-view request accepted): return full `photoUrls`.
  - If the viewer has **no** grant:
    - Return **no** (or masked) photo URLs, e.g. `photoUrls: []` or placeholder URLs.
    - Include a field so the app can show “Request to view pictures” and know the request state (see §3.1).

Recommended response addition for **GET /profile/:userId** (and, if used, **GET /profile/summary/:userId**) when caller is a viewer:

| Field                   | Type    | Description |
|-------------------------|---------|-------------|
| `photoVisibility`       | string? | `everyone` \| `on_request` \| `none` (how the **owner** has set visibility). |
| `canViewPhotos`        | boolean | `true` if the **viewer** is allowed to see photos (owner is self, or visibility is everyone, or viewer’s request was accepted). |
| `photoViewRequestState`| string? | When owner has `on_request` and viewer is not granted: `none` \| `pending` \| `accepted` \| `declined`. Omit or `null` when `canViewPhotos` is already `true`. |

So the app can:
- Show full photos when `canViewPhotos === true`.
- Show “Request to view pictures” when `photoVisibility === 'on_request'` and `photoViewRequestState === 'none'`.
- Show “Request pending” when `photoViewRequestState === 'pending'`.
- Show “Request declined” / “Request again” when `photoViewRequestState === 'declined'`.

---

## 3. Request-to-view-pictures API

All endpoints require **Authorization: Bearer &lt;accessToken&gt;**.

### 3.1 Get photo view request status for a profile

Used when **viewing** a profile: has the current user requested to view this user’s pictures? What is the status?

```http
GET /photo-view-requests/status/:profileId
Authorization: Bearer <accessToken>
```

**Success** `200 OK`

```json
{
  "state": "none",
  "requestId": null
}
```

| Field      | Type   | Description |
|-----------|--------|-------------|
| state     | string | `none` \| `pending` \| `accepted` \| `declined` |
| requestId | string \| null | Present when state is not `none` (e.g. for reference or to withdraw). |

- **none:** No request sent.
- **pending:** Request sent; awaiting their response.
- **accepted:** They accepted; caller can now load this profile’s photos (GET /profile/:profileId returns full photoUrls when canViewPhotos is true).
- **declined:** They declined; caller may be allowed to “Request again” (backend may rate-limit).

If the backend prefers to embed this in the profile response, it can do so via `photoViewRequestState` (and optionally `photoViewRequestId`) on **GET /profile/:userId** instead of a separate status endpoint; the app can use either.

---

### 3.2 Send photo view request

```http
POST /photo-view-requests
Content-Type: application/json
Authorization: Bearer <accessToken>
```

**Body**

```json
{
  "toUserId": "usr_abc"
}
```

**Success** `201 Created` or `200 OK` — no body required, or return current status `{ "state": "pending", "requestId": "pvr_xyz" }`.

**Errors**

| HTTP | code           | When |
|------|----------------|------|
| 400  | ALREADY_SENT   | Photo view request already sent to this user. |
| 400  | NOT_APPLICABLE | Profile’s photos are visible to everyone or hidden entirely (no request flow). |
| 404  | NOT_FOUND      | toUserId invalid or no profile. |

---

### 3.3 Get received photo view requests

List of users who have requested **to view my photos** (pending, and optionally recent accepted/declined for context). Shown in the app under **Requests** (e.g. “Photo requests” tab or unified “Received” with type `photo_view`).

```http
GET /photo-view-requests/received?page=1&limit=20
Authorization: Bearer <accessToken>
```

**Success** `200 OK`

```json
{
  "requests": [
    {
      "requestId": "pvr_xyz",
      "fromUser": {
        "id": "usr_abc",
        "name": "Priya S",
        "age": 28,
        "city": "Mumbai",
        "imageUrl": "https://...",
        "verified": false
      },
      "requestedAt": "2026-02-27T10:00:00Z"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 5, "hasMore": false }
}
```

`fromUser` should be at least a minimal profile (id, name, age, imageUrl, etc.) so the recipient can recognise and accept/decline.

---

### 3.4 Accept photo view request

Recipient (profile owner) accepts; the requester is now allowed to see their photos. **Backend must send a notification to the requester** (e.g. “Priya accepted your request to view their photos”).

```http
POST /photo-view-requests/:requestId/accept
Authorization: Bearer <accessToken>
```

**Success** `200 OK` — no body required, or return `{ "accepted": true }`.

**Errors**

| HTTP | code     | When |
|------|----------|------|
| 404  | NOT_FOUND| requestId invalid or not a received request for this user. |

**Notification (requester):** Push and/or in-app so the requester can open the profile and see full photos.

---

### 3.5 Decline photo view request

Recipient declines. **Backend must send a notification to the requester** (e.g. “Priya declined your request to view their photos”).

```http
POST /photo-view-requests/:requestId/decline
Authorization: Bearer <accessToken>
```

**Success** `200 OK` — no body required, or return `{ "declined": true }`.

**Errors**

| HTTP | code     | When |
|------|----------|------|
| 404  | NOT_FOUND| requestId invalid or not a received request for this user. |

**Notification (requester):** Push and/or in-app so the requester sees “Request declined” and optionally “Request again” (if backend allows and rate-limits).

---

### 3.6 (Optional) Get sent photo view requests

If the app shows “Sent” photo requests (e.g. “Request to view pictures” sent by me):

```http
GET /photo-view-requests/sent?page=1&limit=20
Authorization: Bearer <accessToken>
```

**Success** `200 OK` — same shape as received, with `toUser` instead of `fromUser` and status per request (`pending` \| `accepted` \| `declined`).

---

### 3.7 (Optional) Withdraw request

If the requester can withdraw a **pending** request:

```http
DELETE /photo-view-requests/:requestId
Authorization: Bearer <accessToken>
```

**Success** `200 OK` or `204 No Content`. **Errors:** 404 if not found or not pending.

---

## 4. Notifications

| Event                | Recipient   | Suggested copy / payload |
|----------------------|------------|---------------------------|
| Photo view accepted  | Requester (A) | “{B.name} accepted your request to view their photos” — deep link to B’s profile. |
| Photo view declined  | Requester (A) | “{B.name} declined your request to view their photos” — optional deep link. |

Implementation is backend-specific (FCM, APNs, or in-app feed). After accept/decline, the requester’s next **GET /photo-view-requests/status/:profileId** (or **GET /profile/:profileId** with `photoViewRequestState`) should return the updated state.

---

## 5. Summary: endpoints to implement

| Method | Path | Description |
|--------|------|-------------|
| PATCH | /profile/me (or /profile/me/photo-visibility) | Set photoVisibility: `everyone` \| `on_request` \| `none`; optional lockedPhotoIds. |
| GET   | /profile/me | Return current user’s photoVisibility (and lockedPhotoIds if supported). |
| GET   | /profile/:userId | When caller is viewer: return canViewPhotos, photoVisibility, photoViewRequestState (or equivalent) and full/masked photoUrls. |
| GET   | /photo-view-requests/status/:profileId | Status of my request toward that profile: none \| pending \| accepted \| declined. |
| POST  | /photo-view-requests | Send photo view request (body: toUserId). |
| GET   | /photo-view-requests/received | Received photo view requests (query: page, limit). |
| POST  | /photo-view-requests/:requestId/accept | Accept; grant requester access to my photos; notify requester. |
| POST  | /photo-view-requests/:requestId/decline | Decline; notify requester. |
| GET   | /photo-view-requests/sent (optional) | Sent photo view requests. |
| DELETE| /photo-view-requests/:requestId (optional) | Withdraw pending request. |

---

## 6. Frontend integration (reference)

| Area | Purpose |
|------|--------|
| **Preferences / Privacy** | Setting: “Who can see my photos” → `everyone` / `on_request` / `none`; optional per-photo “lock” in photo gallery. Save via PATCH /profile/me (or dedicated endpoint). |
| **Profile view (viewer)** | If `canViewPhotos === false` and `photoVisibility === 'on_request'`: show “Request to view pictures”. If `photoViewRequestState === 'pending'`: show “Request pending”. If `accepted`: show full photos. If `declined`: show “Request declined” and optionally “Request again”. |
| **Requests screen** | “Photo requests” tab (or unified Received with type) → GET /photo-view-requests/received; each card: fromUser, “Accept” / “Decline” → POST accept or decline; invalidate list and notify requester. |
| **Status on profile** | Before showing “Request to view pictures”, call GET /photo-view-requests/status/:profileId (or use profile’s photoViewRequestState) to show correct CTA. |

This contract allows the app to implement hide-photos preferences and request-to-view-pictures with accept/decline and notifications, and to connect to the backend once these endpoints and profile fields are implemented.
