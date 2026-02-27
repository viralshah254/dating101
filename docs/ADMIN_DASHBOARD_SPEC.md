# Admin Panel Web Dashboard — Specification for Saathi (Dating & Matrimony)

This document is the **single source of truth for building the Saathi admin web dashboard**. It is intended to be fed to Cursor (or another builder) to implement a full-featured admin panel for managing the dating and matrimony platform.

---

## 1. Platform context

- **Product:** Saathi — dating and matrimony app (modes: **dating**, **matrimony**).
- **App:** Flutter (mobile); backend API at `https://api.saathi.app` (dev: `http://localhost:3000`).
- **Auth:** Phone OTP only; tokens: `accessToken`, `refreshToken`, `userId`.
- **Key docs in this repo:**  
  `BACKEND_API_REFERENCE.md`, `BACKEND_SECURITY_BLOCK_REPORT.md`, `BACKEND_VERIFICATION.md`, `BACKEND_CONTACT_REQUESTS.md`, `BACKEND_CROSS_CUTTING.md`, `BACKEND_CHAT_INTEGRATION.md`, `BACKEND_MATCHES_AND_VISITORS.md`, `BACKEND_REQUESTS_SHORTLIST_FAMILY.md`.

The admin dashboard must **call backend admin APIs** (to be added or already present). Where admin endpoints do not exist yet, this spec defines what they should be so the dashboard can be built against a contract.

---

## 2. Dashboard purpose and users

- **Purpose:** Operate and moderate the whole platform: payments, users, verifications, reports/blocks, content, and safety.
- **Users:** Internal staff only (support, moderation, ops). No end-user access.
- **Auth:** Separate admin auth (e.g. email/password or SSO). Admin JWT or session must be sent to the backend; all admin routes must require an admin role.

---

## 3. Backend: admin API surface (required)

The dashboard will need the following. Implement these on the backend if they do not exist.

### 3.1 Auth and base

| Need | Recommendation |
|------|----------------|
| Admin login | `POST /admin/auth/login` (email + password or SSO). Returns admin JWT. |
| Admin session | All admin endpoints require header `Authorization: Bearer <adminToken>` and backend checks admin role. |
| Base path | Prefix all admin routes with `/admin` (e.g. `/admin/users`, `/admin/reports`). |

### 3.2 Stats and overview

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/admin/stats` or `/admin/dashboard` | Aggregates: total users, active today, new signups (e.g. last 7/30 days), total reports pending, total verifications pending, revenue (today/week/month), subscription counts by tier. |

Response shape (example):

```json
{
  "users": { "total": 12500, "activeToday": 3200, "newLast7Days": 450 },
  "reports": { "pending": 12, "resolvedToday": 5 },
  "verifications": { "pendingReview": 8 },
  "revenue": { "today": 1200, "thisWeek": 8500, "thisMonth": 32000 },
  "subscriptions": { "premium": 2100, "trial": 80 }
}
```

### 3.3 Users

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/admin/users` | List users with filters: search (name/phone/userId), mode (dating/matrimony), verified (y/n), hasActiveSubscription (y/n), createdAfter, lastActiveAfter. Pagination: `page`, `limit` (e.g. 20). |
| GET | `/admin/users/:userId` | Full admin view of one user: profile (same shape as UserProfile in BACKEND_API_REFERENCE §9.1), subscription, lastActiveAt, creationAt, creationAddress, reportCount, blockCount, verification status. |
| PATCH | `/admin/users/:userId` | Admin override: e.g. suspend profile, set hideFromDiscovery, reset verification flags, add internal note. (Define a small allowed set of fields.) |
| POST | `/admin/users/:userId/suspend` | Suspend user (reason, until?). Backend hides from discovery and may revoke tokens. |
| POST | `/admin/users/:userId/unsuspend` | Restore suspended user. |

### 3.4 Who is logged in / active

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/admin/sessions` or `/admin/activity/recent` | List recent active sessions or last-active users: userId, lastActiveAt, device/location if stored. Optional filters: lastActiveAfter, limit. |

Backend must persist `lastActiveAt` (and optionally session/location) from existing app traffic (e.g. from auth refresh or a heartbeat). No change to the mobile app required if lastActiveAt already exists on the profile.

### 3.5 Locations

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/admin/users` | Include in user list: currentCity, currentCountry, creationAddress, creationLat, creationLng (from UserProfile). |
| GET | `/admin/analytics/locations` | Optional: aggregated counts by city/country for map or top-locations view. |

Profile and security endpoints already record creation location and current city; admin just needs to read them (and optionally aggregate).

