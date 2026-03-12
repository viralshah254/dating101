# March 2025 Backend: Mode (Dating / Matrimony / Both) & Independent Likes

This document describes backend changes required to support:
1. **User mode preference**: Dating only, Matrimony only, or **Both** (with discovery filtering).
2. **Likes, passes, and super-likes independent per mode**: Dating and matrimony maintain separate sent/received state and discovery feedback.

---

## 1. User mode preference (signup)

At signup/first-run the app lets the user choose:
- **Dating** – use the app in dating mode only.
- **Matrimony** – use the app in matrimony mode only.
- **Both** – use both; discovery and matches are shown per “current view” (user can switch between Dating and Matrimony in Settings).

The app persists:
- **Preference**: `dating` | `matrimony` | `both`.
- **Current view** (only when preference is `both`): `dating` | `matrimony` – which feed/tabs the user is currently seeing.

### Backend: user profile

- Store the user’s **mode preference** on the user/profile (e.g. `modePreference: 'dating' | 'matrimony' | 'both'`).
- The app may send this on signup or profile update so the backend can:
  - Filter discovery (see §3).
  - Optionally drive notifications or product logic by mode.

---

## 2. Profile-level mode (who appears where)

Profiles can be:
- **Dating only** – show only in dating discovery/matches.
- **Matrimony only** – show only in matrimony discovery/matches.
- **Both** – show in both dating and matrimony.

### Discovery filtering rules

| Viewer preference | Viewer current view | Who they see |
|-------------------|---------------------|--------------|
| Dating            | Dating              | Profiles that are **dating** or **both** |
| Matrimony         | Matrimony           | Profiles that are **matrimony** or **both** |
| Both              | Dating              | Profiles that are **both** only (when backend enforces “both sees both”) |
| Both              | Matrimony           | Profiles that are **both** only |

So:
- If the **viewer’s preference is “both”**, the app expects discovery to return only profiles that are also on **both** (so the same pool is used in both Dating and Matrimony views).
- If the viewer’s preference is **dating** or **matrimony**, discovery returns profiles that are that mode **or both**.

Backend needs:
- A way to store **per-profile mode**: e.g. `profileMode: 'dating' | 'matrimony' | 'both'` (or equivalent).
- **GET discovery/recommended** (and explore, if used) to accept:
  - **mode** (required): `dating` | `matrimony` – the current feed the user is viewing.
  - **userModePreference** (optional): `dating` | `matrimony` | `both` – so that when preference is `both`, the backend can restrict to profiles that are `both` only.

---

## 3. Discovery feedback (pass / like / super-like) – scoped by mode

The app sends **mode** with discovery feedback and with interest/priority-interest so that **dating and matrimony are independent**.

### 3.1 Discovery feedback (pass / view / block / report)

**POST /discovery/feedback**

| Field         | Type   | Required | Description |
|---------------|--------|----------|-------------|
| candidateId   | string | Yes      | Profile that was passed/viewed/blocked/reported. |
| action        | string | Yes      | `pass`, `view`, `like`, `superlike`, `block`, `report`, etc. |
| **mode**      | string | No       | **`dating` \| `matrimony`** – which feed this action belongs to. |
| timeSpentMs   | number | No       | Time spent on card. |
| source        | string | No       | E.g. `discovery`. |
| reason        | string | No       | Required for block/report. |
| details       | string | No       | Optional for report. |

- Store feedback **per (user, candidate, mode)** so a pass in dating does not affect matrimony and vice versa.
- Discovery recommendations should use this per-mode (e.g. exclude passed users in the same mode only).

---

## 4. Interactions (like / super-like) – scoped by mode

Likes and super-likes are **independent per mode**: the same user can like the same profile in **dating** and again in **matrimony** (or pass in one and like in the other).

### 4.1 Express interest (like)

**POST /interactions/interest**

| Field    | Type   | Required | Description |
|----------|--------|----------|-------------|
| toUserId | string | Yes      | Profile being liked. |
| **mode** | string | No       | **`dating` \| `matrimony`** – which mode this like is for. |
| source   | string | No       | E.g. `discovery`, `profile`, `shortlist`. |

- Store the interest **per mode** (e.g. `(fromUser, toUser, mode)`).
- Response shape unchanged (e.g. `interactionId`, `mutualMatch`, `chatThreadId`, etc.).

### 4.2 Express priority interest (super-like)

**POST /interactions/priority-interest**

| Field              | Type   | Required | Description |
|--------------------|--------|----------|-------------|
| toUserId           | string | Yes      | Profile being super-liked. |
| **mode**           | string | No       | **`dating` \| `matrimony`**. |
| message            | string | No       | Optional message. |
| source             | string | No       | E.g. `discovery`, `profile`. |
| adCompletionToken  | string | No       | When free user has watched an ad. |

- Same as above: store **per mode** so dating and matrimony are independent.

### 4.3 Get sent interactions

**GET /interactions/sent**

| Query   | Type   | Required | Description |
|---------|--------|----------|-------------|
| status  | string | No       | E.g. `pending`. |
| page    | number | No       | Pagination. |
| limit   | number | No       | Page size. |
| **mode**| string | No       | **`dating` \| `matrimony`** – return only sent interests for this mode. |

