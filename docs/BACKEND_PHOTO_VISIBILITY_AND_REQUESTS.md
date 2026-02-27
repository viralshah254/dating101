# Photo visibility & photo view requests API

Backend specification for **hide my photos** and **request to view photos**. When a user hides their photos, others see a locked state and can send a "Request to view photos"; these requests appear in the Requests tab and can be approved or declined.

---

## 1. Overview

- **Photo visibility**: A user can set **photosHidden** in privacy. When `true`, their profile photos are not returned to other users unless the viewer has been **granted** access (see §4).
- **Request to view photos**: When viewing a profile with hidden photos, the viewer can send a **photo view request**. The profile owner sees it in **Requests** (alongside interest and contact requests) and can **Accept** or **Decline**.
- **After approval**: The backend records that the requester is allowed to view the owner's photos. Subsequent `GET /profile/:userId` for that owner by that requester returns `photoUrls` and `canViewPhotos: true`.

---

## 2. Privacy: hide my photos

### 2.1 GET /profile/me/privacy

**Response** must include:

| Field | Type | Description |
|-------|------|-------------|
| photosHidden | boolean | When `true`, my photos are hidden from others until they request and I approve. Default `false`. |

Example:

```json
{
  "showInVisitors": true,
  "profileVisibility": "everyone",
  "hideFromDiscovery": false,
  "photosHidden": false
}
```

### 2.2 PATCH /profile/me/privacy

**Request body** may include:

| Field | Type | Description |
|-------|------|-------------|
| photosHidden | boolean | Set to `true` to hide my photos; `false` to show them to everyone. |

Example:

```json
{
  "photosHidden": true
}
```

**Response**: Same shape as GET /profile/me/privacy (full privacy object).

---

## 3. Get another user's profile (photo visibility)

### 3.1 GET /profile/:userId

When the target user has **photosHidden: true** and the **caller does not** have permission to view their photos:

- Return the profile as usual **except**:
  - **photoUrls**: `[]` (empty array), or omit.
  - Include **photosHidden: true** and **canViewPhotos: false** so the app can show "Request to view photos" and locked photos UI.

When the target user has **photosHidden: false**, or the caller **has** been granted access:

- Return the profile with full **photoUrls** and **canViewPhotos: true** (or omit **photosHidden** / **canViewPhotos** for backward compatibility).

**Response fields** (add to existing profile response when applicable):

| Field | Type | Description |
|-------|------|-------------|
| photosHidden | boolean | Present when viewing another user. `true` if they hide their photos. |
| canViewPhotos | boolean | `true` if the caller is allowed to see this user's photos (either they don't hide, or they approved the caller's request). |

**Example (photos hidden, caller not allowed):**

```json
{
  "id": "usr_xyz",
  "name": "Priya",
  "photoUrls": [],
  "photosHidden": true,
  "canViewPhotos": false,
  ...
}
```

**Example (photos hidden, caller approved):**

```json
{
  "id": "usr_xyz",
  "name": "Priya",
  "photoUrls": ["https://..."],
  "photosHidden": true,
  "canViewPhotos": true,
  ...
}
```

---

## 4. Photo view requests

### 4.1 Send request to view photos

```http
POST /photo-view-requests
Content-Type: application/json
Authorization: Bearer <accessToken>
```

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| targetUserId | string | Yes | User whose photos the caller wants to view. |

**Example:**

```json
{
  "targetUserId": "usr_xyz"
}
```

**Success** `201 Created`

```json
{
  "requestId": "pvr_abc123",
  "targetUserId": "usr_xyz",
  "status": "pending",
  "createdAt": "2026-02-27T12:00:00Z"
}
```

**Errors:**

- `400`: Invalid targetUserId (e.g. self, or target has photosHidden: false).
- `409 Conflict`: Caller already has a pending or approved photo view for this user. Body: `{ "code": "ALREADY_REQUESTED" }` or `{ "code": "ALREADY_GRANTED" }`.

---

### 4.2 List received photo view requests

Used for the **Requests** tab: "Photo view" requests (someone requested to view my photos).

```http
GET /photo-view-requests/received
Authorization: Bearer <accessToken>
```

**Query params:**

| Param | Type | Description |
|-------|------|-------------|
| page | number | Default 1. |
| limit | number | Default 20. |
| status | string | Optional. `pending` (default for "Received" tab), `accepted`, `declined`. |

**Response** `200 OK`

```json
{
  "requests": [
    {
      "requestId": "pvr_abc123",
      "fromUser": {
        "id": "usr_requester",
        "name": "Rahul",
        "age": 28,
        "city": "Mumbai",
        "imageUrl": "https://...",
        "photoCount": 3
      },
      "status": "pending",
      "requestedAt": "2026-02-27T12:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "hasMore": false
  }
}
```

