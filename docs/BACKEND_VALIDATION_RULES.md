# Saathi Backend — Field Validation & Optionality Rules

Which fields are required vs optional when creating/updating a profile via
`PUT /profile/me` and `PATCH /profile/me`.

---

## 1. Core principle

**Profile creation is progressive.** Users fill their profile across 7 steps
and may skip most of them. The backend must accept a profile with only the
bare minimum fields and allow everything else to be filled in later via PATCH.

---

## 2. PUT /profile/me — minimum required fields

Only these fields are **required** on initial profile creation:

| Field | Type | Notes |
|-------|------|-------|
| `name` | string | Min 2 characters |
| `gender` | string | Enum: `"Man"`, `"Woman"`, `"Non-binary"` |
| `dateOfBirth` | string | ISO date `"YYYY-MM-DD"`. Must be 18+ |

Everything else — including `matrimonyExtensions`, `datingExtensions`,
`partnerPreferences`, `photoUrls`, `interests`, location fields — is
**optional** on PUT and can be sent later via PATCH.

---

## 3. PATCH /profile/me — all fields optional

PATCH should accept any subset of fields and merge them into the existing
profile. No field is required on PATCH.

---

## 4. Top-level profile fields

| Field | Type | Required on PUT | Notes |
|-------|------|-----------------|-------|
| `name` | string | **Yes** | Min 2 chars, max 100 |
| `gender` | string | **Yes** | Enum: `"Man"`, `"Woman"`, `"Non-binary"` |
| `dateOfBirth` | string | **Yes** | ISO date, must be 18+ |
| `aboutMe` | string | No | Free text bio, max 500 chars |
| `currentCity` | string | No | |
| `currentCountry` | string | No | |
| `originCity` | string | No | Hometown |
| `originCountry` | string | No | |
| `motherTongue` | string | No | |
| `languagesSpoken` | string[] | No | |
| `photoUrls` | string[] | No | Array of CDN URLs, max 6 |
| `interests` | string[] | No | Array of interest tags |
| `creationLat` | number | No | Set once on first creation |
| `creationLng` | number | No | Set once on first creation |
| `creationAt` | string | No | ISO datetime, set once |
| `creationAddress` | string | No | Reverse-geocoded, set once |

---

## 5. matrimonyExtensions (entirely optional)

The entire `matrimonyExtensions` object is **optional**. When provided, every
field inside it is also optional. The backend should not reject a profile
because `matrimonyExtensions` is missing or partially filled.

| Field | Type | Required | Enum values (if applicable) |
|-------|------|----------|-----------------------------|
| `roleManagingProfile` | string | No | `"self"`, `"parent"`, `"guardian"`, `"sibling"`, `"friend"` |
| `religion` | string | No | Free text (e.g. "Hindu", "Muslim", "Christian", "Sikh", "Buddhist", "Jain", "Other") |
| `casteOrCommunity` | string | No | Free text |
| `motherTongue` | string | No | Free text |
| `maritalStatus` | string | No | `"Never married"`, `"Divorced"`, `"Widowed"`, `"Awaiting Divorce"` |
| `heightCm` | number | No | Integer, range 100–250 |
| `bodyType` | string | No | `"Slim"`, `"Athletic"`, `"Average"`, `"Heavy"` |
| `complexion` | string | No | `"Fair"`, `"Wheatish"`, `"Dark"`, `"Very fair"` |
| `disability` | string | No | `"None"`, `"Physical"`, `"Visual"`, `"Hearing"`, `"Other"` |
| `educationDegree` | string | No | Free text (e.g. "B.Tech", "MBA", "Masters", "PhD") |
| `educationInstitution` | string | No | Free text |
| `occupation` | string | No | Free text |
| `employer` | string | No | Free text |
| `industry` | string | No | Free text |
| `workLocation` | string | No | Free text |
| `settledAbroad` | string | No | `"Yes"`, `"No"`, `"Planning to"` |
| `willingToRelocate` | string | No | `"Yes"`, `"No"`, `"Maybe"` |
| `incomeRange` | object | No | `{ minLabel: string, maxLabel?: string, currency?: string }` |
| `diet` | string | No | `"Vegetarian"`, `"Non-vegetarian"`, `"Eggetarian"`, `"Vegan"`, `"Jain"` |
| `drinking` | string | No | `"Non-drinker"`, `"Social"`, `"Regular"` |
| `smoking` | string | No | `"Non-smoker"`, `"Occasional"`, `"Regular"` |
| `exercise` | string | No | `"Daily"`, `"Often"`, `"Sometimes"`, `"Never"` |
| `pets` | string | No | `"Dog"`, `"Cat"`, `"Both"`, `"Other"`, `"None"` |
| `aboutEducation` | string | No | Free text |
| `aboutCareer` | string | No | Free text |

