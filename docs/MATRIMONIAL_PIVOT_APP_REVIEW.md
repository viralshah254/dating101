# saathi → Indian Matrimonial App: Codebase Review & Gap Analysis

**Purpose:** Feed this document to ChatGPT (or any AI) to identify what is missing or needs to change when pivoting from an Indian-global **dating app** to an **Indian matrimonial app** that aims to offer a better experience than Shaadi.com, BharatMatrimony, Jeevansathi, etc.

---

## 1. Executive Summary

- **Current product:** saathi — Flutter MVP frontend for a “sophisticated Indian-global dating app” (depth-first profiles, map discovery, circles, events, premium, verification).
- **Target product:** Indian **matrimonial** app with a better UX than incumbents (Shaadi.com & similar).
- **Codebase:** Flutter (Dart), Riverpod, go_router, Firebase (Auth, Firestore, Storage), Material 3, ~35 Dart files under `lib/`.
- **Data:** All discovery/profile/chat/events/circles data is **mock** (in-memory); no backend API or Firestore wiring yet.

---

## 2. Tech Stack & Project Structure

| Layer | Tech |
|-------|------|
| Framework | Flutter, Dart SDK ^3.9 |
| State / routing | flutter_riverpod, go_router |
| Backend (planned) | Firebase (Auth, Firestore, Storage), Google/Apple sign-in |
| Map | flutter_map, latlong2, geolocator, geocoding |
| Payments | in_app_purchase, flutter_stripe (UI only) |
| UI | google_fonts (Playfair Display, Inter), flutter_animate, cached_network_image, shimmer, lottie |
| Media | image_picker, camera, file_picker, permission_handler |

**Structure (abridged):**

```
lib/
├── main.dart, app.dart
├── core/
│   ├── theme/          # AppColors, AppTypography, AppTheme (light/dark)
│   ├── router/         # go_router: splash → login → otp → onboarding → identity → profile-wizard → main shell
│   ├── shell/          # MainShell with bottom nav (Discover, Map, Chats, Circles, Events, Profile)
│   ├── constants/      # AppCTAs (copy strings)
│   ├── analytics/      # AnalyticsService placeholder
│   └── feature_flags/  # FeatureFlags placeholder
└── features/
    ├── auth/           # Login (email/phone), OTP
    ├── onboarding/     # Carousel (depth-first, map, circles & events)
    ├── identity/       # Identity onboarding (gender, interest, relationship, location, language, heritage, community, family, diet)
    ├── profile/        # Profile wizard (basic info, photos, prompts & interests, voice intro), full profile, settings
    ├── discovery/      # Feed, city chip, travel mode, profile cards, filters (placeholder), block/report
    ├── map/            # flutter_map, radius, blur/precise, active-now, cluster pins, profile preview sheet
    ├── chat/           # Chat list, thread (messages, typing bar, voice note UI)
    ├── premium/        # Paywall, Premium & Boost plans, restore purchases
    ├── circles/        # Groups list (mock), Join CTA
    ├── events/         # Upcoming / My RSVPs, event detail, RSVP
    ├── ai/             # MatchReasonChip, ChatSuggestionChip (UI only)
    ├── verification/   # ID, face, LinkedIn, education, safety score; photo verification flow
    ├── referral/       # Invite code, share, copy link
    └── splash/         # Splash, tagline (optional)
```

---

## 3. Current Features (What Exists)

