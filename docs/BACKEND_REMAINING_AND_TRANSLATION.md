# Backend: What’s remaining & how to translate user-generated content

Quick reference for backend improvements and for making the “Translate” / language behaviour work.

---

## 1. What’s remaining for the backend

From [ENDPOINT_CONNECTION_STATUS.md](./ENDPOINT_CONNECTION_STATUS.md):

| Item | Status | Notes |
|------|--------|--------|
| **POST /auth/google** | ○ Optional | Social login; app uses phone OTP only. Return **501** if not implemented. |
| **POST /auth/apple** | ○ Optional | Same as above. |
| **POST /translate** | ○ Not implemented | No translate route/service. App calls it and degrades (returns null on 404/501). See §2 below. |

Everything else the app needs is **already connected** (107 endpoints). Backend should keep those live and match the contracts in the main API reference.

**Other improvements (optional but high impact):**

- **Profile/discovery translation by locale** — Read `Accept-Language` (or `locale` query) on profile and discovery endpoints; return `bio` / `aboutMe` (and optionally other free text) **already translated** into the viewer’s language. See [BACKEND_PROFILE_TRANSLATION.md](./BACKEND_PROFILE_TRANSLATION.md). No new endpoint; same response shape, different content per locale.
- **In-app notifications feed** — If not built yet: GET /notifications, GET /notifications/unread-count, PATCH /notifications/:id/read, POST /notifications/mark-all-read. Main API reference §6d.3.
- **Boost IAP** — If not built yet: GET /boost/me, POST /boost/purchase. [BACKEND_SUBSCRIPTION_IAP.md](./BACKEND_SUBSCRIPTION_IAP.md), §8.4a in API reference.

Full “docs to give backend” checklist: [CONNECT_AND_BACKEND_HANDOFF.md](./CONNECT_AND_BACKEND_HANDOFF.md) §4.

---

## 2. How to get user-generated content translated (language section)

The app shows a **“Translate”** link under bios and other user-generated text (e.g. on profile cards). When the user taps it, the app calls **POST /translate** with `text` and `targetLocale`. Right now the backend does **not** implement this, so the request fails (404/501) and the app shows “Translation unavailable” or keeps the original text.

You can support translation in three ways (or combine them).

### Option A: Backend implements POST /translate (on-demand “Translate” button)

- Add a **POST /translate** route.
- Request body: `{ "text": "...", "targetLocale": "hi" }` (or `en`, `ta`, `te`, etc.).
- Response: `{ "translatedText": "..." }`.
- Backend uses Google Cloud Translation (or similar), optionally caches by `(textHash, targetLocale)`, and rate-limits per user.
- The app already calls this; once the endpoint exists and returns 200, the “Translate” button will work with no app change.

**Doc:** [BACKEND_PROFILE_TRANSLATION.md](./BACKEND_PROFILE_TRANSLATION.md) §6.

---

### Option B: Backend returns translated content in profile APIs (no button needed for default language)

- On **GET /profile/:userId**, **GET /profile/:userId/summary**, **GET /discovery/recommended**, **GET /discovery/explore**, etc., read the **Accept-Language** header (e.g. `hi`, `en`, `ta`).
- For free-text fields (**bio**, **aboutMe**, and optionally city, occupation, etc.), **translate to that locale** (on-the-fly + cache, or pre-stored per locale) and return the translated string in the same `bio` / `aboutMe` fields.
- The profile card then **already shows** the bio in the viewer’s language. The “Translate” button can still be used to switch to another language if you implement **POST /translate** (Option A), or you can hide it when content is already in the user’s app language.

**Doc:** [BACKEND_PROFILE_TRANSLATION.md](./BACKEND_PROFILE_TRANSLATION.md) §2–5, §8 checklist.

---

### Option C: Client-side translation (no backend change)

- The app can call a **translation API or SDK directly** (e.g. Google Cloud Translation from the app with an API key, or an on-device SDK). Then the “Translate” button does **not** depend on the backend.
- Implementation: add a **client-only** translate implementation (e.g. a new `TranslateRepository` implementation that calls Google Translate REST API or a small cloud function), and use it when the backend returns 404/501 for POST /translate. No backend work required; you handle API keys and quotas on the client or via a separate service.

---

## 3. Recommended path

1. **Short term:**  
   - Implement **POST /translate** (Option A) so the existing “Translate” button works. Contract is in [BACKEND_PROFILE_TRANSLATION.md](./BACKEND_PROFILE_TRANSLATION.md) §6.
2. **Medium term:**  
   - Add **Accept-Language** support and return **translated bio/aboutMe** in profile and discovery responses (Option B). Then most users see content in their language without tapping “Translate”.
3. **Optional:**  
   - If you prefer not to add translation on the backend yet, use **Option C** (client-side translation) so the button still works.

---

## 4. Summary

| Goal | Action |
|------|--------|
| **Backend “what’s remaining?”** | 3 endpoints optional/not implemented: /auth/google, /auth/apple, **POST /translate**. Biggest functional gap: **POST /translate** for the “Translate” link. |
| **Translate UGC (bios, etc.)** | **A)** Backend: POST /translate. **B)** Backend: Accept-Language + translated bio in profile APIs. **C)** App: client-side translation (no backend). |
