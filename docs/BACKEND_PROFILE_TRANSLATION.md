# Backend: Translating user-generated profile content

Users write bios, about-me, and other profile text in their own language. Viewers may use the app in a different language (e.g. Hindi UI but viewing a profile with an English bio, or vice versa). This doc specifies how the backend can return **translated** profile content so that bios, marital status labels, religion, occupation, interests, etc. appear in the **viewer’s preferred language**.

---

## 1. Goal

- **Bio / aboutMe**: When a viewer’s app language is different from the content language, the backend returns the text translated into the viewer’s locale when possible.
- **Enum-like fields** (marital status, religion, diet, education, etc.): Return **localized labels** for the viewer’s locale (e.g. “Widowed” in English, “विधुर/विधवा” in Hindi), either by storing translations or by sending a **key** (e.g. `maritalStatusKey: "widowed"`) so the app can look up the label in its l10n.
- **Interests**: Same as above — localized strings for the viewer’s locale.

---

## 2. Viewer locale

The app sends the viewer’s preferred language on every request so the backend can return content in that language.

### 2.1 Accept-Language header

The API client sets:

```http
Accept-Language: hi
```

(or `en`, `ta`, `te`, `mr`, `bn`, `gu`, `kn`, `ml`, `pa`, `ur` — match your supported app locales).

- Use this on **all** authenticated requests, or at least on:
  - `GET /profile/:userId`
  - `GET /profile/:userId/summary`
  - `GET /discovery/recommended`
  - `GET /discovery/explore`
  - `GET /discovery/search`
  - `GET /discovery/nearby`
- Backend reads `Accept-Language`; if missing, treat as `en`.

### 2.2 Optional query param (if you prefer)

Some APIs may also accept:

```http
GET /profile/usr_123/summary?locale=hi
```

If both `Accept-Language` and `locale` are present, prefer `locale` for that request.

---

## 3. What to translate / localize

| Content type | Example | How to handle |
|-------------|--------|----------------|
| **Bio / aboutMe** | Free text in any language | Translate to viewer locale (e.g. Google Translate API); cache by (profileId, field, targetLocale). Return translated string in `bio` / `aboutMe`. |
| **Marital status** | "Widowed", "Never married", etc. | Option A: Store a **key** (e.g. `widowed`, `never_married`) and a mapping table to localized labels per locale; return the label for viewer locale. Option B: Store/return only the key; app uses l10n to resolve label (see §5). |
| **Religion, community, diet, education, occupation** | Free text or from a fixed list | Same as marital status: key + localized label, or key-only and app resolves. |
| **Interests** | "Reading", "Music", "Yoga" | If interests are from a fixed list, use keys and return localized labels for viewer locale. If user can enter custom interests, translate free text and cache. |
| **Mother tongue, city, employer** | Free text | Translate to viewer locale when possible; otherwise return as-is. |

---

## 4. Backend implementation options

### Option A: Translate on the fly and cache

- When serving a profile/summary, if stored content language ≠ requested locale:
  - Call a translation API (e.g. Google Cloud Translation) for `bio`, `aboutMe`, and other free-text fields.
  - Cache result by (userId, field, targetLocale) to avoid repeated calls.
- For enum-like fields, maintain a **mapping table** (e.g. `marital_status_labels`: key → { en: "Widowed", hi: "विधुर/विधवा", ... }) and return the label for the requested locale.

### Option B: Pre-translate and store

- When the user saves their profile, or in a background job, translate and store:
  - `bio_en`, `bio_hi`, … or a JSON `bioTranslations: { "en": "...", "hi": "..." }`.
- When serving, pick the field for the requested locale; fallback to original or `en`.

### Option C: Key-based enums only

- Store only **keys** for marital status, religion, diet, etc. (e.g. `maritalStatusKey: "widowed"`).
- Return keys in the API response; the **app** resolves the label using its l10n (see §5). No backend translation for these.
- For **bio / aboutMe**, use Option A or B (translate and return a single string in the viewer’s locale).

---

## 5. App fallback: key-based labels

If the backend returns **keys** for enum-like fields, the app can map them to localized strings:

- Example response: `"maritalStatusKey": "widowed"`, `"religionKey": "islam"`.
- The app already has l10n for labels like “Widowed”, “Marital status”, “Religion”. It can add keys for **value** labels (e.g. `widowed`, `never_married`, `divorced`) and use them when the API returns `maritalStatusKey` instead of (or in addition to) `maritalStatus`.

So the backend can either:

- Return **localized** strings (e.g. `maritalStatus: "विधुर/विधवा"` when `Accept-Language: hi`), or  
- Return **keys** (e.g. `maritalStatusKey: "widowed"`) and let the app show the localized label.

---

## 6. Optional: on-demand translate endpoint

For a “Translate to [language]” button (e.g. when the backend did not return a translation or the user wants a different target language):

```http
POST /translate
Content-Type: application/json
Authorization: Bearer <token>
```

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| text | string | Yes | Text to translate (e.g. bio snippet). |
| targetLocale | string | Yes | Target language code (e.g. `en`, `hi`). |

**Success** `200 OK`:

```json
{
  "translatedText": "Translated content here.",
  "detectedSourceLocale": "hi"
}
```

- Backend uses Google Translate (or similar) and optionally rate-limits per user.
- App can use this when the user taps “Translate” on a bio or other block of text.

---

## 7. Suggested response shape (no key change required)

You can keep the same response shape. The only change is **what you put in each field**:

- For a given `GET /profile/:userId/summary` or `GET /profile/:userId` with `Accept-Language: hi`:
  - `bio` / `aboutMe`: translated into Hindi when possible.
  - `maritalStatus`, `religion`, `occupation`, etc.: either localized strings for Hindi or keys (if app supports key-based display).
  - `interests`: list of localized (or key-based) strings for Hindi.

So the client continues to use `profile.bio`, `profile.maritalStatus`, etc.; the backend simply fills them with the right language for the viewer.

---

## 8. Checklist for backend

- [ ] Read `Accept-Language` (and optional `locale` query) on profile and discovery endpoints.
- [ ] For free text (bio, aboutMe): translate to viewer locale (on-the-fly + cache or pre-stored); return in existing `bio` / `aboutMe` fields.
- [ ] For enum-like fields (marital status, religion, etc.): return localized labels for viewer locale, or return keys and document for app l10n.
- [ ] For interests: return localized (or key-based) labels for viewer locale.
- [ ] (Optional) Implement `POST /translate` for on-demand translation and document for the app.

Once this is in place, the app will send the viewer’s locale on every request; no change to response schema is required if you return translated/localized content in the same fields.
