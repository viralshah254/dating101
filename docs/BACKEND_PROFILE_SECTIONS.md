# Profile sections (app edit flow)

This document describes the **section-based profile edit** flow: each profile section has its own screen. The user taps a section on the profile view (e.g. "Basic Details", "Religion & Community") → opens **one screen** with only that section’s fields → edits → **Save & close** → data is saved and the user returns to the profile view.

The backend does **not** need separate endpoints per section. The app uses **GET /profile/me** to load the full profile (and prefill the form) and **PATCH /profile/me** to save. When saving after editing one section, the app may send a **full profile payload** (all fields it has in memory); the backend should **merge** the request body with the existing profile (partial update semantics).

---

## App structure (for reference)

- **Profile view:** One card per section (title, section completion %, edit). Tapping a card opens the section edit screen.
- **Section edit:** One route `/profile-edit?section=<sectionId>`. Section IDs: `basic`, `religion`, `physical`, `education-career`, `lifestyle`, `interests`, `family`, `horoscope`, `about`, `preferences`, `photos`.
- **Flow:** Open section → load profile (GET /profile/me) → show only that section’s fields → user edits → Save & close → PATCH /profile/me → pop.

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

### 1. Basic Details

**What we collect:** Name, about me, gender, looking for (partner gender), date of birth, current location (city/country), hometown / origin.

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

---

### 2. Religion & Community (matrimony)

**What we collect:** Religion, community/caste, mother tongue, languages spoken, **marital status** (life situation, not physical).

| Field | Location | Type | Notes |
|-------|----------|------|--------|
| religion | Matrimony | string? | e.g. Hindu, Muslim, Christian, Sikh, Jain. |
| casteOrCommunity | Matrimony | string? | Community/caste. |
| motherTongue | Core / Matrimony | string? | |
| languagesSpoken | Core | string[] | |
| maritalStatus | Matrimony | string? | "Never married", "Divorced", "Widowed", "Awaiting divorce". |

---

### 3. Physical Attributes (matrimony)

**What we collect:** Only physical attributes — height, body type, complexion, disability. (Marital status is in Religion & Community.)

| Field | Location | Type | Notes |
|-------|----------|------|--------|
| heightCm | Matrimony | number? | Height in cm. |
| bodyType | Matrimony | string? | "Slim", "Athletic", "Average", "Heavy", "Curvy". |
| complexion | Matrimony | string? | "Fair", "Wheatish", "Dark", "Prefer not to say". |
| disability | Matrimony | string? | "None", "Physical", "Prefer not to say". |

---

### 4. Education & Career (matrimony)

| Field | Location | Type | Notes |
|-------|----------|------|--------|
| educationDegree | Matrimony | string? | Primary degree (also from first entry). |
| educationInstitution | Matrimony | string? | Primary institution (also from first entry). |
| **educationEntries** | **Matrimony** | **array?** | **Each: degree, institution, graduationYear (number), scoreCountry (e.g. "UK", "India"), scoreType (e.g. "Upper second (2:1)").** |
| **aboutEducation** | **Matrimony** | **string?** | **Free-text "About your education"; shown in About section.** |
| occupation | Matrimony | string? | |
| employer | Matrimony | string? | |
| industry | Matrimony | string? | |
| incomeRange | Matrimony | object? | { minLabel?, maxLabel?, currency? } |

**Backend must persist and return** `educationEntries` and `aboutEducation` so that year of graduation, grading system, degree grade/classification, and "About your education" save and display correctly.

---

### 5. Lifestyle & Habits (matrimony)

| Field | Location | Type | Notes |
|-------|----------|------|--------|
| diet | Matrimony | string? | |
| drinking | Matrimony | string? | |
| smoking | Matrimony | string? | |
| **exercise** | **Matrimony** | **string?** | **"Daily", "Regularly", "Sometimes", "Rarely". Must persist and return.** |

---

