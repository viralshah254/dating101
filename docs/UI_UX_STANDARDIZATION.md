# UI/UX Standardization

Date: 2026-03-12
Goal: make the app feel like one coherent product across Dating, Matrimony, and Both modes.

## What is standardized now

- Global button styling (`FilledButton`, `ElevatedButton`, `OutlinedButton`) from theme tokens.
- Consistent input field shape, padding, and focus/error borders.
- Standardized tab, icon button, dialog, chip, and bottom-sheet theming.
- Bottom navigation uses theme-driven semantic colors instead of per-screen hardcoded colors.
- Signup flow for `both` mode now uses a clean shared-first flow and explicit context messaging.

## Design system rules

- Use `Theme.of(context).colorScheme.*` for UI colors.
- Avoid hardcoded hex colors in feature screens unless it is a branded illustration element.
- Use `AppTypography` for text styles.
- Use `AppTokens` (`lib/core/theme/app_tokens.dart`) for spacing and radius values.
- Keep primary CTA as `FilledButton` and secondary CTA as `OutlinedButton` or `TextButton`.
- Keep one major CTA per screen; avoid competing same-weight actions.

## High-priority next cleanup

- Replace remaining hardcoded strings/colors in:
  - `lib/features/map/screens/map_screen.dart`
  - `lib/features/chat/screens/chat_list_screen.dart`
  - `lib/features/profile/screens/profile_settings_screen.dart`
  - `lib/features/matches/screens/matches_screen.dart`
- Align all sheet/card corners to tokenized radii.
- Unify list empty/error/loading states with one reusable pattern.
- Add spacing helpers for vertical rhythm in forms and cards.

## UX flow standards for onboarding

- Shared data first (identity, photos, interests).
- Mode-specific questions grouped after shared data.
- For `both`, show explicit section labels (`Matrimony ·`, `Dating ·`) and progress context.
- Keep mandatory only for identity/legal eligibility; everything else skippable with later edit.

## Definition of done for UI consistency

- No high-traffic screen uses custom one-off button shapes.
- No critical flow has dead taps or “coming soon” on primary actions.
- Theme switch (light/dark) preserves contrast and hierarchy.
- Core journeys pass UX review:
  - Sign up
  - Discovery interaction
  - Requests/likes handling
  - Chat start and reply
  - Profile edits
