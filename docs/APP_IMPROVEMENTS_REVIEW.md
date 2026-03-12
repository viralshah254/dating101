# App Improvements Review

Date: 2026-03-09
Scope: Full Flutter app review (`lib/`) + backend integration wiring (`lib/data/repositories_api/`) + key backend docs.

## Executive Overview

This app has strong feature breadth (discovery, matches, chat, requests, shortlist, profile, premium, verification), but it still has several production-readiness gaps:

- Some user-facing surfaces are still prototype-quality (especially map and parts of verification).
- A few high-risk engineering issues should be fixed before wider release (credentials handling, token storage, observability).
- Backend integration is mostly present, but some endpoints are either unconnected, partially connected, or at risk of contract drift.
- Localization and testing are incomplete for a multi-language production app.

## Priority Improvement Backlog

## P0 (Fix Immediately)

- **Rotate and remove signing credentials from repo workflows**
  - Evidence: `android/key.properties` currently contains real signing fields.
  - Action:
    - Rotate keystore credentials.
    - Move secrets to CI/env injection and local ignored files only.
    - Add secret scanning in CI.

- **Move auth tokens from `SharedPreferences` to secure storage**
  - Evidence: `lib/data/api/token_storage.dart` stores access/refresh tokens via `SharedPreferences`.
  - Action:
    - Use `flutter_secure_storage` (or equivalent keystore/keychain abstraction).
    - Add migration path for existing sessions.

## P1 (High Impact, Next Sprint)

- **Map tab from demo to real product behavior**
  - Evidence: `lib/features/map/screens/map_screen.dart`
    - hardcoded London center,
    - mock pins,
    - forced permission false flow for demo education.
  - Action:
    - Wire real permission checks.
    - Fetch pins from backend/provider.
    - Add loading/error/empty states and metric events.

- **Close dead/placeholder UX actions**
  - Evidence:
    - `lib/features/chat/screens/chat_list_screen.dart` search action no-op.
    - Verification methods still “coming soon” in `lib/features/verification/screens/verification_screen.dart`.
  - Action:
    - Implement chat search/filter.
    - Either wire LinkedIn/Education verification endpoints or hide feature tiles behind explicit “coming soon” sections.

- **Harden API client reliability and privacy**
  - Evidence: `lib/data/api/api_client.dart`
    - no request timeouts,
    - no backoff/circuit behavior,
    - logs response body preview.
  - Action:
    - Add per-request timeout + typed network errors.
    - Guard/disable response payload logs in production.
    - Add retry policy for transient failures (not only 401 refresh).

- **Fix environment configuration strategy**
  - Evidence: `lib/core/providers/repository_providers.dart` uses `const _config = ApiConfig.localDev;`
  - Action:
    - Use flavor/env-based config (`dev/staging/prod`) instead of hardcoded constant.
    - Add startup assert for invalid release config.

- **Observability baseline**
  - Evidence: analytics appears non-production-grade, and no clear crash reporting integration path.
  - Action:
    - Integrate Crashlytics/Sentry.
    - Add core funnel events (auth, discovery like/pass, request accept/decline, chat send, paywall conversion).

## P2 (Important, Scheduled)

- **Localization completion and consistency**
  - Evidence: `untranslated_messages.json` still has missing translations; several hardcoded strings in feature screens.
  - Action:
    - Clear untranslated keys for all supported locales.
    - Remove hardcoded user-facing strings from screens.

- **Testing foundation**
  - Evidence: minimal automated tests currently.
  - Action:
    - Add repository contract tests for critical endpoints.
    - Add widget tests for key states (loading/error/empty/permission denied/paywall).
    - Add integration happy-path tests for sign-in -> discover -> like -> chat.

- **Reduce silent failure patterns**
  - Evidence: multiple `catch (_) {}` occurrences in core flows.
  - Action:
    - Replace with structured error handling + user feedback + telemetry.

---

## Backend Endpoint Integration Matrix

Legend:
- **Connected**: implemented and actively used by app flows.
- **Partially connected**: implemented but incomplete UI flow or fallback masking.
- **Unconnected**: implemented in repository, not wired to active UI/provider flows.
- **Contract-risk**: likely schema/path mismatch risk between app and backend/docs.

