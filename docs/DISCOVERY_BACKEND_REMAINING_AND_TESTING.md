# Discovery: Remaining Backend Connectivity, Loosen-Filters, and Testing

This document covers:
1. **What’s remaining** to fully connect discovery/recommendations to the backend  
2. **Loosen-filters behaviour**: when there are no recommendations, automatically widen the search and inform the user  
3. **Filter parity** between frontend and backend  
4. **Matrimony testing** steps to verify everything works  

---

## 0. Same backend/DB and empty profiles

- **Same env:** The app uses the backend at `baseUrl` from `ApiConfig` (`lib/core/providers/repository_providers.dart`). For local dev this is `http://localhost:3000`. Run your seed against the **same** server/DB so discovery has profiles to return.
- **Network check:** In logs or network tab, confirm:
  - `GET /discovery/recommended?mode=matrimony&limit=20` (and/or `GET /discovery/explore?mode=matrimony&limit=20`) is sent and returns **200** with a JSON body that includes `"profiles": [...]`. If the array is empty, the backend has no (other) profiles for that mode/user (e.g. only one user in DB, or backend excludes same user and no others).
- **Filters not sent until set:** The app does **not** add filter query params (ageMin, ageMax, city, religion, education, diet) until the user has explicitly set them in the Refine/filters sheet and tapped Apply. Initial discovery requests use only `mode` and `limit` (and optional `city` for travel mode).

---

## 1. Current state and remaining work

### 1.1 Already connected

| Area | Status | Notes |
|------|--------|--------|
| **GET /discovery/recommended** | ✅ Connected | Used by Recommendations tab (`matchesRecommendedProvider`) and discovery feed when no filters are applied. Supports `mode`, `city` (travel), `limit`, `cursor`. |
| **GET /discovery/explore** | ✅ Partially connected | Used when user applies filters (Discover filters sheet, Explore tab). Sends `mode`, `ageMin`, `ageMax`, `city`, `religion`, `education`, `heightMinCm`, `limit`, `cursor`. |
| **GET /discovery/filter-options** | ✅ Connected | Used when opening the filters sheet; drives age, city, religion, education, diet options and defaults. |
| **Travel mode (city)** | ✅ Supported | `discoveryTravelCityProvider` + `city` query on `/discovery/recommended`. |
| **Match reasons** | ✅ Expected | Backend should return `matchReasons` (array) per profile; app uses them for “Why recommended” chips. |
| **Compatibility** | ✅ Optional | `GET /discovery/compatibility/:candidateId` used on full profile; app falls back to profile `matchReasons` if missing. |

### 1.2 Gaps to close

| Gap | Where | Action |
|-----|--------|--------|
| **Diet not sent to explore** | Backend supports `diet` on `GET /discovery/explore` (see BACKEND_API_REFERENCE §4.2). Frontend has diet in `DiscoveryFilterParams` and in the filters sheet UI, but it is **not** passed to the API. | Add `diet` to: (1) `DiscoveryRepository.getExplore()` signature, (2) `ApiDiscoveryRepository.getExplore()` (add to query map), (3) `discoveryFeedProvider` when calling `getExplore`, (4) optionally `MatchesSearchFilters` and `matchesExploreProvider` so the Discover → Refine → Explore flow sends diet in matrimony too. |
| **Loosen filters when empty** | Not implemented. When recommendations or explore returns 0 results, the app shows an empty state but does not auto-widen or inform the user. | See §2 below. |
| **User message when widening** | No copy yet for “We’ve widened the search by reducing filters.” | Add localized strings (e.g. `searchWidenedTitle`, `searchWidenedBody`) and show a banner or snackbar when showing results from a relaxed request. |

---

## 2. Loosen-filters behaviour (to implement)

### 2.1 Goals

- When there are **no recommendations** (or no results with current filters), **automatically loosen** the request so the user can still see profiles.  
- **Always inform the user** that the app has widened the search by reducing filters, so they are not confused.

### 2.2 Where it applies

| Screen / tab | Trigger | Loosen strategy | User message |
|--------------|---------|------------------|--------------|
| **Recommendations tab** (Discover) | `GET /discovery/recommended` returns 0 profiles | Fallback: call `GET /discovery/explore` with **no filters** (or very wide defaults, e.g. age 18–60, no city/religion/education). Show those as “recommendations” and set a flag that we used fallback. | Banner above list: “No recommendations matched your preferences. We’ve widened the search to show you more profiles.” (or use localized `searchWidenedTitle` / `searchWidenedBody`). |
| **Explore / Search tab** (Discover) | `GET /discovery/explore` with current filters returns 0 profiles | Option A: Retry with **progressively relaxed** filters (e.g. drop diet → then city → then religion → then education → then age range one step). Option B: Single fallback to explore with no filters. Prefer Option A so we relax stepwise. | Banner: “No results with your current filters. We’ve reduced some filters to show more profiles.” Optionally list which filters were relaxed. |

### 2.3 Implementation outline

1. **Recommendations tab**  
   - In the provider or in the widget: if `getRecommended()` returns an empty list, call `getExplore(mode, limit: 20)` with **no** filters (all params null).  
   - If that returns non-empty, show those profiles and set state like `isWidenedSearch: true`.  
   - In the UI, when `isWidenedSearch == true`, show a dismissible banner at the top with the “We’ve widened the search…” message.

2. **Explore tab**  
   - When `getExplore(filters)` returns empty and `filters` has at least one filter set, implement a small “relaxation” chain: e.g. try without diet, then without city, then without religion, then without education, then without height, then with wider age range.  
   - Use the first non-empty result set; store which request actually returned data (e.g. “relaxed” params) and set `isWidenedSearch: true`.  
   - Show a banner: “We’ve reduced some filters to show more results.”

