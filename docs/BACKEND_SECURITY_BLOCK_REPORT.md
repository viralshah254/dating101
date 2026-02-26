# Backend: Security — Block, Report, Blocked list, Unblock

Use this doc to implement the security/safety endpoints so the Saathi app can:

- Let users **block** or **report** others with a **reason**.
- Show **blocked users** in Privacy & safety and allow **unblock**.

---

## 1. Block (with reason)

The app sends block with a reason code so the backend can log and optionally enforce policies.

**Endpoint (recommended):** `POST /safety/block`  
*Alternative:* keep using `POST /discovery/feedback` with `action: "block"` and add optional `reason` (and optionally `source`) in the body.

**Request**

```http
POST /safety/block
Content-Type: application/json
Authorization: Bearer <accessToken>
```

```json
{
  "blockedUserId": "usr_xyz",
  "reason": "spam",
  "source": "profile"
}
```

| Field           | Type   | Required | Description |
|----------------|--------|----------|-------------|
| `blockedUserId`| string | Yes      | User ID being blocked. |
| `reason`       | string | Yes      | One of the reason codes below. |
| `source`       | string | No       | Where the block was triggered: `"profile"`, `"discover"`, `"shortlist"`, `"chat"`. |

**Block reason codes (app sends these):**

| Code                  | Label (app)              |
|-----------------------|--------------------------|
| `spam`                | Spam                     |
| `harassment`          | Harassment               |
| `inappropriate_content` | Inappropriate content  |
| `fake_profile`        | Fake profile             |
| `other`               | Other                    |

**Response**

- **200** — Block recorded. No body required; optional `{ "blockedAt": "2025-03-01T12:00:00Z" }`.
- **400** — Invalid body or reason (e.g. unknown `reason`).
- **401** — Unauthorized.

---

## 2. Report (with reason and optional details)

**Endpoint (recommended):** `POST /safety/report`  
*Alternative:* extend `POST /discovery/feedback` with `action: "report"` and body including `reason` and optional `details`.

**Request**

```http
POST /safety/report
Content-Type: application/json
Authorization: Bearer <accessToken>
```

```json
{
  "reportedUserId": "usr_xyz",
  "reason": "harassment",
  "details": "Optional free text from the user.",
  "source": "chat"
}
```

| Field            | Type   | Required | Description |
|-----------------|--------|----------|-------------|
| `reportedUserId`| string | Yes      | User ID being reported. |
| `reason`        | string | Yes      | One of the report reason codes below. |
| `details`       | string | No       | Optional additional context from the user. |
| `source`        | string | No       | Where the report was triggered. |

**Report reason codes (app sends these):**

| Code                    | Label (app)              |
|-------------------------|--------------------------|
| `spam`                  | Spam                     |
| `harassment`            | Harassment               |
| `inappropriate_photos`  | Inappropriate photos     |
| `fake_profile`          | Fake profile             |
| `scam`                  | Scam or fraud            |
| `other`                 | Other                    |

**Response**

- **200** — Report submitted. Optional body e.g. `{ "reportId": "rpt_abc" }`.
- **400** — Invalid body or reason.
- **401** — Unauthorized.

---

## 3. List blocked users (for Privacy & safety)

Used so the user can see who they have blocked and unblock them.

**Endpoint:** `GET /safety/blocked`

**Request**

```http
GET /safety/blocked?limit=50&cursor=
Authorization: Bearer <accessToken>
```

| Query   | Type   | Required | Description |
|---------|--------|----------|-------------|
| `limit` | number | No       | Default 50. |
| `cursor`| string | No       | For pagination. |

**Response 200**

```json
{
  "blocked": [
    {
      "blockedUserId": "usr_abc",
      "blockedAt": "2025-03-01T12:00:00Z",
      "profile": {
        "id": "usr_abc",
        "name": "Jane",
        "age": 28,
        "imageUrl": "https://cdn.../photo.jpg"
      }
    }
  ],
  "nextCursor": null
}
```

- `blocked[].profile` — Minimal profile for list/avatar (same shape as `GET /profile/:userId/summary` or at least `id`, `name`, `age`, `imageUrl`).
- `nextCursor` — Opaque cursor for next page; omit or null when no more.

---

## 4. Unblock

**Endpoint:** `DELETE /safety/blocked/:userId`

**Request**

```http
DELETE /safety/blocked/usr_xyz
Authorization: Bearer <accessToken>
```

- `:userId` — The blocked user’s ID (path segment).

**Response**

- **200** — Unblocked. No body required.
- **404** — That user was not in the current user’s blocked list.
- **401** — Unauthorized.

---

## 5. Compatibility with existing feedback endpoint

If you prefer not to add `/safety/block` and `/safety/report` yet, you can extend the existing discovery feedback:

**POST /discovery/feedback** (existing)

Current body example:

```json
{
  "candidateId": "usr_xyz",
  "action": "block",
  "source": "profile"
}
```

Extended body for block:

```json
{
  "candidateId": "usr_xyz",
  "action": "block",
  "source": "profile",
  "reason": "spam"
}
```

Extended body for report:

```json
{
  "candidateId": "usr_xyz",
  "action": "report",
  "source": "profile",
  "reason": "harassment",
  "details": "Optional user-provided text."
}
```

The app can send `reason` (and for report, `details`) in the same POST; backend can accept them and return 200. Block reason codes and report reason codes are as in §1 and §2 above.

---

## 6. Quick reference

| Action        | Method | Path                      | Auth | Body / query |
|---------------|--------|---------------------------|------|----------------|
| Block         | POST   | `/safety/block`           | Yes  | `blockedUserId`, `reason`, `source?` |
| Report        | POST   | `/safety/report`          | Yes  | `reportedUserId`, `reason`, `details?`, `source?` |
| List blocked  | GET    | `/safety/blocked`         | Yes  | `limit`, `cursor` |
| Unblock       | DELETE | `/safety/blocked/:userId` | Yes  | — |

If using discovery feedback only:

| Action | Method | Path                 | Body includes                          |
|--------|--------|----------------------|----------------------------------------|
| Block  | POST   | `/discovery/feedback`| `candidateId`, `action: "block"`, `reason`, `source?` |
| Report | POST   | `/discovery/feedback`| `candidateId`, `action: "report"`, `reason`, `details?`, `source?` |

---

## 7. App behaviour summary

- **Block:** User selects a reason (spam, harassment, inappropriate content, fake profile, other) → confirmation → API call with `reason`. Backend stores block and optional reason.
- **Report:** User selects a reason (spam, harassment, inappropriate photos, fake profile, scam, other) and optionally enters details → confirmation → API call with `reason` and `details`.
- **Privacy & safety → Blocked users:** App calls `GET /safety/blocked`, shows list with avatar/name and “Unblock” per row. On Unblock, app calls `DELETE /safety/blocked/:userId` and refreshes the list.
