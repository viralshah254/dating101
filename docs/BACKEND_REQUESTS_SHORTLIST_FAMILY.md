# Saathi — Requests, Shortlist, Family, Horoscope & Parent Role: Backend Contract

Backend behaviour and API contract for **requests/interests**, **contact request gating**, **shortlist** (list, notes, reorder, tags), **family details**, **horoscope**, and **parent/guardian role**. Frontend is implemented against this contract.

**Related:** [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) (§5a Interactions, §6 Shortlist, §9 Profile shapes).

---

## 1. Requests and interests

### 1.1 Status and actions

- **Received requests:** Each item has a clear **status**: `pending`, `accepted`, or `declined`.
- **Sent requests:** Status: `pending`, `accepted`, `declined`, or `withdrawn`.
- **Actions:**
  - **View profile** — Navigate to `/profile/:userId` (existing).
  - **Accept** — PATCH with `action: "accept"` (existing). On success, may return `mutualMatch`, `matchId`, `chatThreadId`.
  - **Decline** — PATCH with `action: "decline"` (existing).
  - **Withdraw** (sent only) — DELETE (existing); only when status is `pending`.

Backend already supports:

- `GET /interactions/received?status=pending|accepted|declined|all&type=all&page=1&limit=20`
- `GET /interactions/sent?status=pending&page=1&limit=20`
- `PATCH /interactions/:interactionId` with `{ "action": "accept" }` or `{ "action": "decline" }`
- `DELETE /interactions/:interactionId` (withdraw)

### 1.2 Decline with message (optional)

To soften rejection, backend may support:

- **PATCH** body: `{ "action": "decline", "message": "Optional short message" }` or
- **PATCH** body: `{ "action": "decline", "reasonId": "canned_reason_id" }`

**Suggested canned reason IDs** (backend can define): e.g. `not_right_match`, `not_ready`, `family_decided`, `other`. Frontend can show a picker when user taps "Decline" and send either free-text `message` or `reasonId`.

**Backend checklist:**

- [ ] Accept optional `message` or `reasonId` on decline (PATCH).
- [ ] Store and optionally show decline message/reason to recipient (e.g. in activity or nowhere; product decision).
- [ ] Document response shape unchanged.

---

## 2. Contact request gating

When **contactRequestGating** is on (app feature flag), the app shows:

- **"Request contact"** or **"Share number"** only when the user is **allowed** to request contact (e.g. after **mutual interest** or after a **paid step**).
- When **not** allowed, the button is **disabled** and the app shows a short **explanation** (e.g. "Request contact is available after you both express interest" or "Upgrade to request contact before mutual interest").

**Backend support:**

- **Option A — Entitlement only:** App uses existing `canRequestContact` (premium or female). When contactRequestGating is on, app additionally requires **mutual match** before enabling the button (app checks match list).
- **Option B — Backend endpoint:** Backend exposes e.g. `GET /profile/:userId/contact-eligibility` or includes in profile/summary a field like `canRequestContactDetails: boolean` (true when mutual match OR premium/entitlement).
- **Option C — Contact request API:** Backend has explicit `POST /contact-requests` (or similar). Only succeeds when gating rules pass; else returns 403 with code e.g. `CONTACT_REQUEST_NOT_ALLOWED` and a `message` for the UI.

**Backend checklist:**

- [ ] Decide model: entitlement + mutual match (app-side) vs backend eligibility vs explicit contact-request API.
- [ ] If eligibility endpoint: document response (`canRequestContactDetails`, optional `reason` when false).
- [ ] If contact-request API: document request/response and 403 payload for disabled state copy.

---

## 3. Shortlist

### 3.1 List: reorder, notes, folders/tags

**Current API:**

- `GET /shortlist?page=1&limit=20` returns `profiles[]` with `shortlistId`, `profile`, `note`, `createdAt`.
- `POST /shortlist` body: `{ "profileId": "usr_abc", "note": "Optional private note" }`.
- `DELETE /shortlist/:profileId`.

**Enhancements for backend:**

