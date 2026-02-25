# saathi Mega Spec — Implementation Status

This doc tracks progress against [saathi-Frontend-MegaSpec.md](/Users/v/Desktop/saathi-Frontend-MegaSpec.md). The app is being redesigned for **dual mode (Dating + Matrimony)** and **full i18n**.

---

## Phase 1 — Foundations (Current)

### Done

1. **i18n**
   - Flutter `gen_l10n` + ARB in `lib/l10n/` (template: `app_en.arb`).
   - English (en) and Hindi (hi) ARB files; keys cover auth, mode select, nav, discovery, matches, requests, shortlist, profile, paywall, verification, referral, and common actions.
   - `MaterialApp.router` uses `AppLocalizations.localizationsDelegates` and `supportedLocales`.
   - **Remaining:** Add ARB files for bn, te, mr, ta, ur, gu, kn, ml, pa (same keys, translate or copy en).

2. **AppMode + persistence**
   - `AppMode` enum: `dating`, `matrimony` in `core/mode/app_mode.dart`.
   - `ModeRepository` (interface + `ModeRepositoryImpl` with `SharedPreferences`) in `core/mode/`.
   - `appModeProvider` (StateNotifier) and `modeSelectedOnceProvider` in `core/mode/mode_provider.dart`.
   - `main.dart` overrides `sharedPreferencesProvider` with `SharedPreferences.getInstance()`.

3. **Feature flags**
   - `FeatureFlags` in `core/feature_flags/feature_flags.dart` now takes `AppMode` and includes: `mapInMatrimony`, `communitiesInMatrimony`, `horoscope`, `parentGuardianRole`, `contactRequestGating`, `profileBoost`.

4. **Mode-aware copy**
   - `AppCopy` in `core/i18n/app_copy.dart`: `ctaSendPrimary(context, mode)`, `discoveryTitle`, `paywallSubtitle` using l10n + mode.

5. **Dual shell + router**
   - **RootShell** (`core/shell/root_shell.dart`): 5 tabs; labels/icons switch by `AppMode` (Dating: Discover, Map, Chats, Communities, Profile; Matrimony: Matches, Requests, Shortlist, Chats, Profile).
   - **ShellBranchContent** (`core/shell/shell_branch_content.dart`): For each branch index, shows the correct screen for the current mode; branch 0 with `mode == null` shows **ModeSelectScreen**.
   - Router in `core/router/app_router.dart`: Uses `appRouterProvider` (Provider&lt;GoRouter&gt;) with `StatefulShellRoute.indexedStack` and 5 branches; each branch renders `ShellBranchContent(branchIndex)`.
   - **Mode select** route: `/mode-select` → `ModeSelectScreen`; after choosing Dating/Matrimony, mode is saved and user goes to `/onboarding`.
   - OTP flow: After verify → `/mode-select` (so first-time users pick mode before onboarding).

6. **Mode select screen**
   - `features/mode_select/screens/mode_select_screen.dart`: “What are you here for?” with two cards (Dating / Matrimony) and short subtitles; on tap, sets mode and navigates to `/onboarding`.

7. **Matrimony screens (UI)**
   - **MatchesScreen** (`features/matches/screens/matches_screen.dart`): Tabs Recommended / Search / Nearby; placeholder content and empty state copy from l10n.
   - **RequestsScreen** (`features/requests/screens/requests_screen.dart`): Tabs Received / Sent; empty states from l10n.
   - **ShortlistScreen** (`features/shortlist/screens/shortlist_screen.dart`): Empty state from l10n.

8. **Communities (Dating)**
   - **CommunityScreen** (`features/community/screens/community_screen.dart`): Single “Communities” tab that combines Circles and Events via inner TabBar (CirclesScreen, EventsScreen).

9. **Discovery + profile (mode-aware copy)**
   - **DiscoveryScreen**: Uses l10n for title, “Daily curated set”, explore city, travel mode hint, filters; passes `AppCopy.ctaSendPrimary(context, mode)` into **ProfileCard** as `sendPrimaryLabel`.
   - **ProfileCard**: Takes `sendPrimaryLabel` and uses it for the primary button (Send Intro vs Express Interest).
   - **FullProfileScreen**: Uses l10n for About, Interests, Prompt, profile not found, km away; primary CTA uses `AppCopy.ctaSendPrimary(context, mode)`.

10. **App entry**
    - `app.dart`: Uses `ref.watch(appRouterProvider)` for `routerConfig` and sets `localizationsDelegates` and `supportedLocales` from `AppLocalizations`.

