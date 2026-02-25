# Profile Schema — Complete Backend Specification

> This document lists **every field** the backend must store for user profiles.
> Fields marked **NEW** do not exist in the current backend schema and must be added.
> Fields marked **EXISTING** are already supported.

---

## 1. Top-level `UserProfile`

| Field | Type | Required | Status | Description |
|-------|------|----------|--------|-------------|
| id | string | Yes | EXISTING | Same as auth userId |
| name | string | Yes | EXISTING | Full name |
| gender | string? | No | EXISTING | `"Man"`, `"Woman"`, `"Non-binary"` |
| age | number? | No | EXISTING | Computed from dateOfBirth |
| dateOfBirth | string? | No | EXISTING | ISO 8601 date (`YYYY-MM-DD`) |
| currentCity | string? | No | EXISTING | Where user lives now |
| currentCountry | string? | No | EXISTING | |
| originCity | string? | No | EXISTING | Hometown |
| originCountry | string? | No | EXISTING | |
| languagesSpoken | string[] | No | EXISTING | Default `[]` |
| motherTongue | string? | No | EXISTING | |
| photoUrls | string[] | No | EXISTING | Default `[]` |
| aboutMe | string | No | EXISTING | Default `""` |
| interests | string[] | No | EXISTING | Default `[]` |
| verificationStatus | object? | No | EXISTING | See §6 |
| profileCompleteness | number | No | EXISTING | 0.0–1.0, backend-computed |
| isVerified | boolean | No | EXISTING | `true` if score ≥ threshold |
| privacySettings | object? | No | EXISTING | key → boolean |
| datingExtensions | object? | No | EXISTING | See §3 |
| matrimonyExtensions | object? | No | EXISTING | See §2 |
| partnerPreferences | object? | No | EXISTING | See §4 |
| lastActiveAt | string? | No | EXISTING | ISO 8601 datetime |
| creationLat | number? | No | EXISTING | Lat at profile creation |
| creationLng | number? | No | EXISTING | Lng at profile creation |
| creationAt | string? | No | EXISTING | ISO 8601 datetime |
| creationAddress | string? | No | EXISTING | Reverse-geocoded address |

---

## 2. `MatrimonyExtensions`

Stored as `matrimonyExtensions` on the profile. All fields optional.

### 2.1 Core identity & physical

| Field | Type | Status | Description |
|-------|------|--------|-------------|
| roleManagingProfile | string? | EXISTING | `"self"`, `"parent"`, `"guardian"`, `"sibling"`, `"friend"` |
| religion | string? | EXISTING | e.g. `"Hindu"`, `"Muslim"`, `"Christian"` |
| casteOrCommunity | string? | EXISTING | e.g. `"Brahmin"`, `"Rajput"` |
| motherTongue | string? | EXISTING | e.g. `"Hindi"`, `"Tamil"` |
| maritalStatus | string? | EXISTING | `"Never married"`, `"Divorced"`, `"Widowed"`, `"Awaiting Divorce"` |
| heightCm | number? | EXISTING | Height in centimeters |
| bodyType | string? | **NEW** | `"Slim"`, `"Athletic"`, `"Average"`, `"Heavy"` |
| complexion | string? | **NEW** | `"Fair"`, `"Wheatish"`, `"Dark"`, `"Very fair"` |
| disability | string? | **NEW** | `"None"`, `"Physical"`, `"Visual"`, `"Hearing"`, `"Other"` |

### 2.2 Education

| Field | Type | Status | Description |
|-------|------|--------|-------------|
| educationDegree | string? | EXISTING | Highest degree, e.g. `"B.Tech"`, `"MBA"` |
| educationInstitution | string? | EXISTING | University/college name |
| educationEntries | object[]? | **NEW** | Array of `{ degree, institution, graduationYear, scoreCountry, scoreType }` |
| aboutEducation | string? | **NEW** | Free-text about education |

> `educationEntries` allows multiple degrees. Each entry:
>
> | Field | Type | Description |
> |-------|------|-------------|
> | degree | string | e.g. `"B.Tech"`, `"MBA"` |
> | institution | string? | University/college |
> | graduationYear | number? | e.g. `2020` |
> | scoreCountry | string? | `"India"`, `"UK"`, `"US"`, `"Other"` |
> | scoreType | string? | `"First class"`, `"2:1"`, `"GPA 3.5"` |

### 2.3 Career