| Feature | Status | Notes |
|--------|--------|------|
| **Auth** | UI + flow | Phone (country code + OTP) and email; Google/Apple buttons (no backend). Default country +91 India. |
| **Onboarding** | UI | 3 slides: “Depth-first connections”, “Explore by map”, “Circles & events”. Skip → Identity. |
| **Identity onboarding** | UI | 8 steps: gender, who you’re interested in, relationship intent (incl. “Marriage”), origin/live location, language, heritage, community tags, family orientation (Traditional↔Progressive), diet. Data not persisted. |
| **Profile wizard** | UI | 4 steps: basic info (name, bio), photos (6 slots, “main”), conversation starter prompt + interests, voice intro. Completion %; no backend. |
| **Discovery** | UI + mock | “Daily curated set”, city selector (London, Dubai, Mumbai, etc.), travel mode, list of profile cards; filters = placeholder. |
| **Profile card** | UI | Name, age, city, distance, verified badge, match reason chip, bio, prompt answer, “Send Thoughtful Intro” (→ paywall). Block/Report in menu. |
| **Full profile** | UI | Same fields + interests; CTA “Send Thoughtful Intro”. |
| **Map** | UI + mock | Radius slider, location blur, “Active now” chip, cluster pins, tap pin → bottom sheet → View profile / Send intro. Mock pins in London. |
| **Chat** | UI + mock | List of threads, thread screen with bubbles, voice note UI, typing bar. Mock threads/messages. |
| **Circles** | UI + mock | List of groups (e.g. London Desi Professionals, IIT Alumni UK, Chai & Chats); “Join” → paywall. |
| **Events** | UI + mock | Upcoming / My RSVPs tabs; event cards; detail sheet; RSVP. Mock events. |
| **Premium** | UI | Paywall: “Unlock more with saathi”, Premium (£9.99/mo), Boost pack; features like “See who likes you”, “Unlimited intros”, “Travel mode”, “Priority in discovery”, “Read receipts”. Restore purchases. |
| **Verification** | UI | Tiles: ID, face match, LinkedIn, education; safety score bar; ID upload bottom sheet. Photo verification: intro → capture → challenge → processing/success/failed/retry. |
| **Referral** | UI | Invite code, copy, share (“sophisticated dating, globally”), copy link; rewards text (Premium for inviter/invitee). |
| **Profile & settings** | UI | My profile placeholder, Verification, Notifications, Privacy & safety, Help, Terms & Privacy, Sign out. |
| **Splash / tagline** | UI | Splash: “saathi”, “Sophisticated connections, globally.” Tagline: “Depth-first connections. No mindless swiping.” |

---

## 4. Data Models (Relevant to Matrimony)

**DiscoveryProfile (discovery, map, full profile):**

- `id`, `name`, `age`, `city`, `bio`, `promptAnswer`, `imageUrl`
- `distanceKm`, `verified`, `matchReason`, `interests` (list)

**Identity onboarding (in-memory only):**

- Gender, interest (Men/Women/Everyone/Non-binary), relationship intent (Fun/casual, Serious relationship, **Marriage**, Friends first, Open to see, Still figuring it out)
- Origin & current live (country/city list), language, heritage (North/South/East/West Indian, NRI, Mixed, Other), community tags (Tech, Healthcare, etc.), family orientation (slider), diet (Vegetarian, Vegan, Non-vegetarian, Flexible)

**Missing for typical matrimonial profiles (vs Shaadi.com / BharatMatrimony):**

- Religion, caste/sub-caste, mother tongue, marital status, height, weight, complexion, body type
- Education (degree, institution, occupation, employed in, annual income)
- Family (father/mother occupation, siblings, family type, family values, family status)
- Horoscope / birth details (date, time, place, manglik, nakshatra, etc.)
- Partner preferences (all of the above as filters)
- “Looking for” (Bride/Groom) and role (Self/Parent/Guardian/Sibling/Friend)
- Document verification (e.g. photo ID, address) for trust
- Shortlist / interest / accept / reject workflow (not just “intro”)
- Contact visibility (phone/email) as premium or after mutual interest

---

## 5. User Flows (Current)

1. **Cold start:** Splash → Login (or Tagline → Login).
2. **Login:** Phone + OTP → Onboarding **or** Email/Google/Apple → Onboarding. (OTP screen can go to `/onboarding` or `/identity` depending on code path.)
3. **Onboarding:** 3 slides → “Get started” → Identity.
4. **Identity:** 8 steps (gender, interest, relationship, location, language, heritage, community, family, diet) → Profile wizard (with Skip).
5. **Profile wizard:** 4 steps → “Finish” → Main shell at `/` (Discover).
6. **Main:** Bottom nav: Discover | Map | Chats | Circles | Events | Profile. Discover = list of profile cards; Map = map with pins; Chats = thread list; Circles = groups; Events = upcoming/RSVPs; Profile = settings.
7. **Discovery:** Tap card → Full profile. “Send Thoughtful Intro” → Paywall (no real messaging yet).
8. **Verification / Referral / Paywall:** Reached from profile settings, discovery, or referral; no backend.

