# Subscription IAP: Google Play + App Store + Backend

This guide covers connecting the subscription flow to **Google Play** (Android), **Apple App Store** (iOS), and your **backend** so you know who is subscribed.

---

## 1. Current App Architecture

| Component | Status | Location |
|-----------|--------|----------|
| **in_app_purchase** package | ✅ In use | `pubspec.yaml` |
| **IAP purchase service** | ✅ Implemented | `lib/features/premium/services/iap_purchase_service.dart` |
| **Product IDs** | ✅ Defined | `premium_monthly`, `boost_one_time` |
| **Paywall UI** | ✅ Implemented | `lib/features/premium/screens/paywall_screen.dart` |
| **Subscription repository** | ✅ API + Fake | `api_subscription_repository.dart` |
| **Backend API** | 📋 Spec ready | `docs/BACKEND_SUBSCRIPTION_IAP.md` |

**Flow:** User taps Subscribe → App calls store (Google/Apple) → Store returns receipt/token → App sends to `POST /subscription/purchase` → Backend validates and stores for user.

---

## 2. Google Play Console Setup

### 2.1 Enable billing

1. **Google Play Console** → Your app → **Monetize** → **Products** → **Subscriptions**
2. Create **3 subscriptions** (same subscription group):
   - **`premium_monthly`** — Monthly, e.g. $20.99 USD / ₹800 INR
   - **`premium_quarterly`** — Every 3 months, e.g. $44.97 USD / ₹1,800 INR
   - **`premium_annual`** — Yearly, e.g. $120 USD / ₹3,500 INR
3. **In-app products** (for boost):
   - **Product ID:** `boost_one_time`
   - **Type:** One-time
   - **Price:** e.g. $4.99 / ₹299
   - **Status:** Activate

### 2.2 License testing

- **Setup** → **License testing** → Add test Gmail accounts
- Use these accounts on a device to test purchases without being charged

### 2.3 Service account (for backend validation)