| Field | Type | Status | Description |
|-------|------|--------|-------------|
| occupation | string? | EXISTING | e.g. `"Software Engineer"` |
| employer | string? | EXISTING | Company name |
| industry | string? | EXISTING | Sector, e.g. `"IT"`, `"Finance"` |
| incomeRange | object? | EXISTING | `{ minLabel, maxLabel, currency }` |
| workLocation | string? | **NEW** | City where user works |
| settledAbroad | string? | **NEW** | `"Yes"`, `"No"`, `"Planning to"` |
| willingToRelocate | string? | **NEW** | `"Yes"`, `"No"`, `"Maybe"` |
| aboutCareer | string? | **NEW** | Free-text about career |

### 2.4 Lifestyle

| Field | Type | Status | Description |
|-------|------|--------|-------------|
| diet | string? | EXISTING | `"Vegetarian"`, `"Non-vegetarian"`, `"Eggetarian"`, `"Vegan"`, `"Jain"` |
| drinking | string? | EXISTING | `"Non-drinker"`, `"Social"`, `"Regular"` |
| smoking | string? | EXISTING | `"Non-smoker"`, `"Occasional"`, `"Regular"` |
| exercise | string? | **NEW** | `"Daily"`, `"Often"`, `"Sometimes"`, `"Never"` |
| pets | string? | **NEW** | `"Dog"`, `"Cat"`, `"Both"`, `"Other"`, `"None"` |

### 2.5 Family details

Stored as `matrimonyExtensions.familyDetails`.

| Field | Type | Status | Description |
|-------|------|--------|-------------|
| familyType | string? | EXISTING | `"Joint"`, `"Nuclear"`, `"Other"` |
| familyValues | string? | EXISTING | `"Traditional"`, `"Moderate"`, `"Liberal"` |
| fatherOccupation | string? | EXISTING | |
| motherOccupation | string? | EXISTING | |
| siblingsCount | number? | EXISTING | Total siblings |
| siblingsMarried | number? | EXISTING | How many married |
| fatherAge | string? | **NEW** | Age or `"Deceased"` |
| motherAge | string? | **NEW** | Age or `"Deceased"` |
| brothers | string? | **NEW** | `"None"`, `"1"`, `"2"`, `"3"`, `"4+"` |
| sisters | string? | **NEW** | `"None"`, `"1"`, `"2"`, `"3"`, `"4+"` |
| familyLocation | string? | **NEW** | City/town where family lives |
| familyBasedOutOfCountry | string? | **NEW** | Country name, e.g. `"India"`, `"USA"` |
| householdIncome | string? | **NEW** | e.g. `"10-15 LPA"`, `"$100K-150K"` |

### 2.6 Horoscope

Stored as `matrimonyExtensions.horoscope`.

| Field | Type | Status | Description |
|-------|------|--------|-------------|
| dateOfBirth | string? | EXISTING | ISO date (same as top-level) |
| timeOfBirth | string? | EXISTING | e.g. `"06:42 AM"` |
| birthPlace | string? | EXISTING | e.g. `"Nairobi, Kenya"` |
| manglik | string? | EXISTING | `"Manglik"`, `"Non-Manglik"`, `"Anshik Manglik"` |
| nakshatra | string? | EXISTING | e.g. `"Rohini"`, `"Ashwini"` |
| horoscopeDocUrl | string? | EXISTING | URL to uploaded kundli document |
| rashi | string? | **NEW** | e.g. `"Vrishabh"`, `"Mesh"`, `"Kanya"` |
| gotra | string? | **NEW** | e.g. `"Bharadwaj"`, `"Kashyap"` |

---

## 3. `DatingExtensions`

Stored as `datingExtensions` on the profile. All fields optional.

| Field | Type | Status | Description |
|-------|------|--------|-------------|
| datingIntent | string? | EXISTING | `"serious"`, `"casual"`, `"marriage"`, `"friends first"` |
| prompts | object[]? | EXISTING | Array of `{ questionId, questionText, answer }` |
| voiceIntroUrl | string? | EXISTING | |
| travelModeEnabled | boolean | EXISTING | Default `false` |
| discoveryPreferences | object? | EXISTING | `{ ageMin, ageMax, maxDistanceKm, preferredCities, travelModeEnabled }` |

---

## 4. `PartnerPreferences`

Stored as `partnerPreferences` on the profile. Used for matching in both modes.

### Gender preference mapping

The `genderPreference` field is stored as a **normalized value** in the backend. The app displays mode-specific labels:

| Stored value | Matrimony label | Dating label |
|-------------|-----------------|--------------|
| `"Woman"` | Bride | Female |
| `"Man"` | Groom | Male |
| `"Any"` | _(not shown)_ | Other / Everyone |

