# Shubhmilan Backend — Complete API List for Frontend

Single source of truth for all public API endpoints. Base URL: `https://api.saathi.app` (local: `http://localhost:3000`). Auth = `Authorization: Bearer <accessToken>` unless marked "No".

**Note:** The Flutter app uses **POST /account/delete** (not DELETE /account) for account deletion; backend may support either.

## Auth (no auth)
| Method | Path | Purpose |
|--------|------|---------|
| POST | /auth/send-otp | Send OTP (body: countryCode, phone) |
| POST | /auth/verify-otp | Verify OTP, get tokens (body: verificationId, code) |
| POST | /auth/refresh | Refresh access token (body: refreshToken) |
| POST | /auth/google | Google sign-in (501) |
| POST | /auth/apple | Apple sign-in (501) |

## Auth (with auth)
| Method | Path | Purpose |
|--------|------|---------|
| POST | /auth/sign-out | Sign out |

## Profile
| Method | Path | Purpose |
|--------|------|---------|
| GET | /profile/me | Get my profile |
| PATCH | /profile/me | Partial update profile |
| PUT | /profile/me | Replace full profile |
| GET | /profile/me/preferences | Get partner preferences |
| PUT | /profile/me/preferences | Update preferences |
| GET | /profile/:userId | Get profile by id |
| GET | /profile/:userId/summary | Get ProfileSummary |
| POST | /profile/me/photos/upload-url | Get S3 presigned URL(s) (body: count?) |
| POST | /profile/me/photos | Add photo after upload (body: key) |
| DELETE | /profile/me/photos/:key | Delete photo |
| POST | /profile/me/fcm-token | Register FCM token (body: fcmToken) |
| DELETE | /profile/me/fcm-token | Remove FCM token (body: fcmToken?) |
| GET | /profile/me/privacy | Get privacy settings |
| PATCH | /profile/me/privacy | Update privacy (showInVisitors, profileVisibility, hideFromDiscovery, photosHidden) |
| POST | /profile/me/boost | Start boost (body: durationHours?) |
| GET | /profile/me/notifications | Get notification preferences |
| PATCH | /profile/me/notifications | Update notification preferences |

## Security & safety
| Method | Path | Purpose |
|--------|------|---------|
| POST | /security/location | Record location (body: lat, lng, address?) |
| POST | /safety/block | Block user (body: blockedUserId, reason, source?) |
| POST | /safety/report | Report user (body: reportedUserId, reason, details?, source?) |
| GET | /safety/blocked | List blocked (query: limit?, cursor?) |
| DELETE | /safety/blocked/:userId | Unblock user |

## Discovery
| Method | Path | Purpose |
|--------|------|---------|
| GET | /discovery/recommended | Recommended stack (query: mode, limit?, cursor?, city?) |
| GET | /discovery/explore | Explore with filters (query: mode, limit?, cursor?, ageMin?, ageMax?, city?, religion?, education?, heightMinCm?, heightMaxCm?, preferredBodyTypes?, diet?) |
| GET | /discovery/search | Search (query: ageMin?, ageMax?, city?, religion?, education?, heightMinCm?, limit?, cursor?) |
| GET | /discovery/nearby | Nearby profiles (query: lat, lng, radiusKm?, limit?, cursor?) |
| GET | /discovery/compatibility/:candidateId | Compatibility detail (query: mode?) |
| POST | /discovery/feedback | Record like/pass/superlike/block/report/view (body: candidateId, action, timeSpentMs?, source?, reason?, details?) |
| GET | /discovery/preferences | Discovery preferences (age, religions, motherTongues, strictFilters) |
| GET | /discovery/filter-options | Filter options for UI |
| GET | /discovery/saved-searches | List saved searches |
| POST | /discovery/saved-searches | Create saved search (body: name?, filters, notifyOnNewMatch?) |
| PATCH | /discovery/saved-searches/:id | Update saved search (body: name?, notifyOnNewMatch?) |
| DELETE | /discovery/saved-searches/:id | Delete saved search |
| POST | /discovery/saved-searches/:id/viewed | Mark search viewed |

## Subscription & IAP
| Method | Path | Purpose |
|--------|------|---------|
| GET | /subscription/me | My subscription state |
| GET | /subscription/entitlements | Feature flags (canSeeRequestsInbox, etc.) |
| POST | /subscription/purchase | Purchase (body: platform, receiptOrToken, planId) |
| POST | /subscription/restore | Restore purchases (body: platform, receiptOrToken) |

## Shortlist
| Method | Path | Purpose |
|--------|------|---------|
| GET | /shortlist | My shortlist (query: page?, limit?, sort?) |
| POST | /shortlist | Add to shortlist (body: profileId, note?) |
| PATCH | /shortlist/:shortlistId | Update entry (body: note?, sortOrder?) |
| DELETE | /shortlist/:profileId | Remove from shortlist |
| GET | /shortlist/:userId/check | Check if user is shortlisted |
| GET | /shortlist/received | Who shortlisted me (403 + count/quota if free; query: page?, limit?) |
| GET | /shortlist/received/count | Shortlist received count |
| POST | /shortlist/received/unlock-one | Unlock one shortlister after ad (body: adCompletionToken) |