### 3.6 Payments and subscriptions

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/admin/payments` or `/admin/subscriptions/transactions` | List payment/transaction records: userId, amount, currency, planId, platform (ios/android/stripe), status, createdAt. Filters: dateRange, userId. Pagination. |
| GET | `/admin/subscriptions` | List active (and optionally expired) subscriptions: userId, tier, startedAt, expiresAt, platform. Filters: tier, status (active/expired). |
| GET | `/admin/stats` | Include revenue aggregates (today, week, month) and subscription counts. |

If the backend currently only stores subscription state per user (GET /subscription/me), add a payments/transactions table and admin endpoints so the dashboard can show “payments coming in” and revenue.

### 3.7 Verifications

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/admin/verifications/pending` | List verifications awaiting review: userId, type (id, photo, education, linkedin), status (pending/in_review), submittedAt, document keys or links (for ID/education). |
| GET | `/admin/verifications` | List all verification requests with filters: type, status, userId. |
| PATCH | `/admin/verifications/:id` | Approve or reject: body `{ "status": "approved" \| "rejected", "note": "..." }`. Backend updates VerificationStatus on the profile and optionally notifies user. |

VerificationStatus (from BACKEND_VERIFICATION.md and §9.2): photoVerified, idVerified, linkedInVerified, educationVerified, score. Admin needs to see pending submissions (e.g. ID upload, education doc) and set these flags after review.

### 3.8 Reports (user-reported content)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/admin/reports` | List reports: reportId, reportedUserId, reporterUserId, reason (spam, harassment, inappropriate_photos, fake_profile, scam, other), details, source, createdAt, status (pending/reviewed/dismissed/action_taken). Filters: status, reason, dateRange. Pagination. |
| GET | `/admin/reports/:id` | Full report detail + reporter profile summary + reported user profile summary. |
| PATCH | `/admin/reports/:id` | Set status to reviewed, dismissed, or action_taken; optional internal note. |
| POST | `/admin/reports/:id/action` | Optional: trigger action (e.g. warn user, suspend reported user, delete content). |

Backend already has POST /safety/report (reportedUserId, reason, details, source). Backend must persist reports in a table and expose them via these admin endpoints.

### 3.9 Blocks (for moderation context)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/admin/blocks` | List block events: blockerUserId, blockedUserId, reason, source, blockedAt. Optional: filter by user. Used to see patterns (e.g. user blocked by many). |

Blocks are already stored (GET /safety/blocked per user). Admin needs a global list or per-user block history for moderation.

### 3.10 Moderation actions

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/admin/users/:userId/warn` | Send in-app or push warning to user (template or free text). |
| POST | `/admin/users/:userId/suspend` | As above. |
| POST | `/admin/users/:userId/delete-content` | Optional: remove specific photos or bio content. Body: e.g. photoKeys[] or field names. |
| GET | `/admin/moderation/queue` | Optional: single queue merging reports + pending verifications for “next item to review”. |

These support a solid moderation workflow: review report → view reporter and reported user → dismiss or take action (warn, suspend, delete content).

### 3.11 Content and safety (optional extras)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/admin/content/photos` | Optional: list recently uploaded photo URLs/keys for audit or abuse scan. |
| GET | `/admin/chat/threads/:threadId` | Optional: view thread messages for abuse investigations (with legal/compliance guardrails). |

---

## 4. Dashboard UI: feature list

Build the following sections (tabs or sidebar). Use the admin API above; if an endpoint is missing, show a “Coming soon” or mock table with a note.

### 4.1 Overview (home)

- **Metrics cards:** Total users, active today, new signups (7d), pending reports, pending verifications, revenue (today / week / month), active subscriptions.
- **Charts (optional):** Signups over time, revenue over time, reports over time.
- **Quick links:** Jump to Pending reports, Pending verifications, Recent users.

### 4.2 Payments

- **Revenue summary:** Today, this week, this month (from `/admin/stats` or `/admin/payments` aggregates).
- **Transactions table:** Columns: date, user (id/name), amount, currency, plan, platform, status. Filter by date range, user. Export CSV optional.
- **Subscriptions list:** Active (and optionally expired) subscriptions; filter by tier. Link to user.

### 4.3 Users

- **User list:** Search by name/phone/userId; filter by mode (dating/matrimony), verified, subscription, signup date. Columns: avatar, name, userId, mode, city, verified, subscription, lastActive, createdAt. Click → user detail.
- **User detail:** Full profile (read-only), subscription, lastActiveAt, creation location, list of reports (where they are reporter or reported), blocks (blocker/blocked), verification status and pending verification requests. Actions: Suspend, Unsuspend, Warn, Override visibility (e.g. hide from discovery), Add internal note.

