# Backend: Subscription & IAP (user linkage and validation)

**Where this is used in the app:** Profile & Settings shows a **Subscription** card (status, expiry, renew-soon when ≤7 days left, or “Upgrade”). The app calls **GET /subscription/me** for that state and **GET /subscription/entitlements** for feature flags; purchase/restore use **POST /subscription/purchase** and **POST /subscription/restore**. See also [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) §8 (Subscription).

All subscription endpoints are **user-scoped**: the backend identifies the user from the **auth token** (e.g. JWT in `Authorization: Bearer <token>`). Subscription state is stored and returned **for that user only**.

---

## 1. User linkage

- **GET /subscription/me** – Returns subscription state for the **authenticated user**.
- **GET /subscription/entitlements** – Returns feature flags for the **authenticated user** (derived from tier + gender).
- **POST /subscription/purchase** – Validates the receipt, then **associates the subscription with the authenticated user** (create/update row keyed by `userId`).
- **POST /subscription/restore** – Validates the receipt, then **links any found subscription to the authenticated user**.

So the app must send a valid auth header on every request. The backend must:

1. Resolve the user from the token (e.g. decode JWT and get `userId`).
2. For **purchase** and **restore**: after validating the receipt with Apple/Google, **upsert subscription for that `userId`** (do not create anonymous subscriptions).

---

## 2. POST /subscription/purchase

**Request (application/json)**

| Field          | Type   | Required | Description |
|----------------|--------|----------|-------------|
| platform       | string | Yes      | `"ios"` or `"android"` |
| receiptOrToken | string | Yes      | **iOS:** base64 app receipt or `serverVerificationData` from the client. **Android:** purchase token (JSON or token string from `serverVerificationData`). |
| planId         | string | Yes      | Product ID: `premium_monthly`, `premium_quarterly`, or `premium_annual`. Must match App Store Connect / Google Play. |

**Flow**

1. Resolve **userId** from the auth token. Return 401 if missing/invalid.
2. **Validate the receipt** with the store:
   - **iOS:** Call Apple’s verifyReceipt (e.g. `https://buy.itunes.apple.com/verifyReceipt` for production, sandbox URL for sandbox receipts). Send the raw receipt (base64). Check that the receipt contains an active subscription for the product that matches `planId`.
   - **Android:** Use Google Play Developer API (e.g. `purchases.subscriptions.get` or `purchases.products.get`) with the purchase token and your package name. Check that the purchase is valid and matches `planId`.
3. If validation fails → **400** with code e.g. `INVALID_RECEIPT`.
4. If the user already has an active subscription (and you don’t allow stacking) → **409** with code e.g. `ALREADY_ACTIVE`.
5. Otherwise: **upsert subscription** for `userId` (e.g. set `tier = 'premium'`, `expiresAt` from the store response, `platform`, `planId`, etc.).
6. Return **200** with body = **SubscriptionState** (e.g. `{ "tier": "premium", "expiresAt": "…", "isActive": true }`).

**Response (200)**

```json
{
  "tier": "premium",
  "expiresAt": "2025-03-28T12:00:00Z",
  "isActive": true
}
```

**Errors**

| HTTP | code           | When |
|------|----------------|------|
| 401  | UNAUTHORIZED   | Missing or invalid auth token |
| 400  | INVALID_RECEIPT| Receipt validation failed (invalid, expired, or wrong product) |
| 409  | ALREADY_ACTIVE | User already has an active subscription |

---

## 3. POST /subscription/restore

**Request (application/json)**

| Field          | Type   | Required | Description |
|----------------|--------|----------|-------------|
| platform       | string | Yes      | `"ios"` or `"android"` |
| receiptOrToken | string | Yes      | Same as purchase: **iOS** receipt or **Android** purchase token (from store restore). The app sends the verification data returned by the store after `restorePurchases()`. |

**Flow**

1. Resolve **userId** from the auth token. Return 401 if missing/invalid.
2. **Validate the receipt** with Apple or Google (same as purchase). For restore, the receipt may contain past transactions; treat any valid, active (or recently expired) subscription as sufficient.
3. If validation fails or no valid subscription found → Return **200** with subscription state reflecting “no active subscription” (e.g. `isActive: false`), or **400** if you prefer to signal “nothing to restore”.
4. If a valid subscription is found: **upsert subscription** for `userId` (same as purchase).
5. Return **200** with body = **SubscriptionState**.

**Response (200)**

Same shape as purchase (e.g. `tier`, `expiresAt`, `isActive`). If nothing was restored, `isActive` is typically `false`.

---

## 4. GET /subscription/me

- **Auth:** Required.
- **Response:** Subscription state for the **authenticated user** (e.g. `tier`, `expiresAt`, `isActive`). No body or 200 with null/empty state if no subscription.

---

## 5. GET /subscription/entitlements

- **Auth:** Required.
- **Response:** Feature flags for the **authenticated user**, derived from:
  - Subscription tier (e.g. premium vs none)
  - User gender (if your business rules differ by gender)
  - Any other backend rules (e.g. limits, feature toggles)

Return a stable JSON object that the app already expects (see existing API reference for fields like `canSendMessage`, `dailyInterestLimit`, `dailyPriorityInterestLimit`, etc.).

---

## 6. App → Backend data flow (summary)

| Step | App | Backend |
|------|-----|--------|
| 1 | User logs in → receives JWT (or session). | — |
| 2 | User opens paywall; app fetches product details (and prices) from store. | — |
| 3 | User taps Subscribe → app starts IAP (e.g. `buyNonConsumable` with `premium_monthly`). | — |
| 4 | Store completes purchase → app gets `verificationData.serverVerificationData` (or local). | — |
| 5 | App sends **POST /subscription/purchase** with `Authorization: Bearer <token>`, `platform`, `receiptOrToken`, `planId`. | Resolves user from token; validates receipt with Apple/Google; upserts subscription for that user; returns new state. |
| 6 | App refreshes entitlements (e.g. GET /subscription/entitlements) and updates UI. | Returns flags for that user. |
| 7 | Restore: User taps Restore → app calls store `restorePurchases()`, gets verification data, then **POST /subscription/restore** with auth, `platform`, `receiptOrToken`. | Same validation and user linkage; returns state. |

---

## 7. Checklist for backend implementation

- [ ] All subscription endpoints require auth; reject with 401 if token missing/invalid.
- [ ] Resolve **userId** from the token and use it for all reads/writes.
- [ ] **POST /subscription/purchase:** Validate `receiptOrToken` with Apple (iOS) or Google (Android); then upsert subscription for **userId** (not for a guest or device).
- [ ] **POST /subscription/restore:** Same validation; attach any found subscription to **userId**.
- [ ] **GET /subscription/me** and **GET /subscription/entitlements:** Return data for **userId** only.
- [ ] Store at least: `userId`, `tier`, `expiresAt`, `platform`, `planId` (and optionally original receipt/token for debugging or re-validation).
- [ ] Optionally: run a job to set `isActive = false` when `expiresAt` is in the past, or derive `isActive` on read from `expiresAt`.

See also: [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) (§8) for request/response shapes and [IAP_DYNAMIC_PRICING.md](./IAP_DYNAMIC_PRICING.md) for app-side product IDs and store setup.