1. **Ordering**
   - Support `sort` query: e.g. `sort=recent` (default), `sort=most_interested` (e.g. by interest sent date or backend-defined score).
   - Response order must match requested sort.

2. **Notes**
   - Already in GET response and POST body; ensure each shortlist entry returns `note` (string, optional).

3. **Folders / tags (optional)**
   - Allow shortlist entries to have `folderId` or `tags[]` (e.g. "Top 5", "To discuss with parents").
   - **GET** — Optional query `folderId` or `tag` to filter. Response includes `folderId` / `tags` per entry.
   - **POST** — Optional `folderId` or `tags[]` in body.
   - **PATCH /shortlist/:shortlistId** — Optional update of `note`, `folderId`, `sortOrder` (for manual reorder).

**Backend checklist:**

- [ ] Document and implement `sort` for GET /shortlist (`recent`, `most_interested` or equivalent).
- [ ] Ensure `note` in GET response and POST body (already in API ref).
- [ ] (Optional) Add folders/tags: model, GET filter, POST/PATCH body, response shape.
- [ ] (Optional) PATCH /shortlist/:shortlistId for note/folder/order updates.

### 3.2 Add / remove from profile and cards

- **Add to shortlist:** POST /shortlist with `profileId` (and optional `note`). Frontend shows filled star after success.
- **Remove from shortlist:** DELETE /shortlist/:profileId. Frontend shows outline star.
- **Check shortlisted:** GET /shortlist/:userId/check → `{ "shortlisted": true }`. Used to show correct icon state on full profile and cards.

No backend change required for basic add/remove/check; only ensure GET /shortlist/:userId/check is implemented.

---

## 4. Family details and family expectations

**Current profile shape (MatrimonyExtensions / FamilyDetails):**

- familyType, familyValues, fatherOccupation, motherOccupation, siblingsCount, siblingsMarried.

**Frontend:** Dedicated **Family** section on matrimony profile (already present). Show these fields prominently.

**Family expectations (optional):**

- If backend supports it, add e.g. `familyExpectations` (string or structured) to **FamilyDetails** or MatrimonyExtensions.
- Frontend will show a "Family expectations" subsection when present.

**Backend checklist:**

- [ ] Expose family fields in GET /profile/:userId and profile summary where relevant (familyType, etc.).
- [ ] (Optional) Add `familyExpectations` (string) to FamilyDetails in API; frontend already shows it when present.

---

## 5. Horoscope

- **Feature flag:** App uses `horoscope` (matrimony). When true, show horoscope section.
- **Profile:** Already have `horoscope` object: dateOfBirth, timeOfBirth, birthPlace, manglik, nakshatra, horoscopeDocUrl.
- **Compatibility / Kundli match (optional):** Backend may provide:
  - On **ProfileSummary** or full profile: `compatibilityScore`, `compatibilityLabel`, or `kundliMatch: { score, label }` when viewing another profile (e.g. "Kundli match" or "Compatibility" badge).
  - Can be computed server-side when both users have horoscope data.

**Backend checklist:**

- [ ] Horoscope fields in profile/summary (already in API ref).
- [ ] (Optional) Compatibility/Kundli score or label when requesting profile in context of current user (e.g. GET /profile/:userId/summary or GET /discovery response).

---

## 6. Parent / guardian role

- **Feature flag:** App uses `parentGuardianRole` (matrimony). When true:
  - Show **"Profile managed by parent"** or **"View as parent"** where applicable.
  - **Limited actions** for parent view: e.g. view matches and shortlist only; **no chat** (or restricted).
  - When a profile was **created on behalf of** someone, show that clearly (e.g. "Created on behalf of [name]" or "Profile managed by parent").
- **Profile model:** Already have `roleManagingProfile` (self, parent, guardian, sibling, friend) in MatrimonyExtensions. Backend should return this in GET /profile/me and GET /profile/:userId when allowed.

**Backend behaviour:**

