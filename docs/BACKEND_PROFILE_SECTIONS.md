# Profile sections (app edit flow)

This document describes how the app breaks the profile into **sections** for editing. Each section is edited on its own screen; the user taps **Save & close** to persist and return to the profile view. The backend does **not** need separate endpoints per section: the app uses **GET /profile/me** to fetch the full profile (and prefill the form) and **PATCH /profile/me** to save. When editing a single section, the app still sends a **full profile payload** (all fields the form holds); the backend should **merge** the payload with the existing profile (partial update semantics).

---

## Endpoints used

| Action | Endpoint | Notes |
|--------|----------|--------|
| Load profile for edit | **GET /profile/me** | Returns full **UserProfile**; app prefills the section being edited. |
| Save (any section) | **PATCH /profile/me** | Body: partial or full **UserProfile** (see §9.1). Backend merges; omit fields to leave unchanged. |

The app may send the full profile JSON on each save (all fields it has in memory). Backend must support **partial update**: only update fields present in the request body; leave others unchanged.

---

## Section → fields mapping

Below, “Core” = top-level **UserProfile**; “Matrimony” = **matrimonyExtensions**; “Preferences” = **partnerPreferences**.

### 1. Basic Details (step 0 — Identity)

| Field | Location | Type | Notes |
|-------|----------|------|--------|
| name | Core | string | Required; name cannot be changed after setup in some flows. |
| aboutMe | Core | string | "About me" free text. |
| gender | Core | string | e.g. "Man", "Woman", "Non-binary". |
| dateOfBirth | Core | string | ISO 8601 date. |
| currentCity | Core | string | Current location (city). |
| currentCountry | Core | string | Current country. |
| originCity | Core | string | Hometown / from. |
| originCountry | Core | string | |
| motherTongue | Core / Matrimony | string | |
| languagesSpoken | Core | string[] | |

---

### 2. Religion & Community (matrimony; step 5 — Details)

| Field | Location | Type |
|-------|----------|------|
| religion | Matrimony | string? |
| casteOrCommunity | Matrimony | string? |
| maritalStatus | Matrimony | string? |

---

### 3. Physical Attributes (matrimony; step 5 — Details)

| Field | Location | Type | Notes |
|-------|----------|------|--------|
| heightCm | Matrimony | number? | Height in cm. |
| bodyType | Matrimony | string? | "Slim", "Athletic", "Average", "Heavy", "Curvy". |
| complexion | Matrimony | string? | "Fair", "Wheatish", "Dark", "Prefer not to say". |

---

### 4. Education & Career (matrimony; steps 3–4)

| Field | Location | Type |
|-------|----------|------|
| educationDegree | Matrimony | string? |
| educationInstitution | Matrimony | string? |
| occupation | Matrimony | string? |
| employer | Matrimony | string? |
| industry | Matrimony | string? |
| incomeRange | Matrimony | object? | { minLabel?, maxLabel?, currency? } |

---

### 5. Lifestyle & Habits (matrimony; step 5 — Details)

| Field | Location | Type |
|-------|----------|------|
| diet | Matrimony | string? |
| drinking | Matrimony | string? |
| smoking | Matrimony | string? |

---

### 6. Interests & Hobbies (step 1)

| Field | Location | Type | Notes |
|-------|----------|------|--------|
| interests | Core | string[] | Up to 6 in UI; backend may allow more. |

---

### 7. Family (matrimony; step 5 — Details)

| Field | Location | Type |
|-------|----------|------|
| familyDetails.familyType | Matrimony | string? |
| familyDetails.familyValues | Matrimony | string? |
| familyDetails.fatherOccupation | Matrimony | string? |
| familyDetails.motherOccupation | Matrimony | string? |
| familyDetails.siblingsCount | Matrimony | number? |
| familyDetails.siblingsMarried | Matrimony | (as per §9.4) |

---

### 8. Horoscope (matrimony; step 5 — Details)

| Field | Location | Type |
|-------|----------|------|
| horoscope.dateOfBirth | Matrimony | string? |
| horoscope.timeOfBirth | Matrimony | string? |
| horoscope.birthPlace | Matrimony | string? |
| horoscope.manglik | Matrimony | string? |
| horoscope.nakshatra | Matrimony | string? |
| horoscope.horoscopeDocUrl | Matrimony | string? |

---

### 9. About Me

Same as **aboutMe** in Basic Details (core). Edited in step 0.

---

### 10. Partner Preferences (step 6)

| Field | Location | Type |
|-------|----------|------|
| partnerPreferences.ageMin | Preferences | number |
| partnerPreferences.ageMax | Preferences | number |
| partnerPreferences.preferredReligions | Preferences | string[]? |
| partnerPreferences.preferredMotherTongues | Preferences | string[]? |
| partnerPreferences.educationPreference | Preferences | string? |
| partnerPreferences.maritalStatusPreference | Preferences | string[]? |
| partnerPreferences.dietPreference | Preferences | string? |
| partnerPreferences.preferredLocations | Preferences | string[]? |
| partnerPreferences.preferredCountries | Preferences | string[]? |
| partnerPreferences.cityPreferenceMode | Preferences | string? |
| partnerPreferences.strictFilters | Preferences | object? |

See **PartnerPreferences** in main API reference (§9.5).

---

### 11. Photos (step 2)

| Field | Location | Type |
|-------|----------|------|
| photoUrls | Core | string[] |

Photos are uploaded via **POST /profile/me/photos/upload-url** and **POST /profile/me/photos** (see main API reference). The app then includes the resulting URLs in **photoUrls** when calling **PATCH /profile/me**.

---

## App behaviour

- **Profile view** shows one row per section (title, section completion %, edit).
- Tapping a section opens **profile-setup** at the corresponding **step** (query: `edit=true&step=N`).
- User edits only that step; **Save & close** saves the entire in-memory form (full profile) via **PATCH /profile/me** and closes the screen.
- **GET /profile/me** is used on load to prefill the form so that saving does not overwrite other sections with empty data.

Backend must:

1. **GET /profile/me** — return full **UserProfile** including all core, matrimonyExtensions, partnerPreferences, and nested objects (familyDetails, horoscope, incomeRange).
2. **PATCH /profile/me** — merge request body with existing profile; only update fields that are present in the body. Support **bodyType** and **complexion** in **matrimonyExtensions** (see main API reference §9.4).

---

## Related

- [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) — §2 Profile API, §9.1 UserProfile, §9.4 MatrimonyExtensions, §9.5 PartnerPreferences.