1. **Google Cloud Console** → **APIs & Services** → **Credentials**
2. Create **Service Account** with JSON key
3. In **Google Play Console** → **Users and permissions** → Invite the service account with **View financial data** and **Manage orders**
4. Backend will use this key to call [Google Play Developer API](https://developers.google.com/android-publisher) for receipt validation

### 2.4 Android app config

- **Package name:** `com.dvtechventures.saathi` (from `android/app/build.gradle.kts`)
- **Min SDK:** Ensure ≥ 21 (in_app_purchase requirement)
- No extra Gradle config needed; `in_app_purchase` adds billing automatically

---

## 3. App Store Connect Setup (iOS)

### 3.1 Create in-app purchases

1. **App Store Connect** → Your app → **Features** → **In-App Purchases**
2. Create **subscription group** (e.g. "Premium")
3. Add **3 auto-renewable subscriptions:**
   - **`premium_monthly`** — 1 month, e.g. $20.99 USD / ₹800 INR
   - **`premium_quarterly`** — 3 months, e.g. $44.97 USD / ₹1,800 INR
   - **`premium_annual`** — 1 year, e.g. $120 USD / ₹3,500 INR
4. **Non-consumable** (for boost):
   - **Product ID:** `boost_one_time`
   - **Price:** e.g. $4.99 / ₹299

### 3.2 Sandbox testing

- **Users and Access** → **Sandbox** → Create sandbox testers
- On device: **Settings** → **App Store** → Sign in with sandbox account
- Purchases in the app will use sandbox (no real charge)

### 3.3 Shared secret (for backend validation)

1. **App** → **App Information** → **App-Specific Shared Secret** (or In-App Purchase → Manage)
2. Generate shared secret for your app
3. Backend uses this when calling [Apple verifyReceipt](https://developer.apple.com/documentation/appstorereceipts/verifyreceipt)

### 3.4 iOS app config

- **Bundle ID:** Must match App Store Connect
- **Capabilities:** Enable **In-App Purchase** in Xcode
- StoreKit config (optional): Create `.storekit` file for local testing without App Store Connect

---

## 4. Backend Implementation

### 4.1 Endpoints (see BACKEND_SUBSCRIPTION_IAP.md)

| Endpoint | Purpose |
|----------|---------|
| `GET /subscription/me` | Return subscription state for authenticated user |
| `GET /subscription/entitlements` | Return feature flags (premium vs free) |
| `POST /subscription/purchase` | Validate receipt, link subscription to user |
| `POST /subscription/restore` | Validate receipt, restore subscription to user |

### 4.2 Receipt validation

**iOS (Apple):**

```
POST https://buy.itunes.apple.com/verifyReceipt   (production)
POST https://sandbox.itunes.apple.com/verifyReceipt (sandbox)
Body: { "receipt-data": "<base64 receipt>", "password": "<shared_secret>" }
```

- Use sandbox URL for sandbox receipts (status 21007 = try sandbox)
- Parse response for `latest_receipt_info` or `in_app` to get expiry, product_id

**Android (Google Play):**

- Use [Google Play Developer API](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptions)
- `GET https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}`
- Requires OAuth with service account
- Response includes `expiryTimeMillis`, `autoRenewing`, etc.

### 4.3 Database schema (example)

```sql
CREATE TABLE subscriptions (
  user_id        VARCHAR(64) PRIMARY KEY,
  tier           VARCHAR(32) NOT NULL DEFAULT 'none',
  platform       VARCHAR(16),  -- 'ios' | 'android'
  plan_id        VARCHAR(64),
  expires_at     TIMESTAMP,
  purchase_token TEXT,         -- Store receipt/token (for re-validation)
  created_at     TIMESTAMP DEFAULT NOW(),
  updated_at     TIMESTAMP DEFAULT NOW()
);
```

- `isActive` = `expires_at > NOW()` and `tier = 'premium'`
- Optionally run a cron to set `tier = 'none'` when expired

### 4.4 Knowing who is subscribed

- **GET /subscription/me** returns `{ tier, expiresAt, isActive }` for the authenticated user
- **GET /subscription/entitlements** returns feature flags derived from subscription
- For **profile badges** (isPremium on other users): Backend includes `isPremium: true` in profile/summary responses when that user has an active subscription (see BACKEND_PREMIUM_ADS_BOOST.md)

---

## 5. App-Side Checklist

| Task | Status |
|------|--------|
| Product IDs match store consoles | ✅ `premium_monthly`, `boost_one_time` |
| Purchase flow calls store, then backend | ✅ `runIapPurchase` → `purchaseSubscription` |
| Restore flow | ✅ `runIapRestore` → `restorePurchases` |
| Don't send placeholder receipt when store unavailable | ⚠️ Fix: show error, don't call backend |
| Handle 401, 400, 409 from backend | ✅ Via ApiException in repository |

---

## 6. Testing

### Android

1. Build release or use internal testing track
2. Add license tester in Play Console
3. Install app, sign in with test account
4. Open paywall → Subscribe → Complete purchase (no real charge)
5. Check backend: `GET /subscription/me` should return `isActive: true`

### iOS

1. Create sandbox tester
2. On device: Settings → App Store → sign in with sandbox
3. Run app, open paywall, subscribe
4. Sandbox purchase completes; backend validates with sandbox URL

### Backend

- Use [Apple sandbox verifyReceipt](https://developer.apple.com/documentation/appstorereceipts/verifying_receipts_with_the_app_store) for iOS sandbox receipts
- For Android: use a test purchase token from a license tester

---

## 7. Related docs

- [BACKEND_SUBSCRIPTION_IAP.md](./BACKEND_SUBSCRIPTION_IAP.md) — API spec, validation flow
- [IAP_DYNAMIC_PRICING.md](./IAP_DYNAMIC_PRICING.md) — Product IDs, store pricing
- [BACKEND_PREMIUM_ADS_BOOST.md](./BACKEND_PREMIUM_ADS_BOOST.md) — Entitlements, isPremium badge
