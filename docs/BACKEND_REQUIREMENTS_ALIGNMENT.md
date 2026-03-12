# Backend Requirements Alignment

Date: 2026-03-09
Owner: Mobile + Backend
Purpose: Freeze backend contract requirements needed to complete app integration without drift.

## Goals

- Eliminate endpoint/schema ambiguity that causes client workarounds.
- Mark which APIs are required for current release vs deferred.
- Define acceptance criteria so QA can validate end-to-end behavior.

## Release Scope

### Must Be Stable For Release

- Discovery feed + pagination endpoints
- Interactions (interest, priority, respond)
- Chat threads/messages/message-requests
- Profile read/update core endpoints
- Verification ID upload + submit endpoints
- Photo view request endpoints
- Location/city options endpoints

### Can Be Deferred (If Explicitly Marked)

- Notifications center endpoints (if screen is not shipped)
- Boost endpoints (if boost UX is not shipped)
- Legacy interests endpoints (if interactions remains canonical)

## Endpoint Contract Requirements

| Domain | Endpoint | Required contract | Current issue | Required backend action |
|---|---|---|---|---|
| Daily matches action | `POST /interactions/interest` (canonical) | Accept interest send from daily matches flow, return match status payload | Docs still reference `/interests` in places | Update docs and keep alias only if needed for backward compatibility |
| Daily matches fetch | `GET /matrimony/daily-matches` | Return list payload aligned with profile card parser | Client currently has fallback to recommended on 404 | Guarantee endpoint in all envs and monitor 404 rate to zero |
| Photo request status | `GET /photo-view-requests/status/:profileId` (or one canonical alternate) | Response must include a single canonical state key | Mixed usage of `state` vs `status` | Freeze one response shape and support legacy key temporarily |
| Photo request create | `POST /photo-view-requests` | Body key for target user must be canonical | `targetUserId` vs `toUserId` mismatch in docs | Standardize key; accept both during migration window |
| Discovery feed shape | `GET /discovery/recommended` and explore variants | Always include `profiles` array and pagination metadata | Client has tolerant parsing that can hide schema regressions | Add contract tests in backend CI for response schema |
| Verification non-ID | LinkedIn/Education verification endpoints | Return submission + status values consumed by verification UI | UI currently marks these as coming soon | Finalize endpoint readiness date or keep disabled in app |
| Notifications | `/notifications*` | Unread count + list + mark read contract | API exists but mobile surface not fully integrated | Confirm go-live plan or mark as phase-2 |
| Entitlements/boost | `/subscription/entitlements`, `/boost/*` | Single source of truth for premium features | Client currently computes entitlement locally in multiple flows | Decide source of truth and publish authoritative contract |

## Canonical Params and Payloads

These are the required canonical request/response fields to avoid drift.

### 1) Daily Matches Action

- Endpoint: `POST /interactions/interest`
- Request body:
  - `targetUserId` (string, required)
  - `mode` (string enum: `dating` or `matrimony`, required)
  - `source` (string, optional; recommended: `daily_matches`)
- Response body:
  - `ok` (bool)
  - `mutualMatch` (bool)
  - `chatThreadId` (string|null)
  - `interactionId` (string)

### 2) Daily Matches Fetch

- Endpoint: `GET /matrimony/daily-matches`
- Query params:
  - `limit` (int, optional, default `9`)
- Response body:
  - `profiles` (array, required)
  - `nextCursor` (string|null, optional)

### 3) Photo View Request Status

- Endpoint: `GET /photo-view-requests/status/:profileId`
- Path params:
  - `profileId` (string, required)
- Response body:
  - `status` (string enum: `none|pending|accepted|declined`, required canonical key)
  - `requestedAt` (ISO timestamp, optional)

### 4) Photo View Request Create

- Endpoint: `POST /photo-view-requests`
- Request body:
  - `targetUserId` (string, required canonical key)
- Response body:
  - `requestId` (string)
  - `status` (string enum: `pending`)
  - `requestedAt` (ISO timestamp)

### 5) Discovery Feed / Nearby

- Endpoints:
  - `GET /discovery/recommended`
  - `GET /discovery/explore`
  - `GET /discovery/nearby`
- Query params:
  - `mode` (`dating|matrimony`) where applicable
  - `limit` (int)
  - `cursor` (string, optional)
  - nearby-only: `lat`, `lng`, `radiusKm`
- Response body:
  - `profiles` (array, required)
  - `nextCursor` (string|null, optional)
  - each profile should include: `id`, `name`, `age`, `city`, `imageUrl|imageUrls`, `distanceKm` (nearby), verification/premium flags as available
  - nearby profile should include at least one map geometry option:
    - canonical: `pinLat`, `pinLng` (privacy-fuzzed)
    - temporary fallback (migration): `approxLat`, `approxLng`

## Required Response Standards

- Use consistent envelope for errors:
  - `code` (machine key)
  - `message` (user-safe summary)
  - `details` (optional structured diagnostics)
- Keep field names stable across endpoints for equivalent concepts (`status`/`state`, `userId` naming).
- Document nullable fields explicitly.
- Return deterministic enum sets and publish them in docs.

## Backend QA Acceptance Criteria

- All release-scope endpoints pass schema contract tests.
- No 404 fallback path required for core release endpoints in staging.
- Error payloads include `code` and `message` for all 4xx/5xx responses.
- Endpoint latency targets:
  - p95 under 600ms for list APIs,
  - p95 under 400ms for action APIs.
- Staging test data includes:
  - users with no results,
  - premium-locked states,
  - mutual match path,
  - verification pending/approved/rejected states.

## Handoff Checklist

- [ ] Backend confirms canonical routes and payload keys.
- [ ] Mobile removes temporary client-side compatibility shims where safe.
- [ ] QA validates endpoint matrix against staging.
- [ ] Docs (`BACKEND_API_REFERENCE` + feature docs) updated to canonical contracts.
- [ ] Any deferred endpoints are marked "not in release scope."