### 5.1 matrimonyExtensions.educationEntries (optional array)

When present, each entry is an object. An empty array `[]` is fine; an array
with empty objects `[{}]` should be **ignored or accepted** (not rejected).

| Field | Type | Required within entry | Notes |
|-------|------|----------------------|-------|
| `degree` | string | No | e.g. "Masters", "B.Tech" |
| `institution` | string | No | e.g. "University of Kent" |
| `graduationYear` | number | No | e.g. 2024 |
| `scoreCountry` | string | No | e.g. "UK", "India", "US" |
| `scoreType` | string | No | e.g. "First class", "2:1", "GPA 3.5" |

**Important:** If an entry has no fields set (empty object `{}`), the backend
should skip it rather than return a validation error.

### 5.2 matrimonyExtensions.familyDetails (optional object)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `familyType` | string | No | `"Joint"`, `"Nuclear"`, `"Other"` |
| `familyValues` | string | No | `"Traditional"`, `"Moderate"`, `"Liberal"` |
| `fatherOccupation` | string | No | |
| `motherOccupation` | string | No | |
| `fatherAge` | string | No | Number as string, or `"Deceased"` |
| `motherAge` | string | No | Number as string, or `"Deceased"` |
| `siblingsCount` | number | No | |
| `brothers` | string | No | `"None"`, `"1"`, `"2"`, `"3"`, `"4+"` |
| `sisters` | string | No | `"None"`, `"1"`, `"2"`, `"3"`, `"4+"` |
| `familyLocation` | string | No | |
| `familyBasedOutOfCountry` | string | No | Country name |
| `householdIncome` | string | No | |

### 5.3 matrimonyExtensions.horoscope (optional object)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `dateOfBirth` | string | No | ISO date |
| `timeOfBirth` | string | No | e.g. "06:42 AM" |
| `birthPlace` | string | No | |
| `manglik` | string | No | `"Manglik"`, `"Non-Manglik"`, `"Anshik Manglik"` |
| `nakshatra` | string | No | e.g. "Rohini" |
| `rashi` | string | No | e.g. "Vrishabh" |
| `gotra` | string | No | |
| `horoscopeDocUrl` | string | No | URL |

If horoscope is an empty object `{}`, accept it or ignore it.

---

## 6. datingExtensions (entirely optional)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `datingIntent` | string | No | `"serious"`, `"casual"`, `"marriage"`, `"friends first"` |
| `prompts` | array | No | `[{ questionId, questionText, answer }]` |
| `voiceIntroUrl` | string | No | URL |
| `travelModeEnabled` | boolean | No | Default false |
| `discoveryPreferences` | object | No | See below |

### 6.1 datingExtensions.discoveryPreferences

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `ageMin` | number | No | Default 18 |
| `ageMax` | number | No | Default 99 |
| `maxDistanceKm` | number | No | Default 50 |
| `preferredCities` | string[] | No | |
| `travelModeEnabled` | boolean | No | Default false |

---

