# Backend: Account lifecycle (export, deactivate, reactivate, delete)

This document specifies the backend contract for **data export**, **deactivate**, **reactivate**, and **permanent delete**. The Flutter app uses these endpoints from **Profile & Settings → Account & data**.

**Related:** [BACKEND_CROSS_CUTTING.md §5.3](BACKEND_CROSS_CUTTING.md#53-account-and-data), [BACKEND_API_REFERENCE.md §6e](BACKEND_API_REFERENCE.md#6e-account-export-deactivate-delete).

---

## 1. Overview

| Action | Endpoint | Description |
|--------|----------|-------------|
| Download my data | POST /account/export | Request a copy of user data; backend emails when ready. |
| Deactivate account | POST /account/deactivate | Temporarily disable account (reversible). |
| Reactivate account | POST /account/reactivate | Restore a deactivated account. |
| Delete account | POST /account/delete | Permanently delete account (irreversible). |

All endpoints require **auth**: `Authorization: Bearer <accessToken>`.

**Reactivate flow (app behaviour):** When a deactivated user signs in (OTP) or opens the app with an existing token, the app calls **GET /profile/me** (or another authenticated endpoint). The backend must return **403** with body `{ "code": "ACCOUNT_DEACTIVATED", "message": "..." }` so the app can show a dialog: *"Your account is deactivated. Do you want to reactivate it?"* — **Yes** → app calls **POST /account/reactivate**, then continues to home; **No** → app signs out and returns to login. So any authenticated endpoint that would normally return profile or user data (e.g. **GET /profile/me**) should respond with **403 ACCOUNT_DEACTIVATED** when the account is deactivated, instead of returning data.

---

## 2. Request data export

**POST /account/export**

User taps “Download my data” in Settings. Backend should create an export job and notify the user (e.g. by email) when the data is ready.

**Request**

```http
POST /account/export
Content-Type: application/json
Authorization: Bearer <accessToken>
```

Body: empty `{}` or omitted.

**Success** `200 OK`

```json
{
  "requestId": "exp_abc123",
  "status": "pending",
  "message": "We'll email you when your data is ready."
}
```

| Field | Type | Description |
|-------|------|-------------|
| requestId | string | Unique ID for this export request (for status checks if you expose them). |
| status | string | e.g. `"pending"`. Optional: `"processing"`, `"ready"`. |
| message | string | Optional message shown in the app (e.g. “We'll email you when your data is ready.”). |

**Errors:** `401` Unauthorized.

---

## 3. Deactivate account

**POST /account/deactivate**

User taps “Deactivate account” and confirms. Account is hidden from discovery and matches; user can sign out. Reversible via **POST /account/reactivate** (e.g. when they log in again and choose to reactivate).

**Request**

```http
POST /account/deactivate
Content-Type: application/json
Authorization: Bearer <accessToken>
```

**Body** (optional)

```json
{
  "reason": "Taking a break"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| reason | string | No | Optional reason for deactivation (for analytics or support). |

**Success** `200 OK`

```json
{
  "deactivatedAt": "2026-03-07T12:00:00.000Z"
}
```

- Invalidate or mark the auth token as inactive so it can no longer be used for API calls.
- Hide the user’s profile from discovery and match lists.
- Optionally stop sending push notifications.

**Errors:** `401` Unauthorized.

---

## 4. Reactivate account

**POST /account/reactivate**

Called when a deactivated user signs in (or from a “Reactivate” flow). The app calls this only after the user has confirmed in the "Do you want to reactivate?" dialog (see Overview). Restores the account so the profile is visible again and the user can use the app normally.

**Request**

```http
POST /account/reactivate
Content-Type: application/json
Authorization: Bearer <accessToken>
```

Body: empty `{}` or omitted.

**Success** `200 OK`

```json
{
  "reactivatedAt": "2026-03-07T14:00:00.000Z"
}
```

- Restore profile visibility and full access.
- If the client sends a new FCM token after reactivation, associate it with the user as usual.

**Errors**

| HTTP | Code | When |
|------|------|------|
| 400 | ALREADY_ACTIVE | Account is not deactivated. |
| 401 | Unauthorized | Invalid or missing token. |

---

## 5. Permanently delete account

**POST /account/delete**

User taps “Delete account”, confirms in the first dialog, then **types “DELETE”** in the app to enable the final button. The app sends this confirmation word in the body so the backend can enforce that the client completed the extra step.

**Request**

```http
POST /account/delete
Content-Type: application/json
Authorization: Bearer <accessToken>
```

**Body**

```json
{
  "reason": "No longer using",
  "confirmation": "DELETE"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| reason | string | No | Optional reason (analytics/support). |
| confirmation | string | Recommended | The app sends `"DELETE"` when the user has typed it to confirm. Backend may require this for extra safety. |

**Success** `200 OK`

```json
{
  "deleted": true
}
```

- Permanently delete or anonymise user data and PII as required by policy.
- Invalidate all tokens for this user.
- Remove from discovery, matches, chats, etc.

**Errors**

| HTTP | Code | When |
|------|------|------|
| 400 | CONFIRMATION_REQUIRED | Body missing `confirmation: "DELETE"` if backend requires it. |
| 403 | ACTIVE_SUBSCRIPTION | User has an active paid subscription; require cancellation first. |
| 403 | PENDING_EXPORT | Optional: block delete while a data export is in progress. |
| 401 | Unauthorized | Invalid or missing token. |

---

## 6. Summary

| Method | Path | Body | Notes |
|--------|------|------|--------|
| POST | /account/export | `{}` | Returns requestId, status, message. |
| POST | /account/deactivate | `{ "reason"?: "..." }` | Reversible; invalidate token, hide profile. |
| POST | /account/reactivate | `{}` | Restore deactivated account. |
| POST | /account/delete | `{ "reason"?: "...", "confirmation"?: "DELETE" }` | Irreversible; app sends confirmation when user types DELETE. |

Implementing these four endpoints and the behaviours above supports the **Download my data**, **Deactivate account**, and **Delete account** flows in the app.
