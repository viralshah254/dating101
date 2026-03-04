# Docs to give backend team

Use this list when handing off to backend: what’s already connected, what’s left to build, and which docs to share.

---

## Status overview

- **98 endpoints** are **already connected** in the app (see [ENDPOINT_CONNECTION_STATUS.md](./ENDPOINT_CONNECTION_STATUS.md)). Backend must implement and maintain these.
- **3 items** are “remaining” from the app’s perspective: 2 optional (social login), 1 photo flow (app can use PATCH today).
- **7 endpoints** are in the API reference but **not yet called by the app** (notifications feed, boost IAP, POST /profile/me/photos). When backend has them, we’ll connect.

---

## Docs to give backend

| # | Topic | Document(s) |
|---|--------|-------------|
| 1 | **Full API** | Main **Shubhmilan Backend API Reference** (this repo / shared doc) |
| 2 | **What’s connected** | [ENDPOINT_CONNECTION_STATUS.md](./ENDPOINT_CONNECTION_STATUS.md) |
| 3 | **Connect vs build handoff** | [CONNECT_AND_BACKEND_HANDOFF.md](./CONNECT_AND_BACKEND_HANDOFF.md) |
| 4 | **Requests inbox (2/week ad unlock)** | [BACKEND_REQUESTS_INBOX_PREMIUM.md](./BACKEND_REQUESTS_INBOX_PREMIUM.md) |
| 5 | **Shortlisted you (5/week ad unlock)** | [BACKEND_SHORTLIST_RECEIVED_PREMIUM.md](./BACKEND_SHORTLIST_RECEIVED_PREMIUM.md) |
| 6 | **Chat (messages, ad, match rules)** | [chat_endpoint.md](./chat_endpoint.md), [BACKEND_CHAT_INTEGRATION.md](./BACKEND_CHAT_INTEGRATION.md) |
| 7 | **Subscription & IAP** | [BACKEND_SUBSCRIPTION_IAP.md](./BACKEND_SUBSCRIPTION_IAP.md) |
| 8 | **Boost (IAP + discovery)** | API reference §8.4a, [BACKEND_PREMIUM_ADS_BOOST.md](./BACKEND_PREMIUM_ADS_BOOST.md) |
| 9 | **In-app notifications** | API reference §6d.3, [BACKEND_PUSH_NOTIFICATIONS.md](./BACKEND_PUSH_NOTIFICATIONS.md) |
| 10 | **Photo upload & add-by-key** | API reference §2.8–2.10 |
| 11 | **Photo view requests** | [BACKEND_PHOTO_VISIBILITY_AND_VIEW_REQUESTS.md](./BACKEND_PHOTO_VISIBILITY_AND_VIEW_REQUESTS.md) |
| 12 | **Verification** | [BACKEND_VERIFICATION.md](./BACKEND_VERIFICATION.md) |
| 13 | **Social login (optional)** | API reference §1.5 — return 501 for `/auth/google`, `/auth/apple` |

---

## Remaining to build / optional

| Item | Backend action | Doc |
|------|----------------|-----|
| **POST /profile/me/photos** | Implement if you want “add by key” after S3 upload; app can use PATCH with photoUrls until then | API reference §2.9 |
| **In-app notification feed** | Implement GET /notifications, GET /notifications/unread-count, PATCH /notifications/:id/read, POST /notifications/mark-all-read | API reference §6d.3 |
| **Boost IAP** | Implement GET /boost/me, POST /boost/purchase (productId: boost_one_time) | [BACKEND_SUBSCRIPTION_IAP.md](./BACKEND_SUBSCRIPTION_IAP.md), §8.4a |
| **POST /auth/google, /auth/apple** | Optional; return 501 if not implemented | API reference §1.5 |

---

## Ready from backend — we’ll connect in app

When these are live, we’ll wire them in the app:

1. **POST /profile/me/photos** — add photo by key after upload  
2. **GET /notifications** — list in-app notifications  
3. **GET /notifications/unread-count** — badge count  
4. **PATCH /notifications/:id/read** — mark one read  
5. **POST /notifications/mark-all-read** — mark all read  
6. **GET /boost/me** — boost state  
7. **POST /boost/purchase** — purchase boost IAP  

See [CONNECT_AND_BACKEND_HANDOFF.md](./CONNECT_AND_BACKEND_HANDOFF.md) for details.
