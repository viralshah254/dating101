# In-App Purchase – Dynamic Pricing

Prices shown on the paywall come from **Google Play** and **App Store**, not from the app. You set prices (and localisation) in the store consoles; the app fetches and displays them at runtime.

**Backend:** Purchase and restore are tied to the **logged-in user**. The app sends the store receipt/token to your backend; the backend validates it with Apple/Google and stores the subscription for that user. See **[BACKEND_SUBSCRIPTION_IAP.md](./BACKEND_SUBSCRIPTION_IAP.md)** for user linkage, validation, and implementation checklist.

## Product IDs (must match exactly)

| Product ID         | Type        | App display      |
|--------------------|------------|------------------|
| `premium_monthly`  | Subscription | Premium (£9.99/month) |
| `boost_one_time`   | One-time     | Boost pack (£4.99)    |

## Where to set prices

### Google Play Console

1. Open your app → **Monetize** → **Products** → **Subscriptions** (or **In-app products**).
2. Create a **subscription** with ID `premium_monthly` and set price per country (or use default).
3. Create an **in-app product** with ID `boost_one_time` and set price.
4. Activate the products so they are available to the app.

### App Store Connect (iOS)

1. Open your app → **Features** → **In-App Purchases**.
2. Create an **auto-renewable subscription** with product ID `premium_monthly`, set price and territory.
3. Create a **non-consumable** (or consumable) with product ID `boost_one_time`, set price.
4. Submit for review so they appear in production; for **Sandbox** they can stay in “Ready to submit”.

## Behaviour in the app

- On paywall open, the app calls the store API to fetch product details (including `price` and optional `title`).
- The store returns the **localised price** for the user’s region (e.g. £9.99, $9.99, ₹799).
- If the store is unavailable (e.g. simulator, no products in console yet), the app shows fallback text: **£9.99/month** and **£4.99 one-time**.

So: **you configure pricing in the consoles**; the app only displays whatever the store returns.