---

## 6. Copy & Terminology (Dating → Matrimony)

**Branding / taglines (to change):**

- “saathi” — can keep or rename.
- “Sophisticated connections, globally.” → matrimony positioning.
- “Depth-first connections. No mindless swiping.” → e.g. “Serious about marriage. Meaningful profiles.”
- “See full profiles and send thoughtful intros—no mindless swiping.” (onboarding)
- “Give friends a better way to connect” / “sophisticated dating, globally.” (referral)

**CTAs (app_ctas.dart):**

- “Complete Your Profile — %s%”, “Unlock Better Matches”, “Explore %s”, “Send Thoughtful Intro”, “Join This Circle”, “Verify to Get Priority”, “Upgrade for Global”

**Suggestions for matrimony:**

- “Send Interest”, “Express Interest”, “Shortlist”, “Contact request”, “Unlock contact”
- “Better matches” → “Better life partner matches” or “Compatible profiles”
- “Explore [City]” can stay or become “Matches in [City]”
- Premium: “See who viewed you”, “Unlimited interests”, “Priority listing”, “Contact details”, “Horoscope matching”

**Screen-level copy:**

- Discovery: “Daily curated set” → e.g. “Suggested matches” or “Matches for you”.
- Profile wizard: “Conversation starter”, “Answer a prompt so matches have something to talk about” → e.g. “About your expectations”, “What you look for in a partner”.
- Photos: “Profiles with clear face photos get more matches” → “Clear photos help families and matches connect.”
- Verification: “Verified profiles get more matches” → “Verified profiles get more trust and responses.”
- Paywall: “See who likes you”, “Unlimited intros”, “Travel mode”, “Priority in discovery”, “Read receipts” → matrimony equivalents (who viewed, unlimited interests, search in other cities, featured profile, read receipts).
- Referral: “sophisticated dating” → “finding a life partner” or “matrimonial matches”.

**Relationship intent:**

- Identity already has “Marriage”. For matrimony, consider removing or downranking “Fun/casual”, “Friends first”, “Open to see”, “Still figuring it out” or moving them; emphasize “Marriage” and “Serious relationship”.

---

## 7. What Matrimony Apps Typically Have (vs Current App)

Use this as a checklist for “what’s missing” when feeding to ChatGPT.

**Profile (self):**

- [ ] Religion, caste, sub-caste, mother tongue
- [ ] Marital status (Never married, Divorced, Widowed, etc.)
- [ ] Height, weight, complexion, body type
- [ ] Education (degree, institution), occupation, employer, annual income
- [ ] Family (father/mother occupation, siblings, family type, family values, family status)
- [ ] Horoscope (DOB, time, place, manglik, nakshatra, chart upload)
- [ ] Diet (already present), drinking/smoking if desired
- [ ] “About me” / expectations (bio can be repurposed)
- [ ] Who is creating profile (Self, Parent, Brother/Sister, Relative, Friend)
- [ ] Multiple photos (already have slots; need validation/guidance for matrimony)

**Search & filters:**

- [ ] Search by: religion, caste, education, occupation, location, age, height, income, marital status, etc.
- [ ] Saved search / alerts
- [ ] “Matches for you” / recommended list (algorithm or rule-based)

**Actions:**

- [ ] Send Interest / Express Interest (replaces “Send Thoughtful Intro”)
- [ ] Shortlist (save profile)
- [ ] Accept / Reject interest
- [ ] Request contact (phone/email) — often gated (premium or after mutual interest)
- [ ] Chat/message after mutual interest or contact permission
- [ ] Block / Report (already in UI)

**Trust & verification:**

- [ ] Photo verification (exists), ID verification (exists in UI)
- [ ] Mobile/email verified badge
- [ ] “Verified by parent/family” or “Profile verified” (optional)
- [ ] Horoscope verification (optional)

**Monetisation:**

- [ ] Free: limited views, limited interests, no contact
- [ ] Premium: unlimited interests, see who viewed, contact details, priority listing, featured profile, horoscope match
- [ ] Plan names and pricing (INR, regional pricing)

**Other:**