When the user selects "Bride" in matrimony, the app sends `"Woman"`. When the user switches to dating mode, it displays "Female" for the same stored value.

### All fields

| Field | Type | Status | Description |
|-------|------|--------|-------------|
| genderPreference | string? | **NEW** | `"Woman"`, `"Man"`, `"Any"` — see mapping above |
| ageMin | number | EXISTING | Default `21` |
| ageMax | number | EXISTING | Default `45` |
| heightMinCm | number? | EXISTING | |
| heightMaxCm | number? | EXISTING | |
| preferredLocations | string[]? | EXISTING | City names |
| preferredReligions | string[]? | EXISTING | |
| preferredCommunities | string[]? | EXISTING | |
| educationPreference | string? | EXISTING | |
| occupationPreference | string? | EXISTING | |
| maritalStatusPreference | string[]? | EXISTING | |
| dietPreference | string? | EXISTING | |
| horoscopeMatchPreferred | boolean? | EXISTING | |
| preferredMotherTongues | string[]? | **NEW** | e.g. `["Hindi", "Gujarati"]` |
| preferredCountries | string[]? | **NEW** | e.g. `["India", "USA"]` |
| incomePreference | string? | **NEW** | e.g. `"5-10 LPA"` |
| drinkingPreference | string? | **NEW** | `"Non-drinker"`, `"Social"`, `"Doesn't matter"` |
| smokingPreference | string? | **NEW** | `"Non-smoker"`, `"Doesn't matter"` |
| settledAbroadPreference | string? | **NEW** | `"Yes"`, `"No"`, `"Doesn't matter"` |
| cityPreferenceMode | string? | **NEW** | `"any"`, `"same_as_me"`, `"preferred"` |
| distanceMaxKm | number? | **NEW** | Max distance for dating mode |
| strictFilters | object? | **NEW** | See below |

### Strict filters

Each preference can have a "strict" toggle — if strict, the match engine **must** satisfy it; if not strict, it's a soft preference.

Stored as `partnerPreferences.strictFilters`:

| Field | Type | Status | Description |
|-------|------|--------|-------------|
| religion | boolean | **NEW** | Default `false` |
| motherTongue | boolean | **NEW** | Default `false` |
| education | boolean | **NEW** | Default `false` |
| maritalStatus | boolean | **NEW** | Default `false` |
| income | boolean | **NEW** | Default `false` |
| diet | boolean | **NEW** | Default `false` |
| drinking | boolean | **NEW** | Default `false` |
| smoking | boolean | **NEW** | Default `false` |
| settledAbroad | boolean | **NEW** | Default `false` |

---

## 5. Profile completeness calculation

The backend should compute `profileCompleteness` (0.0–1.0) by checking how many of these fields are filled:

### Required for 100% (weighted)

| Category | Fields | Weight |
|----------|--------|--------|
| Basic | name, gender, dateOfBirth | 15% |
| Photos | photoUrls (≥1) | 15% |
| Location | currentCity | 5% |
| Bio | aboutMe | 10% |
| Interests | interests (≥1) | 5% |
| Religion | religion, casteOrCommunity | 5% |
| Education | educationDegree | 5% |
| Career | occupation | 5% |
| Physical | heightCm | 5% |
| Lifestyle | diet, drinking, smoking | 5% |
| Family | familyType, fatherOccupation, motherOccupation | 5% |
| Horoscope | manglik, nakshatra | 5% |
| Partner prefs | genderPreference, ageMin, ageMax | 5% |
| Mother tongue | motherTongue | 5% |
| Prompts | aboutMe or datingExtensions.prompts (≥1) | 5% |

---

## 6. `VerificationStatus`

| Field | Type | Status | Description |
|-------|------|--------|-------------|
| photoVerified | boolean | EXISTING | Default `false` |
| idVerified | boolean | EXISTING | Default `false` |
| emailVerified | boolean | EXISTING | Default `false` |
| phoneVerified | boolean | EXISTING | Default `false` |
| linkedInVerified | boolean | EXISTING | Default `false` |
| educationVerified | boolean | EXISTING | Default `false` |
| score | number | EXISTING | 0.0–1.0 |

---

