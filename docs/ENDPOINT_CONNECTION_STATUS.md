# Endpoint connection status

Status of each API endpoint: **✓ Connected** = app calls it (frontend integrated), **○ Remaining** = not yet connected or backend not built.

Last updated from `BACKEND_API_REFERENCE.md` Quick reference and codebase scan.

---

## 1. Auth API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | POST | /auth/send-otp | `api_auth_repository` |
| ✓ | POST | /auth/verify-otp | `api_auth_repository` |
| ✓ | POST | /auth/refresh | `api_client` (token refresh) |
| ✓ | POST | /auth/sign-out | `api_auth_repository` |
| ○ | POST | /auth/google | Not implemented in app (doc: 501) |
| ○ | POST | /auth/apple | Not implemented in app (doc: 501) |

---

## 2. Profile API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | GET | /profile/me | `api_profile_repository` |
| ✓ | PATCH | /profile/me | `api_profile_repository` |
| ✓ | PUT | /profile/me | `api_profile_repository` (create/replace) |
| ✓ | GET | /profile/me/preferences | `api_profile_repository` |
| ✓ | PUT | /profile/me/preferences | `api_profile_repository` |
| ✓ | GET | /profile/:userId | `api_profile_repository` |
| ✓ | GET | /profile/:userId/summary | `api_profile_repository` |
| ✓ | POST | /profile/me/photos/upload-url | `photo_upload_service` |
| ✓ | POST | /profile/me/photos | `photo_upload_service` (after S3 upload) |
| ✓ | DELETE | /profile/me/photos/:key | `photo_upload_service` |
| ✓ | GET | /profile/me/privacy | `api_profile_repository` |
| ✓ | PATCH | /profile/me/privacy | `api_profile_repository` |
| ✓ | GET | /profile/me/notifications | `api_profile_repository` |
| ✓ | PATCH | /profile/me/notifications | `api_profile_repository` |
| ✓ | POST | /profile/me/fcm-token | `api_profile_repository` |
| ✓ | DELETE | /profile/me/fcm-token | `api_profile_repository` |
| ✓ | POST | /profile/me/boost | `api_profile_repository` |
| ✓ | GET | /profile/:userId/photo-view-status | `api_photo_view_request_repository` |

---

## 3. Security & location

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | POST | /security/location | `security_service` |

---

## 4. Safety API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | POST | /safety/block | `api_safety_repository` |
| ✓ | POST | /safety/report | `api_safety_repository` |
| ✓ | GET | /safety/blocked | `api_safety_repository` |
| ✓ | DELETE | /safety/blocked/:userId | `api_safety_repository` |

---

## 5. Discovery API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | GET | /discovery/recommended | `api_discovery_repository` |
| ✓ | GET | /discovery/explore | `api_discovery_repository` |
| ✓ | GET | /discovery/filter-options | `api_discovery_repository` |
| ✓ | GET | /discovery/compatibility/:candidateId | `api_discovery_repository` |
| ✓ | GET | /discovery/saved-searches | `api_discovery_repository` |
| ✓ | POST | /discovery/saved-searches | `api_discovery_repository` |
| ✓ | PATCH | /discovery/saved-searches/:id | `api_discovery_repository` |
| ✓ | DELETE | /discovery/saved-searches/:id | `api_discovery_repository` |
| ✓ | POST | /discovery/saved-searches/:id/viewed | `api_discovery_repository` |
| ✓ | GET | /discovery/search | `api_discovery_repository` |
| ✓ | GET | /discovery/nearby | `api_discovery_repository` |
| ✓ | GET | /discovery/preferences | `api_discovery_repository` |
| ✓ | POST | /discovery/feedback | `api_discovery_repository` |

---

## 6. Interests API (§5 — dating)

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | POST | /interests | `api_interests_repository` |
| ✓ | GET | /interests/received | `api_interests_repository` |
| ✓ | GET | /interests/sent | `api_interests_repository` |
| ✓ | POST | /interests/:interestId/accept | `api_interests_repository` |
| ✓ | POST | /interests/:interestId/decline | `api_interests_repository` |
| ✓ | DELETE | /interests/:interestId | `api_interests_repository` |

---

## 7. Interactions API (§5a — Shubhmilan)

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | POST | /interactions/interest | `api_interactions_repository` |
| ✓ | POST | /interactions/priority-interest | `api_interactions_repository` |
| ✓ | PATCH | /interactions/:interactionId | `api_interactions_repository` (accept/decline) |
| ✓ | DELETE | /interactions/:interactionId | `api_interactions_repository` (withdraw) |
| ✓ | GET | /interactions/received | `api_interactions_repository` |
| ✓ | GET | /interactions/received/count | `api_interactions_repository` |
| ✓ | POST | /interactions/received/unlock-one | `api_interactions_repository` |
| ✓ | GET | /interactions/sent | `api_interactions_repository` |

---

## 8. Shortlist API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | GET | /shortlist | `api_shortlist_repository` |
| ✓ | POST | /shortlist | `api_shortlist_repository` |
| ✓ | PATCH | /shortlist/:shortlistId | `api_shortlist_repository` |
| ✓ | DELETE | /shortlist/:profileId | `api_shortlist_repository` |
| ✓ | GET | /shortlist/:userId/check | `api_shortlist_repository` |
| ✓ | GET | /shortlist/received | `api_shortlist_repository` |
| ✓ | GET | /shortlist/received/count | `api_shortlist_repository` |
| ✓ | POST | /shortlist/received/unlock-one | `api_shortlist_repository` |

