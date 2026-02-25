# Saathi — Discovery Filter Options & Strict Preferences API

Backend specification for the **Explore** tab filters. Filters must respect the user’s profile and **strict preferences**: if the user has marked a preference as strict (e.g. religion, diet), the filter options and defaults must not offer choices that conflict with that.

---

## Table of contents

1. [Overview](#1-overview)
2. [Strict vs non-strict preferences](#2-strict-vs-non-strict-preferences)
3. [API: Get filter options](#3-api-get-filter-options)
4. [Response shape](#4-response-shape)
5. [Backend logic](#5-backend-logic)
6. [Frontend behaviour](#6-frontend-behaviour)
7. [Search endpoint alignment](#7-search-endpoint-alignment)

---

## 1. Overview

- The **Explore** tab lets users filter profiles by age, city, religion, education, etc.
- Filter **options** (e.g. list of cities, religions) and **defaults** (e.g. age range) should be driven by:
  - The user’s **partner preferences** (what they’re looking for).
  - The **strict** flags on those preferences (e.g. “Strict” on religion).
- If a preference is **strict**, the backend should only expose that option (or a single fixed value) so the UI does not show “wrong” filters.

---

## 2. Strict vs non-strict preferences

From the user’s profile and partner preferences we have dimensions that can be marked **strict** or not:

| Dimension   | Strict meaning | Non-strict meaning |
|------------|----------------|---------------------|
| Age range  | Only show profiles in this range; filter should default to it and optionally lock. | User is flexible; show full range (e.g. 18–60) and allow any selection. |
| Religion   | Only show this religion; filter should show only this option (or hide religion filter). | Show all religions; user can pick one or leave open. |
| City       | Only show these cities; filter options = preferred cities only. | Show broader city list. |
| Education  | Only show this level or above; filter options constrained. | Show all education options. |
| Diet       | Only show matching diet; filter should not offer conflicting options. | Show all options. |
| Drinking   | Strict = no drinking; filter should not offer “Drinks” if strict. | Show all options. |
| Smoking    | Strict = no smoking; filter should not offer “Smokes” if strict. | Show all options. |
| Settled abroad | Strict = only NRI / only India; filter options constrained. | Show “Any”, “India”, “Abroad”, etc. |

**Rule:** For any dimension marked **strict**, the backend must not return filter options that would allow the user to select a value that contradicts their strict preference. Prefer returning a single allowed value (or a locked default) so the UI can show “Religion: Hindu (from your preferences)” and not offer other religions.

---

## 3. API: Get filter options

```
GET /discovery/filter-options
```

**Authentication:** Required (Bearer token).

**Response:** `200 OK` with a JSON body describing allowed filter options and defaults per dimension. See [§4](#4-response-shape).

**Purpose:** The frontend calls this when opening the Explore filters sheet. It uses the response to:

- Populate dropdowns/chips only with **allowed** options.
- Pre-fill defaults (e.g. age range from partner preferences).
- Show or hide dimensions (e.g. hide religion filter if strict and single value).
- Optionally show a “Strict” badge and disable changing that dimension.

---

## 4. Response shape

```typescript
interface FilterOptionsResponse {
  /** Age range allowed for filtering. If user has strict age preference, min/max match it. */
  age: {
    min: number;           // e.g. 21
    max: number;          // e.g. 45
    defaultMin: number;   // from partner preferences
    defaultMax: number;
    strict: boolean;      // if true, UI may show as fixed or single range
  };

  /** Cities the user can filter by. If strict on location, only preferred cities. */
  cities: {
    options: string[];   // e.g. ["Mumbai", "Delhi", "Bangalore", "London", ...]
    strict: boolean;
    defaultSelected?: string | null;  // if strict, the only allowed value
  };

  /** Religions. If strict on religion, only one option (or empty = use profile default). */
  religions: {
    options: string[];
    strict: boolean;
    defaultSelected?: string | null;
  };

  /** Education levels. If strict, only allowed levels (e.g. "Master's" and above). */
  education: {
    options: string[];
    strict: boolean;
    defaultSelected?: string | null;
  };

  /** Optional: height range (cm). */
  height?: {
    minCm: number;
    maxCm: number;
    defaultMinCm?: number;
    defaultMaxCm?: number;
    strict: boolean;
  };

  /** Optional: diet. If strict diet (e.g. Vegetarian), only show matching. */
  diet?: {
    options: string[];
    strict: boolean;
    defaultSelected?: string | null;
  };

  /** Optional: marital status. If strict, only allowed statuses. */
  maritalStatus?: {
    options: string[];
    strict: boolean;
  };
}
```

**Example (non-strict user):**

```json
{
  "age": {
    "min": 18,
    "max": 60,
    "defaultMin": 24,
    "defaultMax": 35,
    "strict": false
  },
  "cities": {
    "options": ["Mumbai", "Delhi", "Bangalore", "Chennai", "Hyderabad", "Pune", "London", "Dubai", "New York"],
    "strict": false
  },
  "religions": {
    "options": ["Hindu", "Muslim", "Christian", "Sikh", "Jain", "Buddhist", "Parsi", "Jewish", "Other"],
    "strict": false
  },
  "education": {
    "options": ["High School", "Diploma", "Bachelor's", "Master's", "Doctorate"],
    "strict": false
  }
}
```

**Example (user with strict religion = Hindu):**

```json
{
  "age": { "min": 21, "max": 45, "defaultMin": 25, "defaultMax": 32, "strict": false },
  "cities": { "options": ["Mumbai", "Delhi", "Bangalore", "..."], "strict": false },
  "religions": {
    "options": ["Hindu"],
    "strict": true,
    "defaultSelected": "Hindu"
  },
  "education": {
    "options": ["Bachelor's", "Master's", "Doctorate"],
    "strict": false
  }
}
```

In the second example, the frontend should only show “Hindu” for religion (or hide the religion filter and pass `religion: "Hindu"` when searching). It must not show “Muslim”, “Christian”, etc., because that would contradict the user’s strict preference.

---

## 5. Backend logic

1. **Load current user’s profile** and **partner preferences** (including strict flags).
2. **Age**
   - If strict age preference: set `age.min` / `age.max` and `defaultMin` / `defaultMax` from preferences; set `strict: true`.
   - Else: use app-wide bounds (e.g. 18–60) and defaults from preferences; `strict: false`.
3. **Religion**
   - If strict religion: `options = [preferredReligion]`, `strict: true`, `defaultSelected = preferredReligion`.
   - Else: `options =` full list; `strict: false`.
4. **Cities**
   - If strict on location: `options =` preferred cities (or allowed list from preferences); `strict: true`; optionally `defaultSelected`.
   - Else: `options =` full or curated city list; `strict: false`.
5. **Education**
   - If strict (e.g. “Master’s and above”): `options =` only allowed levels; `strict: true`.
   - Else: full list; `strict: false`.
6. **Diet / drinking / smoking / settled abroad**
   - If strict, only include options that match the preference (e.g. if “No smoking” strict, don’t include “Smokes” in options).

Return the built object as the body of `GET /discovery/filter-options`.

---

## 6. Frontend behaviour

- Call `GET /discovery/filter-options` when opening the filter sheet (or cache with invalidation on profile/preferences change).
- **Populate controls** only from `options`; do not show values that are not in the list.
- **Defaults:** Use `defaultMin`/`defaultMax` and `defaultSelected` to pre-fill the form.
- **Strict dimensions:** If `strict: true` and a single option (or fixed range), the UI can:
  - Show the dimension as read-only with a “From your preferences” or “Strict” label, or
  - Hide that filter and always send the fixed value when calling search.
- **Apply button:** Always visible at the bottom of the sheet (fixed footer). On Apply, call `GET /discovery/search` (or equivalent) with the selected filter values.

---

## 7. Search endpoint alignment

The existing search endpoint (e.g. `GET /discovery/search`) should accept the same dimensions that filter-options exposes:

- `ageMin`, `ageMax`
- `city`
- `religion`
- `education`
- `heightMinCm`, `heightMaxCm` (if supported)
- etc.

Backend must **enforce** that when the user has a strict preference, the search either:

- Ignores conflicting filter values and applies the strict preference server-side, or
- Returns an error if the client sends a filter that contradicts a strict preference.

Prefer **server-side enforcement**: if the user’s profile says “Strict: Hindu”, the search should only return Hindu profiles even if the client sends something else. This keeps behaviour correct even if the frontend is out of date or bypassed.

---

## Quick reference

| Item | Value |
|------|--------|
| Endpoint | `GET /discovery/filter-options` |
| Auth | Bearer token required |
| Response | JSON object with `age`, `cities`, `religions`, `education`, and optional `height`, `diet`, `maritalStatus` |
| Strict behaviour | For each dimension with `strict: true`, only return allowed option(s); frontend must not show or send conflicting values |
| Search | `GET /discovery/search` (or equivalent) must respect strict preferences server-side |
