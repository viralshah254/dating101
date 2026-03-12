# Backend Phase 1: Trust, Explainability, Openers

## Goal

Define the backend contract needed for Phase 1 UX:

- Trust badge v1 on discovery cards
- Explainable "Why this match" reasons
- Suggested first-message openers when mutual match happens

This doc is additive to `docs/BACKEND_REQUIREMENTS_ALIGNMENT.md`.

## 1) Discovery feed payload additions

Applies to:

- `GET /discovery/recommended`
- `GET /discovery/explore`
- `GET /discovery/nearby`
- `GET /matrimony/daily-matches`

### Query params (existing)

- `mode`: `dating` | `matrimony`
- `limit`: int
- `cursor`: string (optional)
- Other filter params as already documented

### Response (profile item) additions

Each profile item in `profiles[]` should include:

- `trustScore`: number in range `0..1` (optional for backwards compatibility)
- `trustSignals`: object (optional)
  - `phoneVerified`: boolean
  - `idVerified`: boolean
  - `photoVerified`: boolean
  - `hasBio`: boolean
  - `hasPrompt`: boolean
  - `photoCount`: int
  - `profileCompleteness`: number `0..1`
- `matchReasons`: string[] (already partially supported; now canonical)
  - 1 to 5 short reasons, user-facing copy

If `trustScore` is absent, frontend falls back to local heuristic.

### Example

```json
{
  "profiles": [
    {
      "id": "usr_123",
      "name": "Priya",
      "age": 28,
      "city": "London",
      "compatibilityScore": 0.84,
      "matchReasons": [
        "Same city",
        "Shared interests: Travel, Design",
        "Within your preferred age range"
      ],
      "trustScore": 0.81,
      "trustSignals": {
        "phoneVerified": true,
        "idVerified": true,
        "photoVerified": true,
        "hasBio": true,
        "hasPrompt": true,
        "photoCount": 5,
        "profileCompleteness": 0.92
      }
    }
  ],
  "nextCursor": "abc_2"
}
```

## 2) Compatibility detail endpoint (reinforce canonical shape)

Endpoint:

- `GET /discovery/compatibility/:candidateId`

### Response fields

- `candidateId`: string
- `compatibilityScore`: number `0..1`
- `compatibilityLabel`: string
- `matchReasons`: string[]
- `breakdown`: object of numeric dimensions
- `preferenceAlignment`: object (dimension -> enum/string)

Notes:

- `matchReasons` should be short and directly displayable as chips.
- Do not return empty strings in reasons.

## 3) Opener suggestions endpoint (new, recommended)

When a user gets a mutual match, frontend can request personalized opener suggestions.

Endpoint:

- `GET /interactions/openers`

### Query params

- `toUserId` (required): string
- `mode` (optional): `dating` | `matrimony`
- `context` (optional): default `mutual_match`

### Response

- `suggestions`: string[] (0..5 entries)

### Example

```json
{
  "suggestions": [
    "Hi Priya, great to match with you!",
    "I noticed we both like travel. What's your favorite trip so far?",
    "What does your ideal weekend look like?"
  ]
}
```

### Error behavior

- `404 NOT_FOUND` if `toUserId` unknown
- `403 BLOCKED` if messaging not allowed due to safety state
- `200` with empty `suggestions: []` is valid; frontend falls back to local templates

## 4) Optional telemetry endpoint for selected opener

If tracking selection quality is needed:

- `POST /interactions/openers/selection`

Body:

- `toUserId`: string
- `mode`: `dating` | `matrimony` (optional)
- `selectedText`: string
- `source`: string (example: `discovery_mutual_match_sheet`)

Response:

- `204 No Content` or `200 { "ok": true }`

## 5) Content constraints for reasons/openers

- Max length per reason: 60 chars
- Max length per opener: 160 chars
- No markdown or HTML
- Avoid unsafe wording and policy-sensitive claims
- Locale-aware generation if `Accept-Language` is provided

## 6) Backward compatibility and rollout

- Keep all new fields optional during rollout.
- Frontend already supports fallback behavior when fields are missing.
- Recommended rollout:
  1. Ship `matchReasons` quality improvements
  2. Add `trustScore` + `trustSignals`
  3. Launch `/interactions/openers`
  4. Add opener selection telemetry

## 7) Backend implementation handoff (copy/paste)

Use this exact brief for backend coding:

1. Update discovery feed serializers (`/discovery/recommended`, `/discovery/explore`, `/discovery/nearby`, `/matrimony/daily-matches`) to return optional:
   - `trustScore: number(0..1)`
   - `trustSignals: { phoneVerified, idVerified, photoVerified, hasBio, hasPrompt, photoCount, profileCompleteness }`
   - `matchReasons: string[]` (1-5 concise reasons)
2. Ensure `GET /discovery/compatibility/:candidateId` includes canonical keys:
   - `candidateId`, `compatibilityScore`, `compatibilityLabel`, `matchReasons`, `breakdown`, `preferenceAlignment`
3. Implement `GET /interactions/openers`:
   - Query: `toUserId` (required), `mode` (optional), `context` (optional default `mutual_match`)
   - Response: `{ "suggestions": string[] }`
4. (Optional) Implement `POST /interactions/openers/selection` for analytics.
5. Enforce content constraints:
   - Reasons <= 60 chars, openers <= 160 chars, plain text only.
6. Keep new fields optional so old clients do not break.

### Acceptance tests

- Discovery responses include `matchReasons` for >90% of returned profiles.
- `GET /interactions/openers?toUserId=<valid>` returns at least 1 suggestion for valid, message-eligible users.
- Empty suggestions are returned as `200 { "suggestions": [] }` (not error) when model has no candidates.
- Unknown `toUserId` returns 404 with typed error code.