### 4.4 Active / logged-in

- **Recent activity:** Table or list of sessions/recent logins: userId, name, lastActiveAt, device/location if available. Filter by last N hours/days.
- Optionally reuse “Users” with a “Last active” column and sort by lastActiveAt.

### 4.5 Locations

- **Per user:** Shown in user list (city, country) and user detail (creationAddress, creationLat, creationLng).
- **Aggregate (optional):** Map or table of user counts by city/country from `/admin/analytics/locations`.

### 4.6 Verifications

- **Queue:** List of pending verifications (ID, photo, education, LinkedIn). Columns: user, type, submittedAt, status. Click → detail (document preview if available) → Approve / Reject with note.
- **History:** All verification requests with status and reviewer note.

### 4.7 Reports and moderation

- **Reports queue:** List of reports with status = pending. Columns: reported user, reporter, reason, details, source, date. Click → report detail (reporter + reported user profiles, full report text).
- **Actions:** Mark as reviewed, dismiss, or “action taken”; optional: trigger Warn/Suspend/Delete content on reported user. Link to user detail.
- **Block list (admin view):** Optional list of block events (who blocked whom, reason, when) for context when reviewing reports.

### 4.8 Blocked and reported users (review)

- **Reported users:** Users who have been reported (with report count and last report reason). Click → user detail and list of reports against them.
- **Blocked users (global):** Optional: list of users who appear in many “blocked” lists (blocked by N users) to spot bad actors.

### 4.9 Moderation system (workflow)

- **Single “Moderation” tab** that combines:
  - **Pending reports** (default view): next report to review; buttons: Dismiss, Warn reported user, Suspend reported user, Delete content.
  - **Pending verifications:** next verification to approve/reject.
- **Consistency:** Same user detail and action buttons (Warn, Suspend, etc.) from Reports and from Users.
- **Audit:** Log moderation actions (who did what, when) if backend supports it (e.g. `admin_audit_log` table).

### 4.10 Other useful features

- **Interests / interactions:** Optional admin list of recent “express interest” or “priority interest” events (from POST /interactions/interest, etc.) for abuse or analytics. Backend: GET /admin/interactions or include in user detail.
- **Shortlist / matches:** Optional: counts or lists for support (e.g. “user X shortlisted Y”). Can be derived from existing APIs with admin user context if backend supports impersonation (risky) or read-only admin endpoints.
- **Contact requests:** Optional: list of contact requests (sent, received, accepted) for dispute/support.
- **Chat threads:** Optional: read-only view of a thread for abuse investigation (with compliance note).
- **Account actions:** Links or buttons to “Deactivate account” / “Delete account” for the selected user (calling backend admin endpoints that mirror POST /account/deactivate and POST /account/delete with admin override).
- **Feature flags / config:** Optional: global or per-user feature flags (e.g. enable travel mode for a user) if backend has a config store.
- **Notifications:** Optional: send in-app or push to a user (e.g. “Your profile is under review”) from admin.
- **Export:** Export users or reports to CSV for compliance or analysis.

---

## 5. Tech stack recommendation for the dashboard

- **Framework:** React (Next.js) or Vue (Nuxt) or SvelteKit for a simple, fast admin SPA with routing and API calls.
- **UI:** Tailwind CSS + a component library (e.g. shadcn/ui, DaisyUI, or MUI) for tables, forms, modals, and layout.
- **State:** React Query or SWR for server state; minimal global state.
- **Auth:** Admin login page; store admin JWT (httpOnly cookie or memory + refresh). Send `Authorization: Bearer <adminToken>` on every request to the backend.
- **API base URL:** Same backend as the app (e.g. `https://api.saathi.app`); admin routes under `/admin/*`.
- **Tables:** Server-side pagination and filters; use the query params defined in §3.

---

## 6. Security and access control

- **Admin-only:** All `/admin/*` endpoints must require a valid admin token and reject non-admin users (403).
- **RBAC (optional):** Roles such as `support` (view users, view reports), `moderator` (review reports, approve verifications, warn/suspend), `admin` (full access, payments, config). Enforce in backend and optionally hide UI actions by role.
- **Audit:** Log admin actions (who, what, when) for reports, verifications, suspensions, and payment-related changes.
- **No exposure of admin dashboard to app users;** use a separate subdomain (e.g. `admin.saathi.app`) and do not link from the mobile app.

---

## 7. Reference: app and backend alignment

The Flutter app currently uses:

