# Connect vs backend handoff

From [ENDPOINT_CONNECTION_STATUS.md](./ENDPOINT_CONNECTION_STATUS.md) and the backend API reference.

- **✓ Connected** = App already calls the endpoint (98 total). Backend must support these for the app to work.
- **Ready from backend — connect** = Backend API exists (or will soon); app still needs to call it.
- **Not ready** = Backend to build or optional; give backend the listed docs.

---

## 1. Already connected (ready from backend — no app change)

**98 endpoints** are already wired in the app. Backend must implement and keep these live. Full list: [ENDPOINT_CONNECTION_STATUS.md](./ENDPOINT_CONNECTION_STATUS.md).

No action for “connect” — only ensure backend implements the contracts in the main API reference and the docs below where relevant.

---

## 2. Ready from backend — connect in app

These are in the **backend API reference** and the app does **not** call them yet. Once backend confirms they’re live, connect them in the app.

| # | Method | Endpoint | Purpose | App change |
|---|--------|----------|---------|------------|
| 1 | POST | /profile/me/photos | Add photo by key after S3 upload | After `photo_upload_service` uploads to S3, call this with `{ "key": "..." }` instead of (or in addition to) updating profile via PATCH with `photoUrls`. See §2.9 in API reference. |
| 2 | GET | /notifications | List in-app notifications (feed) | Add repository method + UI for notification center; query `limit`, `cursor`, `unreadOnly`. |
| 3 | GET | /notifications/unread-count | Badge count for notification icon | Add provider/call for nav badge. |
| 4 | PATCH | /notifications/:id/read | Mark one notification read | Call when user opens or dismisses a notification. |
| 5 | POST | /notifications/mark-all-read | Mark all read | Call from notification center “Mark all read”. |
| 6 | GET | /boost/me | Boost state (activeUntil, hoursRemainingToday) | Use for boost UI if app shows IAP boost separately from profile boost. |
| 7 | POST | /boost/purchase | Purchase boost IAP (productId: boost_one_time) | Use when user buys one-time boost IAP; see [BACKEND_SUBSCRIPTION_IAP.md](./BACKEND_SUBSCRIPTION_IAP.md). |

**Docs for implementation (app side):** Backend API reference §6d.1a (profile boost), §8.4a (boost IAP), §6d.3 (in-app notifications), §2.9 (POST /profile/me/photos).

---

## 3. Not ready — list and docs to give backend

Backend to implement or treat as optional. Give backend the following list and the linked docs.

### 3.1 Optional (not in app)

| Method | Endpoint | Note | Doc to give backend |
|--------|----------|------|---------------------|
| POST | /auth/google | Social login; app uses phone OTP only. Return 501 if not implemented. | Main API reference §1.5 |
| POST | /auth/apple | Social login; app uses phone OTP only. Return 501 if not implemented. | Main API reference §1.5 |

No app change planned; backend can document 501 for now.

---

### 3.2 POST /profile/me/photos (add photo by key)

- **Status:** In API reference (§2.9). App currently does **not** call it; app updates profile via **PATCH /profile/me** with new `photoUrls` after upload.
- **Options:**  
  - **A)** Backend supports both: (1) client calls POST /profile/me/photos with `key` after upload, and (2) client can still PATCH profile with `photoUrls`.  
  - **B)** Backend only supports POST /profile/me/photos; then app must be updated to call it (see §2 above).
- **Doc to give backend:** Main API reference §2.8 (upload-url), §2.9 (POST /profile/me/photos), §2.10 (DELETE). No separate doc; it’s in the main reference.

---

### 3.3 In-app notifications (feed)

If backend does **not** yet have the in-app notification feed:

- **Endpoints to build:**  
  - GET /notifications (query: limit, cursor, unreadOnly)  
  - GET /notifications/unread-count  
  - PATCH /notifications/:id/read  
  - POST /notifications/mark-all-read  
- **Doc to give backend:** Main API reference §6d.3 (In-app notifications). Also [BACKEND_PUSH_NOTIFICATIONS.md](./BACKEND_PUSH_NOTIFICATIONS.md) for relation to push and deep-link data.

---

### 3.4 Boost (IAP)

If backend does **not** yet have IAP boost:

- **Endpoints to build:** GET /boost/me, POST /boost/purchase (body: platform, receiptOrToken, productId e.g. `boost_one_time`).
- **Docs to give backend:**  
  - [BACKEND_SUBSCRIPTION_IAP.md](./BACKEND_SUBSCRIPTION_IAP.md) — product IDs (e.g. `boost_one_time`), pricing, receipt validation.  
  - [BACKEND_PREMIUM_ADS_BOOST.md](./BACKEND_PREMIUM_ADS_BOOST.md) — boost behaviour and discovery.  
  - Main API reference §8.4a (Boost IAP).

---

### 3.5 Requests inbox & shortlist (ad unlocks)

If backend already has these, they’re connected. If not:

- **Docs to give backend:**  
  - [BACKEND_REQUESTS_INBOX_PREMIUM.md](./BACKEND_REQUESTS_INBOX_PREMIUM.md) — 403 body, 2/week unlock, POST /interactions/received/unlock-one, InboxAdUnlock table.  
  - [BACKEND_SHORTLIST_RECEIVED_PREMIUM.md](./BACKEND_SHORTLIST_RECEIVED_PREMIUM.md) — 403 body, 5/week unlock, POST /shortlist/received/unlock-one.