| Area | Endpoint(s) | Current status | Evidence | What to improve |
|---|---|---|---|---|
| Discovery feed | `GET /discovery/recommended`, explore/pagination variants | Connected | `lib/data/repositories_api/api_discovery_repository.dart`, discovery/matches providers | Add strict response validation in non-prod to catch schema drift early. |
| Daily matches fetch | `GET /matrimony/daily-matches` | Partially connected (fallback masks failures) | `lib/data/repositories_api/api_discovery_repository.dart` | Keep fallback temporarily; add alert/logging when fallback path is hit. |
| Interests/likes actions | `/interactions/*` | Connected | `lib/data/repositories_api/api_interactions_repository.dart`, matches/discovery/chat flows | Keep as canonical contract. |
| Daily match send interest flow | docs mention `POST /interests` vs app using interactions endpoint | Contract-risk | `docs/BACKEND_DAILY_MATCHES_POPUP.md`, `api_interactions_repository.dart`, `daily_matches_popup.dart` | Align docs + backend aliases or standardize one route. |
| Chat | chat threads/messages endpoints | Connected (polling-based) | `lib/data/repositories_api/api_chat_repository.dart`, chat screens/providers | Consider websocket push to replace 5s polling loop. |
| Profile | `/profile/*` core endpoints | Connected | `lib/data/repositories_api/api_profile_repository.dart`, profile screens | Add stronger schema checks and error mapping. |
| Verification (ID) | ID upload + submit endpoints | Connected | `lib/features/verification/screens/verification_screen.dart`, `api_verification_repository.dart` | Keep; improve user feedback on failures. |
| Verification (LinkedIn/Education/others) | corresponding verification endpoints | Partially connected / effectively unconnected in UX | `verification_screen.dart` shows coming soon actions | Wire or hide until live. |
| Notifications feed | `/notifications*` endpoints | Unconnected | `lib/data/repositories_api/api_notifications_repository.dart` | Build notifications center UI or remove/defer endpoints from active contract. |
| Subscription entitlements + boost | `/subscription/entitlements`, `/boost/*` | Unconnected/partially unconnected | `lib/data/repositories_api/api_subscription_repository.dart`; entitlement logic mostly local | Decide server-vs-client source of truth for entitlements and boost. |
| Profile boost | `POST /profile/me/boost` | Unconnected | `lib/data/repositories_api/api_profile_repository.dart` | Add boost entry points in UI or remove from contract. |
| Photo-view request status | status endpoint path/field differs across docs and client parsing | Contract-risk | `api_photo_view_request_repository.dart`, `docs/BACKEND_PHOTO_VISIBILITY_AND_VIEW_REQUESTS.md`, `docs/BACKEND_API_REFERENCE.md` | Support both path/key formats short-term; standardize one canonical schema. |
| Photo-view request create | request body key (`targetUserId` vs `toUserId`) differs by docs | Contract-risk | same as above | Standardize request payload key and document canonical form. |
| Location repository endpoints | location/city integration APIs | Connected | `lib/data/repositories_api/api_location_repository.dart`, discovery city picker integration | Add endpoint contract tests for filter-dependent behavior. |
| Legacy interests repository | `/interests/*` repository stack | Unconnected (legacy path) | `lib/data/repositories_api/api_interests_repository.dart` and related providers | Deprecate or migrate fully; avoid dual-like systems. |

---

## What Is Missing Functionally

- Fully production-ready map experience (real data + permissions + behaviors).
- Complete verification feature set (only parts are operational).
- Notifications center UI (backend support exists but app flow incomplete).
- Complete chat search/organization tooling.
- Fully unified premium/paywall gating behavior across likes/requests/chat.
- Better offline/degraded-network user experience.

## What Is Working Well

- Core discovery/matches architecture and provider layering are in place.
- Backend repository structure is broad and mostly consistent.
- Multi-mode app shell (dating vs matrimony) is established.
- Localization infrastructure exists and is already integrated across many screens.

## Recommended Delivery Plan

### Sprint 1 (stability/security)
- Token secure storage migration.
- Secrets handling remediation + CI secret scan.
- API client timeout/error/telemetry hardening.
- Remove or instrument silent catches in top 5 critical flows.

### Sprint 2 (product completion)
- Map MVP backend integration.
- Verification flow completion/hide unfinished tiles.
- Chat search implementation.
- Notifications center MVP (if backend contract is final).

### Sprint 3 (quality scale-up)
- Localization completion.
- Contract tests for high-risk endpoints.
- Integration tests for main user journeys.
- Entitlements/boost contract finalization and cleanup of unconnected endpoint code.

## Tracking Checklist

- [ ] P0 security fixes complete and verified in CI.
- [ ] Endpoint matrix validated with backend owners (canonical paths + payloads frozen).
- [ ] Unconnected repositories either wired or explicitly deprecated.
- [ ] All “coming soon” UX either implemented or clearly segmented from active flows.
- [ ] Localization and test coverage targets met before release.

