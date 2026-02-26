# Saathi — Contact Requests: Backend Contract

Backend behaviour for **requesting another user's contact** (phone), **accept/decline** by the recipient, and **notifications** on accept/decline. When accepted, the requester sees **View contacts** with Call and WhatsApp actions.

**Related:** [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md), [BACKEND_REQUESTS_SHORTLIST_FAMILY.md](./BACKEND_REQUESTS_SHORTLIST_FAMILY.md) (§ contact request gating).

---

## 1. Overview

- **Contact request:** User A requests User B's contact (e.g. phone number). B sees the request in "Contact requests" and can **Accept** or **Decline**.
- **On Accept:** B's shared contact (e.g. phone) is revealed to A. A sees **View contacts** on B's profile with **Call** and **WhatsApp** actions. The backend must **notify A** (push or in-app) that their contact request was accepted.
- **On Decline:** The backend must **notify A** (push or in-app) that their contact request was declined. A may see "Request declined" and optionally "Request again".

Contact request gating (e.g. only after mutual match or premium) is enforced by the app using existing entitlements and match state; the backend may enforce the same rules.

---

## 2. API (to implement)

### 2.1 Get contact request status for a profile

Used when viewing a profile: has the current user requested this profile's contact? What is the status?

```http
GET /contact-requests/status/:profileId
Authorization: Bearer <accessToken>
```

**Success** `200 OK`

```json
{
  "state": "none",
  "requestId": null,
  "sharedPhone": null,
  "sharedAt": null
}
```

| Field        | Type   | Description |
|-------------|--------|-------------|
| state       | string | `none` \| `pending` \| `accepted` \| `declined` |
| requestId   | string \| null | Present when state is not `none` (for reference). |
| sharedPhone | string \| null | When `state` is `accepted`, the phone number shared for Call/WhatsApp. E.g. `+919876543210`. |
| sharedAt    | string \| null | ISO 8601 datetime when contact was shared (when accepted). |

- **none:** No request sent.
- **pending:** Request sent; awaiting their response.
- **accepted:** They accepted; `sharedPhone` (and optionally `sharedAt`) is populated.
- **declined:** They declined; requester can be allowed to "Request again" (backend may rate-limit).

---

### 2.2 Send contact request

```http
POST /contact-requests
Content-Type: application/json
Authorization: Bearer <accessToken>
```

**Body**

```json
{
  "toUserId": "usr_abc"
}
```

**Success** `201 Created` or `200 OK` — no body required, or return current status.

**Errors**

| HTTP | code              | When |
|------|-------------------|------|
| 400  | ALREADY_SENT      | Contact request already sent to this user. |
| 403  | GATING_NOT_MET    | Requester does not meet contact-request rules (e.g. not matched or not entitled). |
| 404  | NOT_FOUND         | toUserId invalid or no profile. |

---

### 2.3 Get received contact requests

List of users who have requested **my** contact (pending only, or include recent accepted/declined for context).

```http
GET /contact-requests/received?page=1&limit=20
Authorization: Bearer <accessToken>
```

**Success** `200 OK`

```json
{
  "requests": [
    {
      "requestId": "cr_xyz",
      "fromUser": {
        "id": "usr_abc",
        "name": "Priya S",
        "age": 28,
        "city": "Mumbai",
        "imageUrl": "https://...",
        "verified": false
      },
      "requestedAt": "2026-02-26T10:00:00Z"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 5, "hasMore": false }
}
```

`fromUser` should be at least a minimal profile (id, name, age, imageUrl, etc.) for the recipient to recognise and accept/decline.

---

### 2.4 Accept contact request

Recipient accepts; their contact (e.g. phone) is shared with the requester. **Backend must send a notification to the requester** (e.g. "Priya shared their contact with you").

```http
POST /contact-requests/:requestId/accept
Authorization: Bearer <accessToken>
```

**Success** `200 OK` — body optional (e.g. `{ "accepted": true }`).

**Errors**

| HTTP | code     | When |
|------|----------|------|
| 404  | NOT_FOUND | requestId invalid or not a request to the current user. |

**Notification (requester):** Push and/or in-app notification that their contact request was accepted so they can open the profile and see "View contacts".

---

### 2.5 Decline contact request

Recipient declines. **Backend must send a notification to the requester** (e.g. "Priya declined your contact request").

```http
POST /contact-requests/:requestId/decline
Authorization: Bearer <accessToken>
```

**Success** `200 OK` — body optional.

**Errors**

| HTTP | code     | When |
|------|----------|------|
| 404  | NOT_FOUND | requestId invalid or not a request to the current user. |

**Notification (requester):** Push and/or in-app notification that their contact request was declined.

---

## 3. Notifications

| Event              | Recipient   | Action |
|--------------------|------------|--------|
| Contact accepted   | Requester (A) | Notify A that B accepted; A can now see "View contacts" (Call/WhatsApp) for B. |
| Contact declined   | Requester (A) | Notify A that B declined (optional in-app message). |

Implementation is backend-specific (FCM, APNs, or in-app feed). The frontend expects that after accept/decline, the requester’s next **GET /contact-requests/status/:profileId** returns the updated state; push is for timely awareness.

---

## 4. Frontend usage

| Feature                    | Backend                         | Frontend |
|---------------------------|----------------------------------|----------|
| Request contact           | POST /contact-requests           | "Request contact" on full profile (when gating allows). |
| Status on profile         | GET /contact-requests/status/:id | Show Request contact / Pending / View contacts / Declined. |
| View contacts (Call/WA)   | sharedPhone from status          | "View contacts" row with Call (tel:) and WhatsApp (wa.me) buttons. |
| Received list             | GET /contact-requests/received   | "Contact requests" tab in Requests screen. |
| Accept                    | POST .../accept                  | Accept button; invalidate status + received list; notify requester. |
| Decline                   | POST .../decline                 | Decline button; invalidate list; notify requester. |

---

## 5. References

- [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) — Base URL, auth, errors.
- [BACKEND_REQUESTS_SHORTLIST_FAMILY.md](./BACKEND_REQUESTS_SHORTLIST_FAMILY.md) — Contact request gating (when the button is enabled).
