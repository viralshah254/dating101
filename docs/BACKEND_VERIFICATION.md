# Backend: Profile verification (ID, face, LinkedIn, education)

This document specifies how the **Verification** screen works with the backend: reading verification state, safety score, and (when implemented) submitting ID, face, LinkedIn, and education verification.

---

## 1. Current behaviour: verification status on profile

The app reads verification state from **GET /profile/me** (and **GET /profile/:userId** for others). The response includes a **verificationStatus** object.

### 1.1 VerificationStatus (in profile response)

Returned as part of **UserProfile**. See [BACKEND_API_REFERENCE.md §9.2](BACKEND_API_REFERENCE.md#92-verificationstatus).

| Field | Type | Description |
|-------|------|-------------|
| photoVerified | boolean | Face/selfie matched to ID or profile photo |
| idVerified | boolean | Government ID uploaded and validated |
| emailVerified | boolean | Email verified (if used) |
| phoneVerified | boolean | Phone verified (OTP at sign-up) |
| linkedInVerified | boolean | LinkedIn account connected and verified |
| educationVerified | boolean | Education (university/college) verified |
| score | number | 0.0–1.0 aggregate safety/trust score |

**Backend:** Store `verificationStatus` as JSON on the **Profile** model (e.g. `verificationStatus` column). When returning the profile, include this object; if missing, return `{}` or defaults (all false, score 0). The app uses it to:

- Show a **check** on each verification tile when the corresponding flag is true.
- Show a **safety score** progress bar using `score` (0.0–1.0).
- Show “Complete verifications to increase your safety score and visibility.”

**Score computation (backend):** Derive `score` from completed verifications (e.g. photo + ID = 0.6, + LinkedIn = 0.8, + education = 1.0), or store it when you update verification flags. A common rule: `isVerified` (badge) = `score >= 0.5` or `photoVerified === true`.

---

## 2. Verification tiles (app mapping)

| Tile | Profile field | App behaviour |
|------|----------------|---------------|
| ID verification | idVerified | Tap → ID upload sheet; when backend supports upload, call API then refresh profile |
| Face match | photoVerified | Tap → Photo verification flow (selfie/challenge); on success backend sets photoVerified |
| LinkedIn | linkedInVerified | Tap → LinkedIn OAuth or “Connect”; backend sets linkedInVerified when verified |
| Education | educationVerified | Tap → Upload degree or connect institution; backend sets educationVerified |

The app shows **verified** (check icon) when the corresponding flag is true; otherwise **pending** (chevron). No “in review” or “failed” in the API yet; backend can add optional `idVerificationStatus: "pending" | "in_review" | "verified" | "failed"` later if needed.

---

## 3. Endpoints to implement (optional, for full flow)

### 3.1 ID verification

**Option A – Presigned upload (recommended)**  
Same pattern as profile photos:

1. **POST /verification/id/upload-url** (or **POST /profile/me/verification/id/upload-url**)  
   - Body: `{}` or `{ "type": "passport" | "driving_licence" }`  
   - Response: `{ "uploadUrl": "...", "key": "..." }` (presigned PUT URL).  
   - Client uploads the ID image with `PUT` to `uploadUrl`, then calls the submit endpoint with `key`.

2. **POST /verification/id/submit**  
   - Body: `{ "key": "..." }` (the storage key after upload).  
   - Backend: store key, run async job (or third-party) to validate ID and match to profile photo; when done, set `verificationStatus.idVerified = true` (and optionally update `score`).  
   - Response: `{ "status": "pending" | "in_review", "message": "We'll notify you when verification is complete." }`.

**Option B – Direct upload**  
- **POST /verification/id** with `multipart/form-data` (file). Backend stores and processes; response same as above.

### 3.2 Face / photo verification

- After the in-app flow (capture selfie, challenge), the app sends the selfie (or a reference) to the backend.  
- **POST /verification/photo** (or **POST /profile/me/verification/photo**)  
  - Body: presigned key or multipart image.  
  - Backend: compare to profile photo (and optionally ID photo); set `verificationStatus.photoVerified = true` and update `score`.  
  - Response: `{ "verified": true }` or `{ "verified": false, "reason": "..." }`.

If the app currently does the flow only on-device, the backend can expose an endpoint that accepts the result (e.g. token from a third-party face match service) and then sets `photoVerified`.

### 3.3 LinkedIn

- **GET /verification/linkedin/auth-url**  
  - Response: `{ "url": "https://..." }` (OAuth URL). App opens in browser or WebView.  
- **GET /verification/linkedin/callback?code=...** (or **POST /verification/linkedin/callback** with `code`)  
  - Backend: exchange code for token, fetch profile, store that user has connected LinkedIn; set `verificationStatus.linkedInVerified = true`.  
  - Redirect to app deep link or return success JSON.

### 3.4 Education

- **POST /verification/education**  
  - Body: e.g. `{ "institutionName": "...", "degree": "...", "documentKey": "..." }` (document uploaded via same presigned pattern as ID) or link to a verification provider.  
  - Backend: validate (manual or provider); set `verificationStatus.educationVerified = true`.

---

## 4. Summary

| Item | Status |
|------|--------|
| verificationStatus in GET /profile/me | Required; app reads it today |
| score 0.0–1.0 and flags (photoVerified, idVerified, etc.) | Required in profile response |
| POST /verification/id/upload-url + submit | Optional; for ID upload flow |
| POST /verification/photo | Optional; for face match result |
| LinkedIn OAuth URL + callback | Optional; for LinkedIn tile |
| POST /verification/education | Optional; for education tile |

Until these endpoints exist, the app shows the correct **verified** state from profile and a working **safety score**; ID / Face / LinkedIn / Education taps can open in-app flows or “Coming soon” with no backend call.

---

## 5. Related docs

- [BACKEND_API_REFERENCE.md](BACKEND_API_REFERENCE.md) — §9.1 UserProfile, §9.2 VerificationStatus.
- [BACKEND_CROSS_CUTTING.md](BACKEND_CROSS_CUTTING.md) — Safety and privacy.