## 7. API endpoints for profile

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/profile/me` | Get my full profile |
| PATCH | `/profile/me` | Partial update (merge fields) |
| PUT | `/profile/me` | Full replace |
| GET | `/profile/me/preferences` | Get partner preferences |
| PUT | `/profile/me/preferences` | Replace partner preferences |
| GET | `/profile/:userId` | Get another user's profile |
| GET | `/profile/:userId/summary` | Get lightweight summary |

### PATCH behavior

- Only fields present in the request body are updated
- Nested objects (`matrimonyExtensions`, `familyDetails`, `horoscope`, `partnerPreferences`) are **deep-merged**, not replaced
- Sending `null` for a field clears it
- `profileCompleteness` is recomputed after every update

### Example PATCH — saving step 1 (identity)

```json
{
  "name": "Vikram Shah",
  "gender": "Man",
  "dateOfBirth": "1996-01-01",
  "aboutMe": "Software engineer who loves hiking.",
  "currentCity": "Mumbai",
  "currentCountry": "India",
  "originCity": "Ahmedabad",
  "originCountry": "India",
  "motherTongue": "Gujarati",
  "matrimonyExtensions": {
    "maritalStatus": "Never married",
    "heightCm": 175,
    "bodyType": "Athletic",
    "complexion": "Wheatish"
  },
  "partnerPreferences": {
    "genderPreference": "Woman"
  }
}
```

### Example PATCH — saving step 5 (details: family + horoscope + lifestyle)

```json
{
  "matrimonyExtensions": {
    "diet": "Vegetarian",
    "drinking": "Non-drinker",
    "smoking": "Non-smoker",
    "exercise": "Daily",
    "familyDetails": {
      "familyType": "Joint",
      "familyValues": "Traditional",
      "fatherOccupation": "Business",
      "motherOccupation": "Homemaker",
      "fatherAge": "65",
      "motherAge": "60",
      "brothers": "1",
      "sisters": "2",
      "siblingsCount": 3,
      "familyLocation": "Ahmedabad",
      "familyBasedOutOfCountry": "India",
      "householdIncome": "15-20 LPA"
    },
    "horoscope": {
      "manglik": "Non-Manglik",
      "rashi": "Vrishabh",
      "nakshatra": "Rohini",
      "gotra": "Bharadwaj",
      "timeOfBirth": "06:42 AM",
      "birthPlace": "Ahmedabad, India",
      "dateOfBirth": "1996-01-01"
    }
  }
}
```

### Example PATCH — saving step 6 (partner preferences)

```json
{
  "partnerPreferences": {
    "genderPreference": "Woman",
    "ageMin": 23,
    "ageMax": 30,
    "preferredReligions": ["Hindu"],
    "preferredMotherTongues": ["Gujarati", "Hindi"],
    "educationPreference": "Post-graduate",
    "maritalStatusPreference": ["Never married"],
    "dietPreference": "Vegetarian",
    "drinkingPreference": "Non-drinker",
    "smokingPreference": "Non-smoker",
    "settledAbroadPreference": "Doesn't matter",
    "preferredLocations": ["Mumbai", "Ahmedabad"],
    "preferredCountries": ["India"],
    "cityPreferenceMode": "preferred",
    "strictFilters": {
      "religion": true,
      "diet": true,
      "motherTongue": false,
      "education": false,
      "maritalStatus": true,
      "income": false,
      "drinking": false,
      "smoking": false,
      "settledAbroad": false
    }
  }
}
```

---

## 8. Summary of NEW fields to add

### MatrimonyExtensions (8 new fields)

```
bodyType         string?
complexion       string?
disability       string?
workLocation     string?
settledAbroad    string?
willingToRelocate string?
exercise         string?
pets             string?
```

### MatrimonyExtensions.educationEntries (2 new fields)

```
educationEntries  object[]?   (array of { degree, institution, graduationYear, scoreCountry, scoreType })
aboutEducation    string?
```

### MatrimonyExtensions.career (1 new field)

```
aboutCareer       string?
```

### MatrimonyExtensions.familyDetails (7 new fields)

```
fatherAge              string?
motherAge              string?
brothers               string?
sisters                string?
familyLocation         string?
familyBasedOutOfCountry string?
householdIncome        string?
```

### MatrimonyExtensions.horoscope (2 new fields)

```
rashi    string?
gotra    string?
```

### PartnerPreferences (10 new fields)

```
genderPreference         string?
preferredMotherTongues   string[]?
preferredCountries       string[]?
incomePreference         string?
drinkingPreference       string?
smokingPreference        string?
settledAbroadPreference  string?
cityPreferenceMode       string?
distanceMaxKm            number?
strictFilters            object?   (9 boolean flags)
```

**Total: 30 new fields + 1 new nested object (strictFilters with 9 booleans)**