### 6. Interests & Hobbies

| Field | Location | Type | Notes |
|-------|----------|------|--------|
| interests | Core | string[] | Up to 6 in UI; backend may allow more. |

---

### 7. Family (matrimony)

| Field | Location | Type | Notes |
|-------|----------|------|--------|
| familyDetails.familyType | Matrimony | string? | Nuclear / Joint. |
| familyDetails.familyValues | Matrimony | string? | Traditional / Moderate / Liberal. |
| **familyDetails.familyLocation** | **Matrimony** | **string?** | **Display name of family location.** |
| **familyDetails.familyBasedOutOfCountry** | **Matrimony** | **string?** | **Country (e.g. "India") for currency.** |
| **familyDetails.householdIncome** | **Matrimony** | **string?** | **e.g. "Rs 20-50 LPA".** |
| familyDetails.fatherOccupation | Matrimony | string? | |
| familyDetails.motherOccupation | Matrimony | string? | |
| **familyDetails.fatherAge** | **Matrimony** | **string?** | **e.g. "50" or "Deceased".** |
| **familyDetails.motherAge** | **Matrimony** | **string?** | **e.g. "45" or "Deceased".** |
| familyDetails.siblingsCount | Matrimony | number? | Derived or legacy. |
| familyDetails.siblingsMarried | Matrimony | (as per §9.4) | |
| **familyDetails.brothers** | **Matrimony** | **string?** | **"None", "1", "2", "3", "4+".** |
| **familyDetails.sisters** | **Matrimony** | **string?** | **"None", "1", "2", "3", "4+".** |

**Backend must persist and return** all familyDetails fields above so family section saves and reloads correctly.

---

### 8. Horoscope (matrimony)

| Field | Location | Type | Notes |
|-------|----------|------|--------|
| horoscope.dateOfBirth | Matrimony | string? | |
| horoscope.timeOfBirth | Matrimony | string? | |
| horoscope.birthPlace | Matrimony | string? | |
| horoscope.manglik | Matrimony | string? | |
| **horoscope.rashi** | **Matrimony** | **string?** | **Rashi (Moon sign). Must persist and return.** |
| horoscope.nakshatra | Matrimony | string? | |
| **horoscope.gotra** | **Matrimony** | **string?** | **Gotra. Must persist and return.** |
| horoscope.horoscopeDocUrl | Matrimony | string? | |

**Backend must persist and return** `rashi` and `gotra` so they are shown when the user returns to the horoscope screen.

---

### 9. About Me

**What we collect:** Single free-text "About me" field only.

| Field | Location | Type |
|-------|----------|------|
| aboutMe | Core | string |

---

### 10. Partner Preferences

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

### 11. Photos

| Field | Location | Type |
|-------|----------|------|
| photoUrls | Core | string[] |

Photos are uploaded via **POST /profile/me/photos/upload-url** and **POST /profile/me/photos** (see main API reference). The app then includes the resulting URLs in **photoUrls** when calling **PATCH /profile/me**.

---

### 12. Photo visibility (privacy)

Users can hide their photos (all or some) and require others to **request to view pictures**; the profile owner accepts or declines. Full API: [BACKEND_PHOTO_VISIBILITY_AND_VIEW_REQUESTS.md](./BACKEND_PHOTO_VISIBILITY_AND_VIEW_REQUESTS.md).

| Field | Location | Type | Notes |
|-------|----------|------|--------|
| photoVisibility | Core or preferences | string | `everyone` \| `on_request` \| `none`. Persist and return so the app can show the correct option in Preferences. |
| lockedPhotoIds | Core or preferences | string[]? | Optional. When `on_request`, which photo IDs require request-to-view; if omitted, all photos are locked. |

The app will send **photoVisibility** (and optionally **lockedPhotoIds**) via **PATCH /profile/me** when the user changes “Who can see my photos” in Preferences (or a dedicated Privacy / Photo visibility section).