- When **mode** is present, return only interests (and optionally priority interests) sent in that mode.
- Each item must include **`toUser`** (profile summary) with **`imageUrl` and/or `photoUrls`** so the app can show the profile photo on the card.
- When **mode** is omitted, backend may return all or default to a single mode for backward compatibility.

### 4.4 Get received interactions (inbox)

**GET /interactions/received**

| Query   | Type   | Required | Description |
|---------|--------|----------|-------------|
| status  | string | No       | E.g. `pending`. |
| type    | string | No       | E.g. `all`, `interest`, `priority_interest`. |
| page    | number | No       | Pagination. |
| limit   | number | No       | Page size. |
| **mode**| string | No       | **`dating` \| `matrimony`** – return only received interests for this mode. |

- When **mode** is present, return only received interests that were sent in that mode (so the Requests tab shows mode-specific inbox when the app passes mode).
- Each interaction must include the sender as **`fromUser`** (profile summary). The profile summary **must include at least one of `imageUrl` (string) or `photoUrls` (array)** so the app can show the requester’s photo on the request card; otherwise the app shows an initial placeholder.

### 4.5 Get received interactions count

**GET /interactions/received/count**

| Query   | Type   | Required | Description |
|---------|--------|----------|-------------|
| status  | string | No       | E.g. `pending`. |
| **mode**| string | No       | **`dating` \| `matrimony`** – count only for this mode. |

- Used for nav badge; when app sends **mode**, count should be for that mode only.

---

## 5. Summary table

| Area                    | Change |
|-------------------------|--------|
| User profile            | Store `modePreference`: `dating` \| `matrimony` \| `both`. |
| Profile (candidate)     | Store profile mode: dating / matrimony / both for discovery filtering. |
| Discovery recommended   | Accept `mode`; optionally `userModePreference`; filter by profile mode and “both” rule. |
| POST /discovery/feedback| Accept **mode** (`dating` \| `matrimony`); store and use feedback per mode. |
| POST /interactions/interest | Accept **mode**; store interest per mode. |
| POST /interactions/priority-interest | Accept **mode**; store per mode. |
| GET /interactions/sent  | Accept **mode**; return sent list for that mode. |
| GET /interactions/received | Accept **mode**; return received list for that mode. |
| GET /interactions/received/count | Accept **mode**; return count for that mode. |

---

## 6. Frontend behavior (reference)

- **Signup**: User selects Dating, Matrimony, or Both; app persists preference and, if Both, current view = dating by default.
- **Settings**: If preference is Both, user can switch “current view” (Dating ↔ Matrimony); app calls backend with the current **mode** for discovery and interactions.
- **Discovery (dating)**: App sends `mode=dating` on pass and on like/super-like; sent and received lists are requested with `mode=dating`.
- **Matches / Requests (matrimony)**: App sends `mode=matrimony` for likes/super-likes and requests sent/received with `mode=matrimony`.
- **Optimistic state**: App keeps per-mode optimistic sets so that liking in dating does not remove the profile from the matrimony feed and vice versa.

Implementing the above on the backend will align with the app’s March 2025 behavior for independent dating/matrimony likes and the “Both” option.

---

## 7. Adding the other mode later (Dating only ↔ Matrimony only ↔ Both)

Users who chose **Dating only** or **Matrimony only** at signup can later opt in to **Both** from Profile & Settings.

### App flow

- In **Profile & Settings**, under "Shubhmilan mode", the tile shows the current mode (e.g. "Matrimony") and a subtitle:
  - If preference is **both**: "Switch to [other mode]" — tap to switch current view between Dating and Matrimony.
  - If preference is **single** (dating or matrimony): "Add [other mode]" — tap to add the other mode and become "Both".
- When the user taps **Add Dating** or **Add Matrimony**:
  1. A dialog explains: *"You'll now be on both Dating and Matrimony. Your profile info is shared—most details are already filled from your current mode. You can switch between them anytime in Settings."*
  2. On confirm, the app sets **mode preference** to `both` and keeps **current view** as the mode they were already on (so they stay on the same tab; no navigation change).
  3. No extra profile steps are required; existing profile data is reused for both modes.

### Backend implications

- **Sync preference when it changes**  
  If the app sends mode preference to the backend (e.g. on signup or when it changes), it will send an update when the user adds the other mode. For example:
  - **PATCH /profile/me** (or equivalent) with `modePreference: 'both'`.
- **Profile-level mode for discovery**  
  When the user becomes "both", the backend should treat their **profile** as visible in **both** dating and matrimony discovery (e.g. set or derive `profileMode` to `both` so they appear in both pools and, when someone's preference is "both", in the "both" pool).
- **No duplicate profile**  
  One profile, one set of details; the same profile is shown in dating and matrimony. No extra APIs are required beyond storing `modePreference` (and any profile-level mode used for discovery).
- **Idempotency**  
  If the app sends `modePreference: 'both'` again (e.g. after reinstall or sync), the backend can safely accept it; no need to restrict this to "only if currently single mode."