---

### 3.6 Chat (messages, ad, match rules)

- **Docs to give backend:**  
  - [chat_endpoint.md](./chat_endpoint.md) — full request/response shapes, DTOs, errors.  
  - [BACKEND_CHAT_INTEGRATION.md](./BACKEND_CHAT_INTEGRATION.md) — match threads (no ad), adCompletionToken, message persistence.

---

### 3.7 Subscription & IAP

- **Doc to give backend:** [BACKEND_SUBSCRIPTION_IAP.md](./BACKEND_SUBSCRIPTION_IAP.md) — product IDs (`premium_monthly`, `boost_one_time`), dynamic pricing, restore, entitlements.

---

### 3.8 Photo view requests

- **Doc to give backend:** [BACKEND_PHOTO_VISIBILITY_AND_VIEW_REQUESTS.md](./BACKEND_PHOTO_VISIBILITY_AND_VIEW_REQUESTS.md) (or BACKEND_PHOTO_VISIBILITY_AND_REQUESTS.md if that’s the repo name). App uses GET /profile/:userId/photo-view-status and POST /photo-view-requests (body: targetUserId).

---

### 3.9 Safety (block / report)

- **Doc to give backend:** Backend API reference §3.3; if you have a dedicated doc, e.g. [CONNECT_FRONTEND_SAFETY.md](./CONNECT_FRONTEND_SAFETY.md) or BACKEND_SECURITY_BLOCK_REPORT.md, give that for request/response shapes.

---

### 3.10 Verification

- **Doc to give backend:** [BACKEND_VERIFICATION.md](./BACKEND_VERIFICATION.md) — ID upload, photo, LinkedIn, education; verificationStatus and score.

---

## 4. One-page “docs to give backend” checklist

Give backend this list plus the repo (or links to the docs):

| Topic | Doc(s) to give |
|--------|-----------------|
| **Full API contract** | Main **Shubhmilan Backend API Reference** (you already have this) |
| **Connection status** | [ENDPOINT_CONNECTION_STATUS.md](./ENDPOINT_CONNECTION_STATUS.md) — 98 connected, 3 remaining |
| **Requests inbox (2/week ad unlock)** | [BACKEND_REQUESTS_INBOX_PREMIUM.md](./BACKEND_REQUESTS_INBOX_PREMIUM.md) |
| **Shortlisted you (5/week ad unlock)** | [BACKEND_SHORTLIST_RECEIVED_PREMIUM.md](./BACKEND_SHORTLIST_RECEIVED_PREMIUM.md) |
| **Chat (threads, messages, ad, match)** | [chat_endpoint.md](./chat_endpoint.md), [BACKEND_CHAT_INTEGRATION.md](./BACKEND_CHAT_INTEGRATION.md) |
| **Subscription & IAP** | [BACKEND_SUBSCRIPTION_IAP.md](./BACKEND_SUBSCRIPTION_IAP.md) |
| **Boost (IAP + discovery)** | Main API reference §8.4a, [BACKEND_PREMIUM_ADS_BOOST.md](./BACKEND_PREMIUM_ADS_BOOST.md) |
| **In-app notifications** | Main API reference §6d.3, [BACKEND_PUSH_NOTIFICATIONS.md](./BACKEND_PUSH_NOTIFICATIONS.md) |
| **Photo upload & add-by-key** | Main API reference §2.8–2.10 |
| **Photo view requests** | [BACKEND_PHOTO_VISIBILITY_AND_VIEW_REQUESTS.md](./BACKEND_PHOTO_VISIBILITY_AND_VIEW_REQUESTS.md) |
| **Verification** | [BACKEND_VERIFICATION.md](./BACKEND_VERIFICATION.md) |
| **Social login (optional)** | Main API reference §1.5 — return 501 for /auth/google, /auth/apple |
| **Translate (UGC)** | [BACKEND_REMAINING_AND_TRANSLATION.md](./BACKEND_REMAINING_AND_TRANSLATION.md) — POST /translate and/or Accept-Language for profile content |
| **Referral (30 days Premium + contest)** | [BACKEND_REFERRAL.md](./BACKEND_REFERRAL.md) — referralCode in verify-otp, 30 days Premium, top referrer ₹1 lakh |

---

## 5. Summary table

| Category | Count | Action |
|----------|-------|--------|
| **Already connected** | 98 | Backend keeps these live; see [ENDPOINT_CONNECTION_STATUS.md](./ENDPOINT_CONNECTION_STATUS.md). |
| **Ready from backend — connect in app** | 7 | Wire when backend confirms: POST /profile/me/photos, GET/PATCH/POST /notifications*, GET /boost/me, POST /boost/purchase. |
| **Not ready / optional** | 2 + various | Give backend the “docs to give backend” list above; optional: /auth/google, /auth/apple (501). |

*\* GET /notifications, GET /notifications/unread-count, PATCH /notifications/:id/read, POST /notifications/mark-all-read*