---

## What we send to the backend (PATCH /profile/me)

The app sends a **single merged payload** (full profile shape). Backend must **merge** the body with the existing profile. No per-section endpoints.

| Section | Keys in request body (under core / matrimonyExtensions / partnerPreferences) |
|---------|-------------------------------------------------------------------------------|
| Basic | name, aboutMe, gender, dateOfBirth, currentCity, currentCountry, originCity, originCountry, (interestedIn in preferences) |
| Religion & Community | religion, casteOrCommunity, motherTongue, languagesSpoken, maritalStatus |
| Physical | heightCm, bodyType, complexion, disability |
| Education & Career | educationDegree, educationInstitution, **educationEntries** (array: degree, institution, graduationYear, scoreCountry, scoreType), **aboutEducation**, occupation, employer, industry, incomeRange |
| Lifestyle | diet, drinking, smoking, **exercise** |
| Interests | interests |
| Family | familyDetails (familyType, familyValues, **familyLocation**, **familyBasedOutOfCountry**, **householdIncome**, fatherOccupation, motherOccupation, **fatherAge**, **motherAge**, siblingsCount, **brothers**, **sisters**, etc.) |
| Horoscope | horoscope (manglik, **rashi**, nakshatra, **gotra**, timeOfBirth, birthPlace, dateOfBirth) |
| About Me | aboutMe |
| Partner Preferences | partnerPreferences (ageMin, ageMax, preferredReligions, preferredMotherTongues, educationPreference, maritalStatusPreference, dietPreference, incomePreference, preferredLocations, preferredCountries, cityPreferenceMode, **strictFilters** (object: religion, motherTongue, education, maritalStatus, income, diet, drinking, smoking, settledAbroad), etc.) |
| Photos | photoUrls |
| Photo visibility | photoVisibility, lockedPhotoIds? (see [BACKEND_PHOTO_VISIBILITY_AND_VIEW_REQUESTS.md](./BACKEND_PHOTO_VISIBILITY_AND_VIEW_REQUESTS.md)) |

---

## App behaviour

- **Profile view** shows one row per section (title, section completion %, edit).
- Tapping a section opens **/profile-edit?section=&lt;sectionId&gt;** (dedicated screen for that section only).
- User edits only that section’s fields; **Save & close** saves the entire in-memory form (full profile) via **PATCH /profile/me** and closes the screen.
- **GET /profile/me** is used on load to prefill the form so that saving does not overwrite other sections with empty data.

Backend must:

1. **GET /profile/me** — return full **UserProfile** including all core, matrimonyExtensions, partnerPreferences, and nested objects. **Must include** in response so the app can prefill and display correctly:
   - **matrimonyExtensions**: `exercise`, `aboutEducation`, `educationEntries` (array of { degree, institution, graduationYear, scoreCountry, scoreType })
   - **matrimonyExtensions.horoscope**: `rashi`, `gotra` (in addition to manglik, nakshatra, timeOfBirth, birthPlace)
   - **matrimonyExtensions.familyDetails**: `familyLocation`, `familyBasedOutOfCountry`, `householdIncome`, `fatherAge`, `motherAge`, `brothers`, `sisters`
   - **partnerPreferences**: `strictFilters` (object with keys religion, motherTongue, education, maritalStatus, income, diet, drinking, smoking, settledAbroad; values boolean)
2. **PATCH /profile/me** — merge request body with existing profile; only update fields that are present in the body. Persist and return the fields listed above so that Education (year, grading, degree, about education), Lifestyle (exercise), Family, Horoscope (rashi, nakshatra, gotra), and Partner preferences (including strict toggles) all save and reload correctly.

---

## Related

- [BACKEND_API_REFERENCE.md](./BACKEND_API_REFERENCE.md) — §2 Profile API, §9.1 UserProfile, §9.4 MatrimonyExtensions, §9.5 PartnerPreferences.