- **Viewing as parent:** Either same account with a "view as parent" mode or a separate parent account linked to the profile. If separate, backend must enforce: parent can only view matches/shortlist (and possibly requests), cannot chat on behalf of profile.
- **Created on behalf:** Profile has e.g. `createdOnBehalfOf: true` or `managedByUserId: "parent_usr_id"`. Expose in API so app can show "Profile managed by parent" / "Created on behalf of".

**Backend checklist:**

- [ ] Return `roleManagingProfile` (and optionally `managedByUserId` / `createdOnBehalfOf`) in profile API.
- [ ] If parent is separate account: enforce permissions (view matches/shortlist, no chat); document which endpoints are allowed for parent role.
- [ ] Document response shape for "managed by parent" and "created on behalf of" so frontend can show labels.

---

## 7. Frontend connection summary

| Area | Backend contract | Frontend usage |
|------|------------------|----------------|
| Requests status | GET received/sent return `status` | Show Pending / Accepted / Declined (and Withdrawn for sent) on cards |
| View profile | Navigate to profile by id | Tap on card → full profile |
| Accept / Decline / Withdraw | PATCH accept/decline, DELETE withdraw | Buttons on requests screen |
| Decline with message | PATCH decline + optional `message` or `reasonId` | Optional decline picker |
| Contact gating | Eligibility or contact-request API | Disable "Request contact" when not allowed; show reason |
| Shortlist order | GET /shortlist?sort=... | Sort options in shortlist screen |
| Shortlist notes | GET returns `note`, POST accepts `note` | Notes per profile in list; add with optional note |
| Shortlist tags/folders | Optional folderId/tags, PATCH | Tags/folders UI when backend supports |
| Shortlist add/remove | POST /shortlist, DELETE /shortlist/:id, GET check | One-tap add/remove on profile and cards; icon state from check |
| Family | familyDetails in profile | Family section on full profile |
| Family expectations | Optional field | Subsection when present |
| Horoscope | horoscope object; optional compatibility | Section when flag on; compatibility badge when API provides |
| Parent role | roleManagingProfile; managedBy/createdOnBehalfOf | "Profile managed by parent"; restrict chat in parent view |

---

## 8. Search and matches (Discover flow)

### 8.1 Recommended vs Search vs Nearby

The app distinguishes three discovery modes; backend should support all three so the difference is clear:

| Tab / mode | Description | Backend |
|------------|-------------|---------|
| **Recommended (For You)** | Algorithm-driven suggestions based on preferences and behaviour | GET /discovery/recommended |
| **Search (Explore)** | User’s filters (age, city, religion, education, etc.) | GET /discovery/explore with query params |
| **Nearby** | Distance-based (e.g. within radius) | GET /discovery/nearby with lat, lng, radiusKm |

- **Refine** in the app opens the same filter-options sheet (GET /discovery/filter-options) and applies filters to **Search (Explore)**.
- **Saved searches:** See [BACKEND_SAVED_SEARCHES.md](./BACKEND_SAVED_SEARCHES.md) for saving current filters as “Search: Software, Bangalore, 28–35” and notifications when new profiles match.

### 8.2 Backend checklist (search and matches)

- [ ] GET /discovery/recommended — algorithm recommendations.
- [ ] GET /discovery/explore — filtered by age, city, religion, education, etc.; strict preferences enforced when set.
- [ ] GET /discovery/nearby — when location available; lat, lng, radiusKm.
- [ ] GET /discovery/filter-options — options and defaults for Refine sheet.
- [ ] (Optional) Saved searches: [BACKEND_SAVED_SEARCHES.md](./BACKEND_SAVED_SEARCHES.md).

---

## 9. References

- [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) — Interactions (§5a), Shortlist (§6), Profile (§9), Discovery (§4).
- [BACKEND_MATCHES_AND_VISITORS.md](./BACKEND_MATCHES_AND_VISITORS.md) — Matches and visitors.
- [BACKEND_SAVED_SEARCHES.md](./BACKEND_SAVED_SEARCHES.md) — Saved searches and new-match notifications.
- App feature flags: `contactRequestGating`, `horoscope`, `parentGuardianRole` in `lib/core/feature_flags/feature_flags.dart`.
