import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mode/app_mode.dart';
import '../mode/mode_provider.dart';

/// Feature flags. Replace with Firebase Remote Config or custom backend.
/// Some flags are mode-dependent (e.g. map in matrimony).
final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  final mode = ref.watch(appModeProvider);
  return FeatureFlags(mode: mode ?? AppMode.dating);
});

class FeatureFlags {
  FeatureFlags({required this.mode});

  final AppMode mode;

  bool get travelMode => true;
  bool get circles => true;
  bool get events => true;
  bool get aiMatchReasoning => true;
  bool get aiChatSuggestions => true;
  bool get verification => true;
  bool get referral => true;
  bool get premiumPaywall => true;

  /// Map in matrimony: remove from main nav; optional "Nearby" inside Matches.
  bool get mapInMatrimony => false;

  /// Circles/events in matrimony: hidden by default or repurposed as "Community meets".
  bool get communitiesInMatrimony => false;

  /// Horoscope section (matrimony profile).
  bool get horoscope => true;

  /// Parent/guardian role (matrimony only).
  bool get parentGuardianRole => true;

  /// Contact request gating (premium or after mutual interest).
  bool get contactRequestGating => true;

  /// Profile boost / featured listing.
  bool get profileBoost => true;
}