3. **Copy**  
   - Add in app ARB/l10n: e.g. `searchWidenedTitle`, `searchWidenedBody`, and optionally `searchWidenedFiltersRelaxed` (for listing which filters were relaxed).

4. **Strict preferences**  
   - Backend may enforce strict preferences on explore. When relaxing, **do not** relax dimensions that are strict (e.g. religion if user has strict religion preference). Only relax non-strict filters so behaviour stays consistent with BACKEND_FILTER_OPTIONS_AND_PREFERENCES.

---

## 3. Filters: frontend ↔ backend parity

### 3.1 Backend (GET /discovery/explore)

From BACKEND_API_REFERENCE §4.2:

- `mode`, `limit`, `cursor`  
- `ageMin`, `ageMax`  
- `city`, `religion`, `education`, `heightMinCm`, **`diet`**

### 3.2 Frontend today

| Source | age | city | religion | education | heightMinCm | diet |
|--------|-----|------|---------|-----------|-------------|------|
| **DiscoveryFilterParams** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (not sent to API) |
| **DiscoveryFiltersSheet** | ✅ | ✅ | ✅ | ✅ | ❌ (no height in sheet?) | ✅ |
| **discoveryFeedProvider → getExplore** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ missing |
| **MatchesSearchFilters** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ missing |
| **matchesExploreProvider → getExplore** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ N/A (filters have no diet) |
| **ApiDiscoveryRepository.getExplore** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ not in signature |

So the main fix is: add **diet** end-to-end (repository interface → API implementation → discovery feed and, if desired, matches Explore tab).

### 3.3 Ensuring filters work seamlessly

- **Backend**: Ensure `GET /discovery/explore` and `GET /discovery/filter-options` accept and return the same dimensions (including diet). Strict preferences should be enforced server-side; see BACKEND_FILTER_OPTIONS_AND_PREFERENCES.  
- **Frontend**:  
  - Pass all filter dimensions from the filters sheet (and from MatchesSearchFilters for Explore tab) into `getExplore` and hence into the API.  
  - After adding diet, ensure the filters sheet and Explore tab send the same set of params the backend expects.  
- **Testing**: After implementation, test in matrimony with filters on and off; verify query params in network tab and that results respect filters (and that strict prefs are not relaxed by the app).

---

## 4. Matrimony testing checklist

Use this to verify discovery and recommendations on **matrimony** mode.

### 4.1 Setup

- [ ] App is pointed at the correct backend (e.g. staging or local).  
- [ ] Log in and switch to **Matrimony** mode (mode selector or profile/settings).  
- [ ] Ensure test user has a complete profile and, if needed, partner preferences set.

### 4.2 Recommendations tab

- [ ] Open **Discover** (main nav) and select **Recommendations** tab.  
- [ ] Confirm feed loads and shows profiles (or “No recommendations yet” if backend returns empty).  
- [ ] If backend returns 0: after implementing §2, confirm fallback to explore (no filters) and that the “We’ve widened the search” banner appears.  
- [ ] Check that each profile shows “Why recommended” style chips if backend sends `matchReasons`.

### 4.3 Refine (filters)

- [ ] Tap **Refine** (filter icon).  
- [ ] Confirm filter options load (GET /discovery/filter-options). Age, city, religion, education, diet (if in API) should appear.  
- [ ] Apply filters (e.g. age range, city, religion) and tap Apply.  
- [ ] Confirm Explore tab (or discovery feed, depending on flow) shows results filtered by those params.  
- [ ] In network tab, confirm `GET /discovery/explore` is called with the chosen `ageMin`, `ageMax`, `city`, `religion`, `education`, and (after diet is added) `diet`.

### 4.4 Explore / Search tab

- [ ] Switch to **Search** (or Explore) tab.  
- [ ] Set filters via Refine; confirm results update and match filters.  
- [ ] Set very strict filters so backend returns 0 results. After implementing §2, confirm either:  
  - retry with relaxed filters and banner “We’ve reduced some filters…”, or  
  - clear empty state message suggesting to loosen filters.  
- [ ] Confirm no crash when switching tabs with filters applied.

### 4.5 Travel mode (if used in matrimony)

- [ ] If Discover has “Change city” / travel: select a city and confirm recommendations (or explore) are requested with `city=` and results reflect that city where applicable.

### 4.6 End-to-end

- [ ] From Recommendations or Explore, open a profile → confirm full profile and compatibility (if available) load.  
- [ ] Send interest / shortlist from discovery and confirm corresponding APIs are called and UI updates.  
- [ ] Verify filters persist correctly when reopening the filters sheet and when switching between Recommendations / Visitors / Search / Matches.

---

## 5. Summary

| Item | Status / action |
|------|------------------|
| Recommendations & explore API | Connected; add **diet** to explore path end-to-end. |
| Filter options & travel | Connected. |
| Loosen filters when no results | **To implement**: fallback + banner on Recommendations; relaxed-filters retry + banner on Explore. |
| User messaging | Add l10n keys and show “We’ve widened the search by reducing filters” when showing relaxed results. |
| Filters parity | Align frontend and backend (diet + any other dimensions); ensure strict preferences are not relaxed by the app. |
| Matrimony testing | Use §4 checklist on matrimony mode; validate recommendations, Refine, Explore, and empty-state / widen behaviour. |

Once diet is wired through and the loosen-filters + user messaging are in place, run the full matrimony test pass and update this doc if you add new endpoints or behaviours.
