# DesiLink — Flutter Dating App (MVP Frontend)

Sophisticated Indian-global dating app: depth-first profiles, map discovery, circles, events, premium, and verification. Built to the 90-day plan (Weeks 1–12).

## Design system

- **Light:** Ivory backgrounds, gold/saffron accents, deep blue, charcoal text.
- **Dark:** Charcoal base, neon-saffron highlights.
- **Typography:** Playfair Display (headings), Inter (body/UI).
- **CTAs:** e.g. "Send Thoughtful Intro", "Explore [City]", "Join This Circle", "Verify to Get Priority", "Upgrade for Global".

## Project structure

```
lib/
├── main.dart                 # Entry, Firebase init
├── app.dart                  # MaterialApp.router + theme
├── core/
│   ├── theme/                # AppColors, AppTypography, AppTheme (light/dark)
│   ├── router/               # go_router (auth, shell, chat thread, paywall, etc.)
│   ├── shell/                # MainShell with bottom nav (Discover, Map, Chats, Circles, Events)
│   ├── constants/            # App CTAs copy
│   ├── analytics/            # AnalyticsService (Week 11 placeholder)
│   └── feature_flags/        # FeatureFlags provider (Week 11)
└── features/
    ├── auth/                 # Login (email/phone), OTP
    ├── onboarding/           # Onboarding carousel
    ├── profile/              # Profile wizard (name, bio, photos, prompts, tags, intent, voice)
    ├── discovery/            # Feed, filters, city chip, travel mode, profile cards, block/report
    ├── map/                  # flutter_map, radius slider, blur/precise, active-now
    ├── chat/                 # Chat list, thread (messages, typing bar, voice note UI)
    ├── premium/              # Paywall, plans, restore purchases
    ├── circles/              # Groups list, join CTA
    ├── events/               # Upcoming / My RSVPs, RSVP, event detail
    ├── ai/                   # MatchReasonChip, ChatSuggestionChip (Week 9)
    ├── verification/         # ID, face, LinkedIn, education, safety score
    └── referral/             # Invite code, share, copy link
```

## Run

```bash
flutter pub get
flutter run
```

### If the IDE shows "Target of URI doesn't exist" for packages

The packages are installed (see `.dart_tool/package_config.json`). The Dart analyzer may be using the wrong folder. Do this:

1. **Open the project folder as the workspace root**  
   File → Open Folder → choose the **desilink** folder (the one that contains `pubspec.yaml`). Do not open a parent folder like `Apps` if it contains multiple projects.

2. **Get packages and restart analysis**  
   - Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`) → **Dart: Get Packages** (or **Flutter: Get Packages**).  
   - Then → **Developer: Reload Window** (or **Dart: Restart Analysis Server**).

3. **Confirm from terminal**  
   `flutter analyze lib` should report no issues. If it does, the codebase is fine and the remaining red squiggles are from the IDE cache; reload usually fixes them.

- **Initial route:** `/login`. From there: OTP → onboarding → profile wizard → main shell at `/`.
- **Firebase:** Optional until you run `flutterfire configure`; `main.dart` catches init errors so the app runs without config.

## Backend / next steps

- Connect auth to Firebase Auth (phone/email, Google, Apple).
- Replace mock data in discovery, map, chat, circles, events with Firestore/API.
- Wire Stripe / in_app_purchase in paywall.
- Add Crashlytics, Mixpanel (or your analytics) in `AnalyticsService`.
- Use feature flags (e.g. Remote Config) in `FeatureFlags`.

## Dependencies (main)

- **State & routing:** flutter_riverpod, go_router
- **Firebase:** firebase_core, firebase_auth, cloud_firestore, firebase_storage, google_sign_in, sign_in_with_apple
- **UI:** google_fonts, flutter_animate, cached_network_image, shimmer, flutter_svg
- **Map:** flutter_map, latlong2
- **Payments:** in_app_purchase, flutter_stripe
- **Media:** image_picker, file_picker, permission_handler
- **Utils:** intl, uuid, equatable, shared_preferences, connectivity_plus, package_info_plus, url_launcher, share_plus
# dating101
