# In-App Purchase – Dynamic Pricing

Prices shown on the paywall come from **Google Play** and **App Store**, not from the app. You set prices (and localisation) in the store consoles; the app fetches and displays them at runtime.

**Backend:** Purchase and restore are tied to the **logged-in user**. The app sends the store receipt/token to your backend; the backend validates it with Apple/Google and stores the subscription for that user. See **[BACKEND_SUBSCRIPTION_IAP.md](./BACKEND_SUBSCRIPTION_IAP.md)** for user linkage, validation, and implementation checklist.

---

## 1. Product IDs (must match exactly)

### Subscriptions (3 tiers)

| Product ID          | Type        | USD (example) | INR (example) |
|---------------------|-------------|---------------|---------------|
| `premium_monthly`   | Subscription | $20.99/month  | ₹800/month    |
| `premium_quarterly` | Subscription | $44.97/3 mo   | ₹1,800/3 mo   |
| `premium_annual`    | Subscription | $120/year     | ₹3,500/year   |

**Pricing logic:** Each tier goes down in effective monthly cost. Annual is best value (~$10/mo USD, ~₹292/mo INR).

### One-time

| Product ID       | Type     | USD (example) | INR (example) |
|------------------|----------|---------------|---------------|
| `boost_one_time` | One-time | $4.99         | ₹299          |

---

## 2. Recommended prices by region

### United States (USD)

| Plan     | Price   | Effective/month |
|----------|---------|-----------------|
| Monthly  | $20.99  | $20.99          |
| Quarterly| $44.97  | ~$15.00         |
| Annual   | $120.00 | $10.00          |

### India (INR)

| Plan     | Price   | Effective/month |
|----------|---------|-----------------|
| Monthly  | ₹800    | ₹800            |
| Quarterly| ₹1,800  | ~₹600           |
| Annual   | ₹3,500  | ~₹292           |

---

## 3. Where to set prices

### Google Play Console

1. **Monetize** → **Products** → **Subscriptions**
2. Create 3 subscriptions:
   - `premium_monthly` — Base plan: monthly, set price per country
   - `premium_quarterly` — Base plan: every 3 months
   - `premium_annual` — Base plan: yearly
3. **In-app products** → `boost_one_time` (one-time)
4. Activate all products

### App Store Connect (iOS)

1. **Features** → **In-App Purchases**
2. Create **subscription group** (e.g. "Premium")
3. Add 3 auto-renewable subscriptions:
   - `premium_monthly` — 1 month
   - `premium_quarterly` — 3 months
   - `premium_annual` — 1 year
4. Create **non-consumable** `boost_one_time`
5. Set prices per territory (USD, INR, etc.)

---

## 4. Behaviour in the app

- On paywall open, the app fetches product details (including `price`) from the store.
- The store returns the **localised price** for the user's region (e.g. $20.99, ₹800).
- If the store is unavailable (e.g. simulator, products not in console yet), the app shows fallback: **$20.99**, **$44.97**, **$120** for the three tiers.
- User selects a plan (Monthly, Quarterly, or Annual) and taps Subscribe.
- Backend receives `planId` as one of: `premium_monthly`, `premium_quarterly`, `premium_annual`.