`fromUser` should match the app's **ProfileSummary** shape (id, name, age, city, imageUrl, photoCount, etc.) so the Requests card can show the requester.

---

### 4.3 Count of pending received photo view requests

For the Requests tab badge (include in "Received" count or as a separate count).

```http
GET /photo-view-requests/received/count
Authorization: Bearer <accessToken>
```

**Query (optional):**

| Param | Type | Description |
|-------|------|-------------|
| status | string | Default `pending`. |

**Response** `200 OK`

```json
{
  "count": 2
}
```

**Recommendation:** The app may sum **interest requests** + **contact requests** + **photo view requests** for the main Requests badge, or show photo view requests in the same "Received" tab with a label like "Requested to view your photos".

---

### 4.4 Accept photo view request

When the profile owner taps **Accept**, the requester is granted permission to view their photos.

```http
POST /photo-view-requests/:requestId/accept
Authorization: Bearer <accessToken>
```

**Success** `200 OK`

```json
{
  "requestId": "pvr_abc123",
  "status": "accepted"
}
```

**Backend must:** Store that the requester (fromUserId) is allowed to view the owner's (toUserId) photos. On subsequent `GET /profile/:userId` where userId is the owner and caller is the requester, return full photoUrls and canViewPhotos: true.

**Errors:** `404` if requestId not found or not for the current user.

---

### 4.5 Decline photo view request

```http
POST /photo-view-requests/:requestId/decline
Authorization: Bearer <accessToken>
```

**Request body (optional):**

```json
{
  "reason": "not_interested"
}
```

**Success** `200 OK`

```json
{
  "requestId": "pvr_abc123",
  "status": "declined"
}
```

---

## 5. Caller status: have I requested / can I view?

### 5.1 GET /profile/:userId/photo-view-status

So the app can show "Request to view photos", "Pending", or the actual photos.

```http
GET /profile/:userId/photo-view-status
Authorization: Bearer <accessToken>
```

**Response** `200 OK`

```json
{
  "status": "pending",
  "requestId": "pvr_abc123"
}
```

**status** values:

- **none** – Caller has not sent a request. App shows "Request to view photos".
- **pending** – Request sent, awaiting response. App shows "Request sent" / "Pending".
- **accepted** – Caller can view photos. App uses GET /profile/:userId and will receive photoUrls.
- **declined** – Owner declined. App may show "Request declined" and optionally allow "Request again" (backend can allow a new request after cooldown).

If the backend prefers to encode this in **GET /profile/:userId** (via canViewPhotos + optional photoViewStatus), that is also fine; the app will use whatever the profile endpoint returns.

---

## 6. Data model (suggested)

### PhotoViewRequest

| Field | Type | Description |
|-------|------|-------------|
| id | string | Primary key (e.g. pvr_xxx). |
| fromUserId | string | Requester (wants to view photos). |
| toUserId | string | Profile owner (has hidden photos). |
| status | enum | pending, accepted, declined. |
| createdAt | datetime | When the request was sent. |
| respondedAt | datetime | When owner accepted/declined (optional). |

### PhotoViewGrant (or equivalent)

After **accept**, store that fromUserId can view toUserId's photos.

| Field | Type | Description |
|-------|------|-------------|
| fromUserId | string | Requester. |
| toUserId | string | Profile owner. |
| grantedAt | datetime | When the request was accepted. |

When **GET /profile/:toUserId** is called by fromUserId, check this table; if a row exists, return photoUrls and canViewPhotos: true.

---

## 7. Summary

| Action | Method | Endpoint |
|--------|--------|----------|
| Get my privacy (incl. photosHidden) | GET | /profile/me/privacy |
| Update privacy (set photosHidden) | PATCH | /profile/me/privacy |
| Get another user's profile | GET | /profile/:userId (return photoUrls only when canViewPhotos) |
| Send photo view request | POST | /photo-view-requests { targetUserId } |
| List received photo view requests | GET | /photo-view-requests/received |
| Count pending received | GET | /photo-view-requests/received/count |
| Accept request | POST | /photo-view-requests/:requestId/accept |
| Decline request | POST | /photo-view-requests/:requestId/decline |
| My status for a profile (optional) | GET | /profile/:userId/photo-view-status |

---

## 8. App behavior

- **Profile owner**: Settings → "Hide my photos" toggle → PATCH /profile/me/privacy with photosHidden.
- **Viewer**: On full profile, if photosHidden && !canViewPhotos → show locked photos + "Request to view photos" (or "Pending" if status pending). On accept, requester's next GET /profile/:id will return photos.
- **Requests tab**: Show received photo view requests with Accept/Decline; include count in badge if desired.