## 7. partnerPreferences (entirely optional)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `genderPreference` | string | No | `"Man"`, `"Woman"`, `"Any"` |
| `ageMin` | number | No | Default 21 |
| `ageMax` | number | No | Default 45 |
| `heightMinCm` | number | No | |
| `heightMaxCm` | number | No | |
| `preferredLocations` | string[] | No | City names |
| `preferredReligions` | string[] | No | |
| `preferredCommunities` | string[] | No | |
| `preferredMotherTongues` | string[] | No | |
| `educationPreference` | string | No | e.g. "Masters+", "Any" |
| `occupationPreference` | string | No | |
| `maritalStatusPreference` | string[] | No | |
| `dietPreference` | string | No | |
| `incomePreference` | string | No | |
| `drinkingPreference` | string | No | `"Non-drinker"`, `"Social"`, `"Doesn't matter"` |
| `smokingPreference` | string | No | `"Non-smoker"`, `"Doesn't matter"` |
| `settledAbroadPreference` | string | No | `"Yes"`, `"No"`, `"Doesn't matter"` |
| `preferredCountries` | string[] | No | |
| `cityPreferenceMode` | string | No | `"any"`, `"same_as_me"`, `"preferred"` |
| `distanceMaxKm` | number | No | |
| `horoscopeMatchPreferred` | boolean | No | |

### 7.1 partnerPreferences.strictFilters (optional object)

All boolean, all default `false`. When a strict filter is `true`, that
preference becomes a hard filter in the matching engine.

| Field | Type | Default |
|-------|------|---------|
| `religion` | boolean | false |
| `motherTongue` | boolean | false |
| `education` | boolean | false |
| `maritalStatus` | boolean | false |
| `income` | boolean | false |
| `diet` | boolean | false |
| `drinking` | boolean | false |
| `smoking` | boolean | false |
| `settledAbroad` | boolean | false |

---

## 8. Validation error handling

When the backend encounters validation errors, return:

```json
{
  "code": "VALIDATION_ERROR",
  "message": "Invalid profile data",
  "details": {
    "fieldName": ["Error message"]
  }
}
```

The frontend uses `details` to show per-field errors. Only validate:

1. **Required fields** (name, gender, dateOfBirth) on PUT
2. **Enum values** — reject unknown enums but with a clear message
3. **Type correctness** — numbers are numbers, strings are strings
4. **Range constraints** — age 18+, height 100-250, etc.

Do **not** reject requests because optional sections (matrimonyExtensions,
datingExtensions, partnerPreferences) are missing or partially filled.

---

## 9. Enum value mapping reference

### roleManagingProfile

The frontend UI shows relationship labels, which are mapped before sending:

| UI label | API value |
|----------|-----------|
| "Self" (null/not set) | field omitted |
| "Son" or "Daughter" | `"parent"` |
| "Brother" or "Sister" | `"sibling"` |
| "Friend" | `"friend"` |
| "Relative" | `"guardian"` |

### gender

| Value |
|-------|
| `"Man"` |
| `"Woman"` |
| `"Non-binary"` |

### genderPreference (partnerPreferences)

| Value | Meaning |
|-------|---------|
| `"Man"` | Looking for men |
| `"Woman"` | Looking for women |
| `"Any"` | No preference |

---

## 10. Example: minimal valid PUT

```json
PUT /profile/me

{
  "name": "Priya Sharma",
  "gender": "Woman",
  "dateOfBirth": "1997-05-15"
}
```

This should succeed with `200 OK` or `201 Created`. The user can then
progressively fill in everything else via PATCH.

---

## 11. Example: progressive PATCH (step by step)

**After step 2 (details):**

```json
PATCH /profile/me

{
  "matrimonyExtensions": {
    "religion": "Hindu",
    "heightCm": 165,
    "educationDegree": "Masters"
  }
}
```

**After step 5 (preferences):**

```json
PATCH /profile/me

{
  "partnerPreferences": {
    "genderPreference": "Man",
    "ageMin": 25,
    "ageMax": 32,
    "preferredReligions": ["Hindu"]
  }
}
```

Each PATCH merges with existing data. No field is required on PATCH.