- **Auth:** POST /auth/send-otp, POST /auth/verify-otp, POST /auth/refresh, POST /auth/sign-out.
- **Profile:** GET/PATCH/PUT /profile/me, GET /profile/:userId, GET /profile/:userId/summary; verificationStatus on profile.
- **Safety:** POST /safety/block, POST /safety/report, GET /safety/blocked, DELETE /safety/blocked/:userId (see BACKEND_SECURITY_BLOCK_REPORT.md).
- **Verification:** VerificationStatus in profile; optional POST /verification/id/upload-url, submit, photo, education, LinkedIn (see BACKEND_VERIFICATION.md).
- **Subscription:** GET /subscription/me, POST /subscription/purchase, POST /subscription/restore, GET /subscription/entitlements (tier, canSendMessage, canSeeWhoLikedYou, etc.).
- **Interests/requests:** GET /interactions/received, GET /interactions/received/count, GET /interactions/sent; PATCH/DELETE /interactions/:id.
- **Contact requests:** GET /contact-requests/status/:profileId, POST /contact-requests, GET /contact-requests/received, accept/decline (see BACKEND_CONTACT_REQUESTS.md).
- **Shortlist:** GET/POST/DELETE /shortlist, GET /shortlist/received, GET /shortlist/received/count.
- **Matches:** GET /matches, DELETE /matches/:matchId.
- **Visits:** POST /visits, GET /visits/received.
- **Chat:** GET/POST /chat/threads, GET/POST /chat/threads/:id/messages.
- **Account:** POST /account/export, POST /account/deactivate, POST /account/delete.
- **Discovery:** GET /discovery/recommended, GET /discovery/explore, GET /discovery/filter-options, etc.

The admin dashboard does **not** replace these; it calls **new admin endpoints** that read or write the same data with elevated permissions and extra fields (e.g. reporter userId, report status, verification queue).

---

## 8. Implementation order (suggested)

1. **Backend:** Admin auth (login, JWT, guard on `/admin`). Then: GET /admin/stats, GET /admin/users (list + detail), GET /admin/reports (list + detail), PATCH /admin/reports/:id (status), GET /admin/verifications/pending, PATCH /admin/verifications/:id.
2. **Dashboard:** Login page, overview with stats, Users list and detail, Reports queue and detail with actions, Verifications queue with approve/reject.
3. **Backend:** Payments/transactions and GET /admin/payments, GET /admin/subscriptions; POST /admin/users/:userId/suspend, unsuspend, warn.
4. **Dashboard:** Payments and Subscriptions tabs; Suspend/Warn from user detail and report detail.
5. **Backend:** GET /admin/blocks or /admin/activity; optional audit log.
6. **Dashboard:** Activity/sessions view; optional Locations aggregate; audit log view if present.
7. **Polish:** RBAC, export, notifications, and optional content/chat views as needed.

---

## 9. File and repo layout (dashboard app)

Suggested layout for the admin dashboard repo (or a folder in the same monorepo):

```
admin-dashboard/
  .env.local          # NEXT_PUBLIC_API_URL=https://api.saathi.app, etc.
  package.json
  src/
    app/              # or pages/ for Next.js
      layout.tsx
      login/
      dashboard/
      users/
      users/[id]/
      reports/
      reports/[id]/
      verifications/
      payments/
      subscriptions/
      activity/
    components/
      Table.tsx
      UserCard.tsx
      ReportDetail.tsx
      ...
    lib/
      api.ts          # fetch wrapper with admin token
      auth.ts
```

Keep the dashboard in a **separate repo or `apps/admin-dashboard`** so the Flutter app stays untouched and the backend can evolve admin routes in one place.

---

## 10. Summary checklist for Cursor

- [ ] Implement or assume backend admin auth and `/admin/*` guard.
- [ ] Implement backend: GET /admin/stats, GET /admin/users (list + detail), GET /admin/reports (list + detail + PATCH status), GET /admin/verifications/pending + PATCH approve/reject.
- [ ] Build dashboard: login, overview (stats), Users (list + detail), Reports (queue + detail + actions), Verifications (queue + approve/reject).
- [ ] Add backend: payments/transactions, GET /admin/payments, GET /admin/subscriptions; suspend/unsuspend/warn user.
- [ ] Add dashboard: Payments and Subscriptions tabs; Suspend/Warn from user and report flows.
- [ ] Add activity/sessions and optional locations aggregate; optional audit log and RBAC.
- [ ] Ensure moderation workflow is solid: one place to process reports and verifications, with clear actions and links to user detail.

Use this spec together with `BACKEND_API_REFERENCE.md`, `BACKEND_SECURITY_BLOCK_REPORT.md`, and `BACKEND_VERIFICATION.md` for exact field names and existing app/backend behaviour.