---

## 9. Contact requests API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | GET | /contact-requests/status/:profileId | `api_contact_request_repository` |
| ✓ | POST | /contact-requests | `api_contact_request_repository` |
| ✓ | GET | /contact-requests/received/count | `api_contact_request_repository` |
| ✓ | GET | /contact-requests/received | `api_contact_request_repository` |
| ✓ | POST | /contact-requests/:requestId/accept | `api_contact_request_repository` |
| ✓ | POST | /contact-requests/:requestId/decline | `api_contact_request_repository` |

---

## 10. Photo view requests API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | GET | /profile/:userId/photo-view-status | `api_photo_view_request_repository` |
| ✓ | POST | /photo-view-requests | `api_photo_view_request_repository` |
| ✓ | GET | /photo-view-requests/received | `api_photo_view_request_repository` |
| ✓ | GET | /photo-view-requests/received/count | `api_photo_view_request_repository` |
| ✓ | POST | /photo-view-requests/:requestId/accept | `api_photo_view_request_repository` |
| ✓ | POST | /photo-view-requests/:requestId/decline | `api_photo_view_request_repository` |

---

## 11. Account API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | POST | /account/export | `api_account_repository` |
| ✓ | POST | /account/deactivate | `api_account_repository` |
| ✓ | POST | /account/reactivate | `api_account_repository` |
| ✓ | POST | /account/delete | `api_account_repository` |

---

## 12. Visits API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | POST | /visits | `api_visits_repository` |
| ✓ | GET | /visits/received | `api_visits_repository` |
| ✓ | POST | /visits/mark-seen | `api_visits_repository` |

---

## 13. Matches API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | GET | /matches | `api_matches_repository` |
| ✓ | DELETE | /matches/:matchId | `api_matches_repository` |

---

## 14. Chat API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | GET | /chat/threads | `api_chat_repository` |
| ✓ | POST | /chat/threads | `api_chat_repository` (get or create) |
| ✓ | GET | /chat/threads/:threadId/messages | `api_chat_repository` |
| ✓ | POST | /chat/threads/:threadId/messages | `api_chat_repository` |
| ✓ | POST | /chat/threads/:threadId/read | `api_chat_repository` |
| ✓ | GET | /chat/suggestions | `api_chat_repository` |
| ✓ | GET | /chat/message-requests | `api_chat_repository` |
| ✓ | POST | /chat/message-requests/:requestId/accept | `api_chat_repository` |
| ✓ | POST | /chat/message-requests/:requestId/decline | `api_chat_repository` |

---

## 15. Translate

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ○ | POST | /translate | **Backend does not have** — no translate route/service. App calls via `api_translate_repository` and degrades gracefully (returns null on 404/501). |

---

## 16. Referral API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | GET | /referral | `api_referral_repository` |
| ✓ | POST | /referral/invite | `api_referral_repository` |

---

## 17. Verification API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | POST | /verification/id/upload-url | `api_verification_repository` |
| ✓ | POST | /verification/id/submit | `api_verification_repository` |
| ✓ | POST | /verification/photo | `api_verification_repository` |
| ✓ | GET | /verification/linkedin/auth-url | `api_verification_repository` |
| ✓ | POST | /verification/linkedin/callback | `api_verification_repository` |
| ✓ | POST | /verification/education | `api_verification_repository` |

---

## 18. Subscription & Boost API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | GET | /subscription/me | `api_subscription_repository` |
| ✓ | POST | /subscription/purchase | `api_subscription_repository` |
| ✓ | POST | /subscription/restore | `api_subscription_repository` |
| ✓ | GET | /subscription/entitlements | `api_subscription_repository` |
| ✓ | GET | /boost/me | `api_subscription_repository` |
| ✓ | POST | /boost/purchase | `api_subscription_repository` |

---

## 19. In-app Notifications API

| Status | Method | Endpoint | Notes |
|--------|--------|----------|-------|
| ✓ | GET | /notifications | `api_notifications_repository` |
| ✓ | GET | /notifications/unread-count | `api_notifications_repository` |
| ✓ | PATCH | /notifications/:id/read | `api_notifications_repository` |
| ✓ | POST | /notifications/mark-all-read | `api_notifications_repository` |

---

## Summary

| | Count |
|---|-------|
| **✓ Connected** | **107** |
| **○ Remaining** | **3** |

### Remaining to connect / build

1. **POST /auth/google** — Social login (doc: 501 Not Implemented); app uses phone OTP only.
2. **POST /auth/apple** — Social login (doc: 501 Not Implemented); app uses phone OTP only.
3. **POST /translate** — **Backend does not have** (no translate route or service). App calls it and degrades gracefully (returns null on 404/501). Translation can be done client-side or via another service until backend implements it.

---

---

**Handoff:** See [CONNECT_AND_BACKEND_HANDOFF.md](./CONNECT_AND_BACKEND_HANDOFF.md) for “ready from backend — connect in app” vs “not ready — docs for backend”. One-page list for backend: [DOCS_FOR_BACKEND.md](./DOCS_FOR_BACKEND.md). **What's remaining + translate UGC:** [BACKEND_REMAINING_AND_TRANSLATION.md](./BACKEND_REMAINING_AND_TRANSLATION.md).

*Generated from `lib/data/repositories_api/*.dart`, `lib/data/services/*.dart`, and `lib/data/api/api_client.dart`.*