### Done (Phase 1 continued)

- **Unified domain models**: `lib/domain/models/` — `UserProfile`, `VerificationStatus`, `FamilyDetails`, `DiscoveryPreferences`, `PartnerPreferences`, `DatingExtensions`, `MatrimonyExtensions`, `ProfileSummary`, `Intro`/`Match`/`Interest`/`ContactRequest` (all freezed).
- **Repository interfaces + fakes**: `lib/domain/repositories/` — Auth, Profile, Discovery, Interests, Shortlist, Chat, Subscription. `lib/data/repositories_fake/` — fake implementations; `lib/data/mappers/profile_mapper.dart` — `UserProfile` → `ProfileSummary`. `lib/core/providers/repository_providers.dart` — Riverpod providers.
- **Discovery wired to repos**: `recommendedProfilesProvider` and `profileSummaryProvider` in `features/discovery/providers/discovery_providers.dart`. DiscoveryScreen uses repo + AsyncValue (loading/error/data). ProfileCard and FullProfileScreen use `ProfileSummary` and l10n.
- **i18n — 11 locales**: `lib/l10n/` — app_en.arb (template), app_hi.arb (Hindi), app_bn.arb, app_te.arb, app_mr.arb, app_ta.arb, app_ur.arb, app_gu.arb, app_kn.arb, app_ml.arb, app_pa.arb (English fallback for now; can translate later).

### Not done yet (Phase 1)

- **Onboarding (mode-aware)**: Multi-step onboarding with “Basic identity”, “Core preferences”, “Extended sections” and mode-specific steps (e.g. “Looking for Bride/Groom”, partner prefs) not implemented; still using existing onboarding and identity screens.
- **Profile builder (section-based)**: Replace profile wizard with section-based editor (Photos, About, Basic, Lifestyle, Dating prompts / Matrimony education & family & partner prefs, Verification) — not done.
- **100% strings from i18n**: Many screens (login, splash, tagline, paywall, verification, referral, profile wizard, chat, map, circles, events, profile settings) still have hardcoded strings; to be migrated to l10n.

### Not done (Phase 2+)

- Mode-aware paywall benefits and INR pricing UI.
- Trust Center unified (photo + ID + education + trust score) with all states.
- Privacy controls and language selector in Settings; mode switch in Settings.
- Notification settings UI.
- Advanced filters, “Why recommended” chips, saved searches (matrimony).
- Design system components (AppScaffold, PrimaryButton, SectionCard, EmptyState, etc.).
- Analytics events and subscription state provider.

---

## How to run

1. `flutter pub get`
2. `flutter gen-l10n` (if you add or change ARB files)
3. `flutter run`

Flow: Splash → Login → (Phone) OTP → **Mode select** → Onboarding → … → Main shell. If user opens app when mode is already set, shell shows the correct 5 tabs for that mode; if mode is null (e.g. first install), branch 0 shows Mode Select.

---

## File / folder changes (summary)

- **New:** `lib/core/mode/` (app_mode, mode_repository, mode_provider), `lib/core/i18n/app_copy.dart`, `lib/core/shell/root_shell.dart`, `lib/core/shell/shell_branch_content.dart`, `lib/features/mode_select/`, `lib/features/matches/`, `lib/features/requests/`, `lib/features/shortlist/`, `lib/features/community/screens/community_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_hi.arb`, `l10n.yaml`.
- **Updated:** `pubspec.yaml` (flutter_localizations, generate: true, intl ^0.20.2, freezed_annotation, json_serializable; freezed dev_dep), `main.dart` (SharedPreferences override), `app.dart` (router from provider, localizationsDelegates, supportedLocales), `core/router/app_router.dart` (Provider-based router, RootShell, 5 branches, ShellBranchContent, /mode-select), `core/feature_flags/feature_flags.dart` (mode-dependent flags), `features/auth/screens/otp_screen.dart` (navigate to /mode-select), `features/discovery/screens/discovery_screen.dart` (ConsumerStatefulWidget, l10n, AppCopy), `features/discovery/widgets/profile_card.dart` (sendPrimaryLabel), `features/profile/screens/full_profile_screen.dart` (ConsumerWidget, l10n, AppCopy).
- **Unused for now:** `core/shell/main_shell.dart` (replaced by RootShell); `core/constants/app_ctas.dart` (replaced by l10n + AppCopy where used).