## Interactions (interests, requests inbox)
| Method | Path | Purpose |
|--------|------|---------|
| POST | /interactions/interest | Send interest (body: toUserId, source?) |
| POST | /interactions/priority-interest | Send priority interest (body: toUserId, message?, source?, adCompletionToken?) |
| PATCH | /interactions/:interactionId | Accept or decline (body: action: "accept" \| "decline", message?, reasonId?) |
| DELETE | /interactions/:interactionId | Withdraw interest |
| GET | /interactions/sent | Sent interests (query: status?, page?, limit?, type?) |
| GET | /interactions/received | Received / requests inbox (403 + count/quota if free; query: status?, page?, limit?, type?) |
| GET | /interactions/received/count | Badge count (query: status?) |
| POST | /interactions/received/unlock-one | Unlock one request after ad (body: adCompletionToken) |

## Contact requests (alternate flow)
| Method | Path | Purpose |
|--------|------|---------|
| GET | /contact-requests/status/:profileId | Status with profile |
| POST | /contact-requests | Create request (body: toUserId) |
| GET | /contact-requests/received/count | Received count |
| GET | /contact-requests/received | Received list (query: page?, limit?) |
| POST | /contact-requests/:requestId/accept | Accept request |
| POST | /contact-requests/:requestId/decline | Decline request |

## Requests (unlock by type)
| Method | Path | Purpose |
|--------|------|---------|
| POST | /requests/unlock | Unlock one request after ad (body: requestType, requestId, adCompletionToken; requestType: contact \| photo_view \| interest) |

## Chat
| Method | Path | Purpose |
|--------|------|---------|
| POST | /chat/threads | Get or create thread (body: otherUserId, mode: "dating" \| "matrimony") |
| GET | /chat/threads | List threads (query: mode, limit?, cursor?) |
| GET | /chat/threads/:threadId/messages | Messages (query: limit?, cursor?) |
| POST | /chat/threads/:threadId/messages | Send message (body: text, adCompletionToken?) |
| POST | /chat/threads/:threadId/read | Mark thread read |
| GET | /chat/message-requests | Message requests (query: limit?) |
| POST | /chat/message-requests/:requestId/accept | Accept message request |
| POST | /chat/message-requests/:requestId/decline | Decline message request |
| GET | /chat/suggestions | Chat suggestions (query: mode?) |

## Visits
| Method | Path | Purpose |
|--------|------|---------|
| POST | /visits | Record visit (body: profileId, source?, durationMs?) |
| GET | /visits/received | Who visited me (query: page?, limit?) |
| POST | /visits/mark-seen | Mark received visits as seen |

## Matches
| Method | Path | Purpose |
|--------|------|---------|
| GET | /matches | List matches (query: page?, limit?) |
| DELETE | /matches/:matchId | Unmatch / delete match |

## Photo view requests
| Method | Path | Purpose |
|--------|------|---------|
| POST | /photo-view-requests | Request to view photos (body: targetUserId) |
| GET | /photo-view-requests/received | Received requests (query: status?, page?, limit?) |
| GET | /photo-view-requests/received/count | Received count (query: status?) |
| POST | /photo-view-requests/:requestId/accept | Accept request |
| POST | /photo-view-requests/:requestId/decline | Decline request (body: reason?) |
| GET | /profile/:userId/photo-view-status | Photo view status with user (profile route) |

## Referral
| Method | Path | Purpose |
|--------|------|---------|
| GET | /referral | My referral info/code |
| POST | /referral/invite | Record invite (body: channel?) |

## Verification
| Method | Path | Purpose |
|--------|------|---------|
| POST | /verification/id/upload-url | Get ID upload URL (body: type?: passport \| driving_licence) |
| POST | /verification/id/submit | Submit ID (body: key) |
| POST | /verification/photo | Submit photo verification (body: key?) |
| POST | /verification/education | Submit education (body: institutionName?, degree?, documentKey?) |
| GET | /verification/linkedin/auth-url | LinkedIn OAuth URL |
| GET | /verification/linkedin/callback | LinkedIn callback (query: code) |
| POST | /verification/linkedin/callback | LinkedIn callback (body: code) |

## Account
| Method | Path | Purpose |
|--------|------|---------|
| POST | /account/export | Request data export |
| POST | /account/reactivate | Reactivate account |
| DELETE | /account | Delete account (body: reason?, password?) — **App uses POST /account/delete** |
| POST | /account/deactivate | Deactivate account (body: reason?) |
| POST | /account/delete | Permanently delete account (body: reason?) — **used by app** |

## Boost
| Method | Path | Purpose |
|--------|------|---------|
| GET | /boost/me | My boost status |
| POST | /profile/me/boost | Start boost (body: durationHours?) — see Profile |

## Notifications (in-app feed)
| Method | Path | Purpose |
|--------|------|---------|
| GET | /notifications | List notifications (query: limit?, cursor?, unreadOnly?) |
| GET | /notifications/unread-count | Unread notification count |
| PATCH | /notifications/:id/read | Mark one notification read |
| POST | /notifications/mark-all-read | Mark all as read |

## Cron (internal; header: x-cron-secret)
| Method | Path | Purpose |
|--------|------|---------|
| POST | /internal/cron/morning-push | Trigger morning push |
| POST | /internal/cron/morning-push/test | Test morning push |

---

**Full specs:** See [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) for request/response bodies, error codes, and query params.

**Connection status:** [ENDPOINT_CONNECTION_STATUS.md](./ENDPOINT_CONNECTION_STATUS.md) — which endpoints the Flutter app calls.
