# Saathi — Matching & Compatibility Scoring Engine

Backend specification for the ML-powered matching pipeline. This system powers
`GET /discovery/recommended`, compatibility badges on profile cards, and
"Why you matched" explanations.

---

## Table of contents

1. [Architecture overview](#1-architecture-overview)
2. [Matching pipeline stages](#2-matching-pipeline-stages)
3. [Stage 1 — Hard filter (candidate generation)](#3-stage-1--hard-filter-candidate-generation)
4. [Stage 2 — Feature extraction](#4-stage-2--feature-extraction)
5. [Stage 3 — Compatibility scoring model](#5-stage-3--compatibility-scoring-model)
6. [Stage 4 — Ranking & diversity](#6-stage-4--ranking--diversity)
7. [Stage 5 — Explainability (match reasons)](#7-stage-5--explainability-match-reasons)
8. [API endpoints](#8-api-endpoints)
9. [DTOs](#9-dtos)
10. [Behavioral signals & feedback loop](#10-behavioral-signals--feedback-loop)
11. [ML model training](#11-ml-model-training)
12. [Cold start strategy](#12-cold-start-strategy)
13. [Caching & performance](#13-caching--performance)
14. [Database requirements](#14-database-requirements)

---

## 1. Architecture overview

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Hard Filter │ ──▶ │   Feature    │ ──▶ │ Compatibility│ ──▶ │  Ranking &   │
│  (SQL/Mongo) │     │  Extraction  │     │   Scoring    │     │  Diversity   │
│              │     │              │     │   (ML Model) │     │  Re-ranking  │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
      ▲                                        ▲                      │
      │                                        │                      ▼
 User prefs &                           Training data          Final ordered
 strict filters                         (interactions)         profile list
```

**Two modes:** The engine runs identically for `dating` and `matrimony` but uses
different feature weights and filter sets per mode.

---

## 2. Matching pipeline stages

| Stage | Purpose | Latency target |
|-------|---------|----------------|
| 1. Hard filter | Eliminate clearly incompatible candidates | < 50ms |
| 2. Feature extraction | Build feature vectors for each pair | < 20ms/pair |
| 3. Compatibility scoring | ML model predicts match probability | < 10ms/pair |
| 4. Ranking & diversity | Re-rank top-N with diversity constraints | < 5ms |
| 5. Explainability | Generate human-readable match reasons | < 2ms/match |

Total budget: **< 200ms** for 20 results (after candidate set is reduced by
hard filters to ~500 candidates).

---

## 3. Stage 1 — Hard filter (candidate generation)

These are non-negotiable filters applied at the database query level. A
candidate is **excluded** if any hard filter fails.

### 3.1 Universal hard filters (both modes)

| Filter | Logic |
|--------|-------|
| Gender match | Candidate's gender matches user's `genderPreference` ("Man", "Woman", "Any") |
| Self-exclusion | `candidate.id ≠ user.id` |
| Already acted on | Exclude profiles user already liked/passed/blocked |
| Age range | `candidate.age ∈ [user.prefs.ageMin, user.prefs.ageMax]` |
| Account status | Candidate must be active (not deleted, suspended, or incomplete) |
| Profile completeness | `candidate.profileCompleteness ≥ 0.30` (at least 30%) |

### 3.2 Strict-filter enforcement

When `partnerPreferences.strictFilters.<field>` is `true`, that preference
becomes a hard filter:

| Strict filter key | Applied as |
|-------------------|------------|
| `religion` | `candidate.religion ∈ user.prefs.preferredReligions` |
| `motherTongue` | `candidate.motherTongue ∈ user.prefs.preferredMotherTongues` |
| `education` | `candidate.educationDegree` matches `user.prefs.educationPreference` |
| `maritalStatus` | `candidate.maritalStatus ∈ user.prefs.maritalStatusPreference` |
| `income` | Candidate income range overlaps with `user.prefs.incomePreference` |
| `diet` | `candidate.diet == user.prefs.dietPreference` |
| `drinking` | `candidate.drinking == user.prefs.drinkingPreference` |
| `smoking` | `candidate.smoking == user.prefs.smokingPreference` |
| `settledAbroad` | `candidate.settledAbroad == user.prefs.settledAbroadPreference` |

### 3.3 Dating-mode additional filters

| Filter | Logic |
|--------|-------|
| Distance | If `user.prefs.distanceMaxKm` is set, `haversine(user.location, candidate.location) ≤ distanceMaxKm` |
| City preference | If `cityPreferenceMode == "same_as_me"`, candidate city must match |

### 3.4 Matrimony-mode additional filters

| Filter | Logic |
|--------|-------|
| Height range | If set: `candidate.heightCm ∈ [user.prefs.heightMinCm, user.prefs.heightMaxCm]` |
| Location preference | If `user.prefs.preferredLocations` non-empty, candidate city must be in list |
| Country preference | If `user.prefs.preferredCountries` non-empty, candidate country must be in list |

---

## 4. Stage 2 — Feature extraction

For each (user, candidate) pair that passes hard filters, extract a feature
vector. Features are grouped into categories.

### 4.1 Demographic features

| Feature | Type | Computation |
|---------|------|-------------|
| `age_diff` | float | `abs(user.age - candidate.age)` |
| `age_diff_norm` | float | `age_diff / (prefs.ageMax - prefs.ageMin)` — 0 = same age, 1 = edge of range |
| `height_diff` | float | `abs(user.heightCm - candidate.heightCm)` or 0 if unknown |
| `same_city` | bool→float | 1.0 if `user.currentCity == candidate.currentCity` |
| `same_country` | bool→float | 1.0 if same country |
| `same_origin` | bool→float | 1.0 if `user.originCity == candidate.originCity` |
| `distance_km` | float | Haversine distance (0 if unknown, capped at 10000) |
| `distance_score` | float | `max(0, 1 - distance_km / prefs.distanceMaxKm)` |

### 4.2 Cultural & religion features

| Feature | Type | Computation |
|---------|------|-------------|
| `same_religion` | float | 1.0 if match, 0.5 if candidate religion in preferred list, 0.0 otherwise |
| `same_community` | float | 1.0 if exact match |
| `same_mother_tongue` | float | 1.0 if match, 0.5 if in preferred list |
| `shared_languages` | float | `len(intersection) / len(union)` of `languagesSpoken` |
| `horoscope_compatible` | float | 1.0 if astrological compatibility passes (rashi/nakshatra rules), 0.5 unknown, 0.0 incompatible |
| `same_gotra` | float | 0.0 if same gotra (some traditions avoid), 1.0 if different or unknown |
| `manglik_match` | float | 1.0 if both manglik or both non-manglik, 0.5 if one unknown, 0.0 if mismatch |

### 4.3 Education & career features

| Feature | Type | Computation |
|---------|------|-------------|
| `education_tier` | float | Map degree to tier (PhD=5, Masters=4, Bachelors=3, Diploma=2, Other=1), normalize to [0,1] |
| `education_tier_diff` | float | `abs(user_tier - candidate_tier) / 4` |
| `education_match` | float | 1.0 if candidate degree matches preference |
| `same_industry` | float | 1.0 if same industry |
| `income_match` | float | 1.0 if candidate income overlaps preferred range, 0.5 if close, 0.0 if far |
| `both_settled_abroad` | float | 1.0 if both settled abroad or both not |

### 4.4 Lifestyle compatibility features

| Feature | Type | Computation |
|---------|------|-------------|
| `diet_match` | float | 1.0 if same, 0.7 if compatible (e.g. veg + eggetarian), 0.3 if not |
| `drinking_match` | float | 1.0 if same, 0.5 if compatible, 0.0 if mismatch |
| `smoking_match` | float | 1.0 if same, 0.5 if compatible, 0.0 if mismatch |
| `exercise_match` | float | 1.0 if same, 0.5 if one step apart |
| `shared_interests` | float | Jaccard similarity of `interests` arrays |
| `interest_count` | float | `len(intersection(interests))` normalized |

### 4.5 Family features (matrimony only)

| Feature | Type | Computation |
|---------|------|-------------|
| `family_type_match` | float | 1.0 if same familyType |
| `family_values_match` | float | 1.0 if same familyValues, 0.5 if one step apart |
| `family_location_match` | float | 1.0 if same city/country |

### 4.6 Profile quality features

| Feature | Type | Computation |
|---------|------|-------------|
| `profile_completeness` | float | `candidate.profileCompleteness` (0.0–1.0) |
| `photo_count_norm` | float | `min(candidate.photoCount, 6) / 6` |
| `has_bio` | float | 1.0 if `aboutMe` is non-empty and > 50 chars |
| `is_verified` | float | 1.0 if verified |
| `verification_score` | float | `candidate.verificationStatus.score` |
| `days_since_active` | float | `1 / (1 + days_since_lastActive)` — decay function |

### 4.7 Behavioral features (from interaction history)

| Feature | Type | Computation |
|---------|------|-------------|
| `user_response_rate` | float | Fraction of received interests user accepts |
| `candidate_response_rate` | float | Same for candidate |
| `mutual_interest_likelihood` | float | P(candidate likes user back) from model |
| `user_avg_session_time` | float | Engagement proxy |
| `similar_to_accepted` | float | Cosine similarity between candidate embedding and centroid of user's accepted profiles |
| `dissimilar_to_rejected` | float | 1 - cosine similarity with centroid of rejected profiles |

---

## 5. Stage 3 — Compatibility scoring model

### 5.1 Model architecture

**Phase 1 (rule-based, launch):** Weighted linear combination of features.

```
score = Σ (weight_i × feature_i)
```

Default weights per mode (tunable via config):

| Feature group | Dating weight | Matrimony weight |
|---------------|--------------|-----------------|
| Demographic (age, location) | 0.25 | 0.15 |
| Cultural/Religion | 0.05 | 0.25 |
| Education/Career | 0.05 | 0.15 |
| Lifestyle | 0.20 | 0.10 |
| Interests overlap | 0.20 | 0.05 |
| Profile quality | 0.10 | 0.10 |
| Family (matrimony only) | 0.00 | 0.10 |
| Behavioral signals | 0.15 | 0.10 |

**Phase 2 (ML, post-launch):** Gradient-boosted decision tree (XGBoost/LightGBM)
trained on interaction outcomes.

**Phase 3 (advanced):** Two-tower neural network.
- Tower A: User embedding (128-dim)
- Tower B: Candidate embedding (128-dim)
- Score = dot product + MLP head
- Trained end-to-end on (like, pass, match, message) signals

### 5.2 Score output

```
compatibilityScore: float [0.0 – 1.0]
```

| Range | Label | UI display |
|-------|-------|------------|
| 0.85–1.00 | Excellent match | ★★★★★ or "Highly compatible" |
| 0.70–0.84 | Great match | ★★★★ or "Great match" |
| 0.55–0.69 | Good match | ★★★ or "Good match" |
| 0.40–0.54 | Fair match | ★★ |
| 0.00–0.39 | Low match | ★ (still shown if passes hard filters) |

### 5.3 Preference match breakdown

In addition to the overall score, compute per-category scores:

```json
{
  "compatibilityScore": 0.82,
  "breakdown": {
    "basics": 0.90,
    "culture": 0.85,
    "lifestyle": 0.75,
    "career": 0.80,
    "interests": 0.70,
    "family": 0.95,
    "location": 0.85
  }
}
```

---

## 6. Stage 4 — Ranking & diversity

After scoring, apply re-ranking to ensure a diverse, engaging feed.

### 6.1 Diversity constraints

| Constraint | Rule |
|------------|------|
| Religion diversity | No more than 60% of results from same religion (unless strict filter) |
| City diversity | No more than 50% from same city |
| Photo freshness | Profiles with recent photos ranked slightly higher (+0.02) |
| New users boost | Profiles < 7 days old get +0.05 boost |
| Inactive penalty | Profiles inactive > 30 days get −0.10 penalty |
| Already-seen decay | Profiles shown before but not acted on get −0.03 per view |
| Mutual likelihood | Boost by `0.1 × P(candidate likes user)` |
| Verified boost | Verified profiles get +0.03 |

### 6.2 Final ranking formula

```
final_score = compatibility_score
            + new_user_boost
            + verified_boost
            + mutual_likelihood_boost
            - inactive_penalty
            - already_seen_decay
```

Sort descending by `final_score`. Return top `limit` results.

### 6.3 Anti-pattern safeguards

- **No repeated profiles**: Track shown profile IDs per user session in Redis
- **Rate-limit passes**: If user passes >50 profiles in 5 min, show cooldown
- **Ghosting detection**: If user matches but never messages, slightly reduce their visibility to others

---

## 7. Stage 5 — Explainability (match reasons)

Generate 1–3 human-readable reasons for each match.

### 7.1 Reason generation rules

Pick the top 3 contributing features by weight × value:

| Condition | Reason text |
|-----------|-------------|
| `same_religion && religion_weight > 0.1` | "Same religion — {religion}" |
| `same_community` | "Same community — {community}" |
| `same_mother_tongue` | "Speaks {motherTongue}" |
| `shared_languages > 0` | "You both speak {languages}" |
| `same_city` | "Lives in {city}" |
| `same_origin` | "From {originCity}" |
| `distance_km < 10` | "Lives nearby — {distance}km away" |
| `shared_interests ≥ 0.4` | "Shares {N} interests with you" |
| `education_match` | "Similar education background" |
| `same_industry` | "Works in {industry}" |
| `diet_match == 1.0` | "Same dietary preference" |
| `family_values_match == 1.0` | "Similar family values" |
| `horoscope_compatible == 1.0` | "Horoscope compatible" |
| `profile_completeness > 0.8` | "Detailed profile" |
| `is_verified` | "Verified profile" |

The `matchReasons` array is included in the API response and displayed on
profile cards.

---

## 8. API endpoints

### 8.1 Get recommended profiles (enhanced)

This **replaces** the current `GET /discovery/recommended` with scoring.

```http
GET /discovery/recommended?mode=matrimony&limit=20&cursor=usr_xyz
Authorization: Bearer <accessToken>
```

| Query | Type | Required | Description |
|-------|------|----------|-------------|
| mode | string | Yes | `"dating"` or `"matrimony"` |
| limit | number | No | Default 20, max 50 |
| cursor | string | No | Pagination cursor (last profile ID) |

**Success** `200 OK`

```json
{
  "profiles": [
    {
      "id": "usr_abc",
      "name": "Priya S.",
      "age": 27,
      "city": "Mumbai",
      "imageUrl": "https://cdn.saathi.app/photos/usr_abc/photo_1.jpg",
      "distanceKm": 4.2,
      "verified": true,
      "bio": "Product designer who loves hiking and chai.",
      "interests": ["Hiking", "Design", "Cooking"],
      "motherTongue": "Gujarati",
      "occupation": "Product Designer",
      "heightCm": 163,
      "religion": "Hindu",
      "community": "Patel",
      "educationDegree": "B.Des",
      "maritalStatus": "Never married",
      "diet": "Vegetarian",
      "photoCount": 4,
      "compatibilityScore": 0.87,
      "compatibilityLabel": "Excellent match",
      "matchReasons": [
        "Lives in Mumbai",
        "Same religion — Hindu",
        "Shares 3 interests with you"
      ],
      "breakdown": {
        "basics": 0.92,
        "culture": 0.88,
        "lifestyle": 0.80,
        "career": 0.85,
        "interests": 0.78,
        "location": 0.95
      }
    }
  ],
  "nextCursor": "usr_def456"
}
```

### 8.2 Get compatibility with specific profile

```http
GET /discovery/compatibility/:candidateId
Authorization: Bearer <accessToken>
```

Returns the full compatibility breakdown between the requesting user and a
specific candidate. Used when viewing a full profile.

**Success** `200 OK`

```json
{
  "candidateId": "usr_abc",
  "compatibilityScore": 0.87,
  "compatibilityLabel": "Excellent match",
  "matchReasons": [
    "Lives in Mumbai",
    "Same religion — Hindu",
    "Shares 3 interests with you"
  ],
  "breakdown": {
    "basics": 0.92,
    "culture": 0.88,
    "lifestyle": 0.80,
    "career": 0.85,
    "interests": 0.78,
    "family": 0.90,
    "location": 0.95
  },
  "preferenceAlignment": {
    "age": "within_range",
    "religion": "match",
    "motherTongue": "match",
    "education": "match",
    "maritalStatus": "match",
    "diet": "match",
    "height": "within_range",
    "location": "same_city",
    "income": "close",
    "drinking": "match",
    "smoking": "match"
  }
}
```

`preferenceAlignment` values: `"match"`, `"close"`, `"within_range"`,
`"no_preference"`, `"mismatch"`.

### 8.3 Report match feedback

```http
POST /discovery/feedback
Authorization: Bearer <accessToken>
Content-Type: application/json
```

Records user interaction for model training.

```json
{
  "candidateId": "usr_abc",
  "action": "like",
  "timeSpentMs": 4200,
  "source": "recommended"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| candidateId | string | Yes | Candidate profile ID |
| action | string | Yes | `"like"`, `"pass"`, `"superlike"`, `"block"`, `"report"` |
| timeSpentMs | number | No | Time user spent viewing profile |
| source | string | No | `"recommended"`, `"search"`, `"nearby"` |

**Success** `200 OK`

```json
{ "recorded": true }
```

### 8.4 Get match preferences tuning (for UI)

```http
GET /discovery/preferences
Authorization: Bearer <accessToken>
```

Returns the user's current matching preferences along with suggested
adjustments based on their interaction history.

**Success** `200 OK`

```json
{
  "current": {
    "ageMin": 25,
    "ageMax": 32,
    "preferredReligions": ["Hindu"],
    "strictFilters": { "religion": true }
  },
  "suggestions": [
    {
      "field": "ageMax",
      "suggestedValue": 35,
      "reason": "Expanding age range by 3 years would show 40% more compatible profiles"
    },
    {
      "field": "strictFilters.religion",
      "suggestedValue": false,
      "reason": "3 highly compatible profiles from other backgrounds were filtered out"
    }
  ]
}
```

---

## 9. DTOs

### 9.1 ProfileSummary (enhanced)

Add these fields to the existing `ProfileSummary` DTO:

| Field | Type | Description |
|-------|------|-------------|
| **sharedInterests** | **string[]** | **Subset of `interests` that the candidate shares with the current viewer. Required in discovery responses so the app can highlight them (e.g. green chip with heart). Compute by intersecting viewer's interests with candidate's interests (case-insensitive).** |
| compatibilityScore | number? | 0.0–1.0 overall match score |
| compatibilityLabel | string? | `"Excellent match"`, `"Great match"`, `"Good match"` |
| matchReasons | string[]? | 1–3 human-readable reasons |
| breakdown | object? | Per-category scores (basics, culture, lifestyle, etc.) |

### 9.2 CompatibilityDetail

Full compatibility response for `GET /discovery/compatibility/:id`:

| Field | Type | Description |
|-------|------|-------------|
| candidateId | string | |
| compatibilityScore | number | 0.0–1.0 |
| compatibilityLabel | string | |
| matchReasons | string[] | |
| breakdown | object | `{ basics, culture, lifestyle, career, interests, family, location }` |
| preferenceAlignment | object | Per-field alignment status |

### 9.3 MatchFeedback

| Field | Type | Description |
|-------|------|-------------|
| candidateId | string | |
| action | string | `"like"`, `"pass"`, `"superlike"`, `"block"`, `"report"` |
| timeSpentMs | number? | |
| source | string? | Where the profile was shown |

---

## 10. Behavioral signals & feedback loop

The matching model improves over time by learning from user interactions.

### 10.1 Positive signals (label = 1)

| Signal | Weight | Source |
|--------|--------|--------|
| Like / Express Interest | 1.0 | `POST /interests` or feedback |
| Super Like | 1.5 | feedback |
| Mutual match (both liked) | 2.0 | Backend detects mutual interest |
| Sent first message | 2.5 | Chat service |
| Conversation > 5 messages | 3.0 | Chat service |
| Exchanged contact info | 4.0 | Chat service (detect phone/email patterns) |
| Profile view > 15 seconds | 0.5 | feedback.timeSpentMs |

### 10.2 Negative signals (label = 0)

| Signal | Weight | Source |
|--------|--------|--------|
| Pass/Skip | −1.0 | feedback |
| Block | −3.0 | feedback |
| Report | −5.0 | feedback |
| Profile view < 2 seconds | −0.3 | feedback.timeSpentMs |
| Match but no message in 7 days | −1.5 | Background job |
| Unmatched after messaging | −2.0 | Chat service |

### 10.3 Feedback storage

Store in an `interactions` table:

```sql
CREATE TABLE interactions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     TEXT NOT NULL REFERENCES users(id),
  candidate_id TEXT NOT NULL REFERENCES users(id),
  action      TEXT NOT NULL,       -- 'like', 'pass', 'superlike', 'block', 'report', 'view'
  time_spent_ms INTEGER,
  source      TEXT,                -- 'recommended', 'search', 'nearby'
  mode        TEXT NOT NULL,       -- 'dating', 'matrimony'
  compatibility_score REAL,        -- score at time of interaction
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user_id, candidate_id, action)
);

CREATE INDEX idx_interactions_user ON interactions(user_id, created_at DESC);
CREATE INDEX idx_interactions_candidate ON interactions(candidate_id, created_at DESC);
CREATE INDEX idx_interactions_training ON interactions(action, created_at DESC);
```

---

## 11. ML model training

### 11.1 Training data format

Each training sample is a (user, candidate, label) triple with the feature
vector from Stage 2.

```json
{
  "user_id": "usr_abc",
  "candidate_id": "usr_def",
  "features": [0.12, 0.85, 1.0, 0.0, ...],
  "label": 1,
  "weight": 2.5,
  "mode": "matrimony",
  "timestamp": "2026-02-20T14:30:00Z"
}
```

### 11.2 Training schedule

| Phase | Trigger | Model |
|-------|---------|-------|
| Cold start | Launch | Rule-based weights (§5.1 Phase 1) |
| First retrain | 10,000 interactions | LightGBM on interaction data |
| Periodic | Weekly (Sunday 3 AM UTC) | Retrain on last 90 days of data |
| Online update | Every 1,000 new interactions | Incremental update of feature weights |

### 11.3 Model serving

- Export trained model as ONNX or pickle
- Serve via a lightweight Python microservice (FastAPI) or embed in Node.js
  via ONNX Runtime
- Endpoint: `POST /internal/ml/score` (internal, not exposed to clients)

```json
// Request
{
  "user_features": [...],
  "candidate_features": [...],
  "mode": "matrimony"
}

// Response
{
  "score": 0.87,
  "feature_importances": {
    "same_religion": 0.22,
    "shared_interests": 0.18,
    "distance_score": 0.15,
    ...
  }
}
```

### 11.4 Evaluation metrics

| Metric | Target | Description |
|--------|--------|-------------|
| AUC-ROC | > 0.75 | Discrimination between like/pass |
| Precision@20 | > 0.30 | At least 6/20 recommended profiles get liked |
| Mutual match rate | > 5% | Of all likes, 5%+ become mutual |
| NDCG@20 | > 0.60 | Ranking quality of recommendations |
| Diversity score | > 0.40 | Shannon entropy of recommended religion/city |

---

## 12. Cold start strategy

### 12.1 New users (no interaction history)

| Strategy | Description |
|----------|-------------|
| Preference-based scoring | Use only explicit partner preferences (age, religion, location) |
| Popular profiles | Mix in profiles with high acceptance rates |
| Demographic matching | Match on city + religion + age range |
| Exploration boost | Show more diverse profiles to learn preferences quickly |
| Onboarding quiz | Optional "swipe these 5 profiles" to bootstrap preferences |

### 12.2 New candidates (few viewers)

| Strategy | Description |
|----------|-------------|
| New user boost | +0.05 to final score for first 7 days |
| Guaranteed impressions | Every new profile shown to at least 50 users in first 48 hours |
| Profile quality bonus | Complete profiles (>70%) get extra visibility |

---

## 13. Caching & performance

### 13.1 Caching strategy

| Data | Cache | TTL | Invalidation |
|------|-------|-----|-------------|
| User feature vector | Redis | 1 hour | On profile update |
| Candidate pool (post hard-filter) | Redis | 15 min | On pref change |
| Compatibility scores | Redis sorted set | 30 min | On feature vector change |
| Shown profile IDs (per session) | Redis set | 24 hours | On session end |
| ML model | In-memory | Until next deploy | On model retrain |

### 13.2 Pre-computation

Run a nightly job to pre-compute compatibility scores for the top 200
candidates per user. Store in a `precomputed_matches` table:

```sql
CREATE TABLE precomputed_matches (
  user_id           TEXT NOT NULL,
  candidate_id      TEXT NOT NULL,
  compatibility_score REAL NOT NULL,
  match_reasons     JSONB,
  breakdown         JSONB,
  mode              TEXT NOT NULL,
  computed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, candidate_id, mode)
);

CREATE INDEX idx_precomputed_user_score
  ON precomputed_matches(user_id, mode, compatibility_score DESC);
```

### 13.3 Real-time vs batch

| Scenario | Strategy |
|----------|----------|
| First page load | Serve from pre-computed cache |
| Scrolling past pre-computed | Compute on-the-fly (hard filter → score → rank) |
| Profile update | Invalidate user's cache, recompute async |
| Preference change | Recompute candidate pool + top 200 async |

---

## 14. Database requirements

### 14.1 New tables

```sql
-- Interaction history for ML training
CREATE TABLE interactions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          TEXT NOT NULL,
  candidate_id     TEXT NOT NULL,
  action           TEXT NOT NULL,
  time_spent_ms    INTEGER,
  source           TEXT,
  mode             TEXT NOT NULL,
  compatibility_score REAL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, candidate_id, action)
);

-- Pre-computed match scores
CREATE TABLE precomputed_matches (
  user_id             TEXT NOT NULL,
  candidate_id        TEXT NOT NULL,
  compatibility_score REAL NOT NULL,
  compatibility_label TEXT,
  match_reasons       JSONB,
  breakdown           JSONB,
  mode                TEXT NOT NULL,
  computed_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, candidate_id, mode)
);

-- Shown profiles tracker (or use Redis)
CREATE TABLE shown_profiles (
  user_id       TEXT NOT NULL,
  candidate_id  TEXT NOT NULL,
  shown_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  times_shown   INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (user_id, candidate_id)
);

-- Model metadata
CREATE TABLE ml_models (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mode        TEXT NOT NULL,
  version     TEXT NOT NULL,
  metrics     JSONB,
  model_path  TEXT NOT NULL,
  trained_at  TIMESTAMPTZ NOT NULL,
  active      BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 14.2 Indexes needed on existing tables

```sql
-- Fast candidate lookup by gender, age, city
CREATE INDEX idx_profiles_discovery
  ON profiles(gender, date_of_birth, current_city)
  WHERE profile_completeness >= 0.30 AND status = 'active';

-- Religion + community for matrimony
CREATE INDEX idx_profiles_religion
  ON profiles(religion, caste_or_community);

-- Geo queries for dating nearby
CREATE INDEX idx_profiles_location
  ON profiles USING gist (
    ST_SetSRID(ST_MakePoint(creation_lng, creation_lat), 4326)
  );
```

---

## Quick reference — Endpoint summary

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /discovery/recommended | Yes | ML-scored recommended profiles |
| GET | /discovery/compatibility/:candidateId | Yes | Full compatibility breakdown |
| POST | /discovery/feedback | Yes | Record interaction for ML training |
| GET | /discovery/preferences | Yes | Current preferences + suggestions |
| GET | /discovery/search | Yes | Filtered search (existing) |
| GET | /discovery/nearby | Yes | Geo-based discovery (existing) |

---

## Implementation priority

| Priority | Item | Effort |
|----------|------|--------|
| P0 | Hard filters + rule-based scoring (Phase 1) | 3–5 days |
| P0 | `interactions` table + feedback endpoint | 1 day |
| P0 | Match reasons generation | 1 day |
| P1 | Pre-computed matches nightly job | 2 days |
| P1 | Compatibility detail endpoint | 1 day |
| P1 | Redis caching layer | 1–2 days |
| P2 | LightGBM model training pipeline | 3–5 days |
| P2 | Preference suggestions | 2 days |
| P3 | Two-tower neural network | 1–2 weeks |
| P3 | A/B testing framework | 1 week |