- [ ] Invite/register as Parent/Guardian (separate flow or role)
- [ ] Privacy: hide profile from specific communities, hide contact until accepted
- [ ] Notifications: new match, interest received, interest accepted, contact request
- [ ] “Circles” and “Events”: repurpose or rename (e.g. community events, offline meets) or drop for MVP
- [ ] Map: less central in matrimony; can keep for “matches in this city” or remove from primary nav

---

## 8. Navigation & IA Considerations

- **Bottom nav:** Discover | Map | Chats | Circles | Events | Profile. For matrimony, consider: **Matches** (or Search) | Shortlisted | Chats | Requests (interests received/sent) | Profile. Map and Circles/Events may become secondary or optional.
- **Routes:** All existing routes remain; new screens may be needed: e.g. Shortlisted, Interest requests, Partner preferences, Extended profile (religion, family, horoscope), Search/filters full screen.

---

## 9. Backend / Integration Gaps

- Auth: Firebase Auth not wired (phone OTP, Google, Apple).
- No Firestore (or API) for: users, profiles, interests, shortlists, messages, notifications.
- No real payments (Stripe/IAP); no subscription state.
- Analytics and feature flags are placeholders.
- All data is mock; no persistence, no search, no matching logic.

---

## 10. Suggested Prompt for ChatGPT

You can paste this (and optionally this file) into ChatGPT:

**Prompt:**

“We have a Flutter dating app (saathi) and want to turn it into an Indian matrimonial app that’s better than Shaadi.com and similar apps. Attached is a detailed review of the codebase (features, data models, flows, copy, and a checklist of what typical matrimony apps have).  
1) List everything that is **missing** in our app compared to a full matrimonial product (profile fields, search, actions, monetisation, trust, privacy).  
2) For each existing feature (discovery, map, chat, circles, events, premium, verification), say whether we should **keep, repurpose, or remove** it for matrimony and how.  
3) Suggest **copy and terminology** changes (app-wide) from dating to matrimony.  
4) Suggest a **phased plan** (e.g. Phase 1: profile + search + interest/shortlist, Phase 2: contact request + chat + payments, Phase 3: verification + parents + advanced).  
5) Any **UX improvements** that would make us clearly better than Shaadi.com (e.g. less clutter, faster signup, better filters, transparency in pricing, safety).”

---

## 11. File Reference (Where Key Things Live)

| What | File(s) |
|------|--------|
| App name, theme mode | `app.dart` |
| Routes | `core/router/app_router.dart` |
| Bottom nav labels | `core/shell/main_shell.dart` |
| CTAs / copy | `core/constants/app_ctas.dart` |
| Colors, typography, theme | `core/theme/app_colors.dart`, `app_typography.dart`, `app_theme.dart` |
| Discovery profile model + mock | `features/discovery/models/discovery_profile.dart` |
| Profile card, discovery screen | `features/discovery/widgets/profile_card.dart`, `features/discovery/screens/discovery_screen.dart` |
| Full profile screen | `features/profile/screens/full_profile_screen.dart` |
| Profile wizard steps | `features/profile/screens/profile_wizard_screen.dart` |
| Identity onboarding (relationship, heritage, diet, etc.) | `features/identity/screens/identity_onboarding_screen.dart` |
| Onboarding carousel copy | `features/onboarding/onboarding_screen.dart` |
| Splash / tagline copy | `features/splash/screens/splash_screen.dart`, `tagline_screen.dart` |
| Login / OTP | `features/auth/screens/login_screen.dart`, `otp_screen.dart` |
| Paywall / premium copy | `features/premium/screens/paywall_screen.dart` |
| Verification screens | `features/verification/screens/verification_screen.dart`, `photo_verification_screen.dart` |
| Referral copy | `features/referral/screens/referral_screen.dart` |
| Map screen, pins, preview | `features/map/screens/map_screen.dart` |
| Chat list, thread | `features/chat/screens/chat_list_screen.dart`, `chat_thread_screen.dart` |
| Circles, events | `features/circles/screens/circles_screen.dart`, `features/events/screens/events_screen.dart` |
| Profile settings | `features/profile/screens/profile_settings_screen.dart` |

---

*Document generated from codebase review for the saathi → Indian matrimonial pivot. Update this file as the product and codebase evolve.*
