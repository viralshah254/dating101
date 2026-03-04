# Backend: Referral program

Spec for the referral flow: **30 days free Premium** for users who sign up with a referral code, **per-user referral codes**, and a **top-referrer contest** (win up to ₹1,00,000).

---

## 1. Program summary

| Item | Description |
|------|-------------|
| **Referred user (new sign-up)** | When they enter a valid referral code at sign-up, grant **30 days free Premium** (subscription). |
| **Referrer** | Every user has their own **referral code** and **invite link** (from GET /referral). App shows: "30 days free Premium for everyone who signs up with your code" and "Top referrer wins up to ₹1,00,000!". |
| **Contest** | Track successful referrals per referrer. The user who has referred the most (within the contest rules) wins up to **₹1,00,000**. Backend must be able to identify top referrer(s) and support pay-out/verification. |

---

## 2. App flow

1. **Sign-up with code**  
   User enters phone → receives OTP → on **Login** they can optionally enter a **Referral code**. That value is sent in **POST /auth/verify-otp** as `referralCode` when they verify.

2. **Referrer experience**  
   User opens **Invite friends** (GET /referral). They see their `code` and `inviteLink`, copy/share them. When they share, the app may call **POST /referral/invite** (body: `channel`). They see: "30 days free Premium for everyone who signs up with your code" and "Top referrer wins up to ₹1,00,000!".

---

## 3. Endpoints

### 3.1 POST /auth/verify-otp — apply referral at sign-up

**Request body** (relevant fields):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| verificationId | string | Yes | From send-otp. |
| code | string | Yes | OTP. |
| **referralCode** | **string** | **No** | **Optional.** Referral code entered by the user at sign-up. |

**Behaviour when `referralCode` is present and user is new (e.g. first time verify):**

1. **Validate** the code (e.g. exists, belongs to another user, not self-referral).
2. If **valid**:
   - **Grant 30 days Premium** to the new user (create/update subscription so they have Premium for 30 days).
   - **Record** the referral (referrer userId, referred userId, referredAt) for analytics and contest.
   - Optionally increment referrer’s “successful referrals” count.
3. If **invalid** (unknown code, already used by this user, same user, expired, etc.): **do not** fail the sign-in; complete auth as usual and **ignore** the referral. Do not return 400 for bad referral code so the user can still sign up.

**Behaviour when `referralCode` is missing or user is returning:**  
No referral logic; normal verify-otp only.

**Response (extend existing verify-otp success body):**

Include **`referralApplied`** so the app can show “30 days free Premium!” only when the code was actually applied:

| Field | Type | Description |
|-------|------|-------------|
| accessToken | string | As today. |
| refreshToken | string | As today. |
| userId | string | As today. |
| isNewUser | boolean | As today. |
| **referralApplied** | **boolean** | **Optional.** Set to `true` when the referral code was valid and 30 days Premium was granted. Omit or `false` otherwise. App uses this to show a one-time “30 days free Premium!” dialog after OTP. |

---

### 3.2 GET /referral — user’s own code and link

**Response** (existing contract):

| Field | Type | Description |
|-------|------|-------------|
| code | string | User’s referral code (e.g. `DESI-XXXX`). Create on first access if missing. |
| inviteLink | string | Full invite URL (e.g. `https://shubhmilan.app/i/DESI-XXXX`). |
| pendingCount | number | Optional. Number of sign-ups with this code not yet “converted” or similar. |
| earnedRewards | array | Optional. List of rewards earned (e.g. premium extensions, contest rank). |

**Contest / leaderboard:**  
If you expose “referral count” or “rank” for the current user, you can add fields such as `successfulReferralCount` or `contestRank` to this response so the app can show “You’ve referred N people” or “You’re #K on the leaderboard”.

---

### 3.3 POST /referral/invite — record that user shared

**Request body:** `{ "channel": "share" | "copy_link" | ... }` (optional).

**Purpose:** Log that the user shared their link/code (for analytics). No change to Premium or referral count; the actual referral is credited when the new user signs up with the code in **verify-otp**.

---

## 4. Data model (suggested)

- **ReferralCode** (or equivalent): `userId` (referrer), `code` (unique), `inviteLink`, `createdAt`.
- **Referral** (or equivalent): `referrerUserId`, `referredUserId`, `referralCode`, `referredAt`, `premiumGranted` (e.g. 30 days). One row per successful sign-up with a valid code.
- **Contest / leaderboard:** Aggregate by `referrerUserId` (count of successful referrals in contest window). Use for “top referrer” and pay-out (e.g. up to ₹1,00,000).

---

## 5. Business rules (summary)

| Rule | Action |
|------|--------|
| New user signs up **with** valid `referralCode` | Grant 30 days Premium; record referral; attribute to referrer. |
| New user signs up **without** code or with invalid code | Normal sign-up; no Premium grant; no referral record. |
| Invalid referral code | Ignore; do not fail verify-otp. |
| Same user as referrer (self-referral) | Reject / ignore; do not grant. |
| Code already used by this user (re-use) | Ignore; do not grant again (idempotent). |
| Top referrer contest | Count successful referrals per referrer in contest period; winner wins up to ₹1,00,000 (pay-out/verification as per your process). |

---

## 6. Related docs

- **Auth:** [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) §1.2 (Verify OTP) — request body including `referralCode`.
- **Subscription:** [BACKEND_SUBSCRIPTION_IAP.md](./BACKEND_SUBSCRIPTION_IAP.md) — how Premium / subscription state is stored and returned (GET /subscription/me, entitlements).
