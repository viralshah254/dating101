import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../analytics/analytics_service.dart';
import '../providers/repository_providers.dart';

import '../mode/app_mode.dart';
import '../mode/mode_provider.dart';

/// Feature flags. Replace with Firebase Remote Config or custom backend.
/// Some flags are mode-dependent (e.g. map in matrimony).
///
/// Fallback behavior:
/// - If remote flags fail to load, defaults are used.
/// - `events` defaults to true, so feature remains available unless explicitly disabled remotely.
final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  final mode = ref.watch(appModeProvider);
  final remote = ref.watch(remoteFeatureFlagsProvider).valueOrNull ?? const {};
  return FeatureFlags(mode: mode ?? AppMode.dating, remoteOverrides: remote);
});

/// Single source of truth for Events/Community feature availability.
final isEventsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagsProvider).events;
});

class FeatureFlags {
  FeatureFlags({required this.mode, this.remoteOverrides = const {}});

  final AppMode mode;
  final Map<String, bool> remoteOverrides;

  bool _value(String key, bool fallback) => remoteOverrides[key] ?? fallback;

  bool get travelMode => _value('travelMode', true);
  bool get circles => _value('circles', true);
  bool get events => _value('events', true);
  bool get aiMatchReasoning => _value('aiMatchReasoning', true);
  bool get aiChatSuggestions => _value('aiChatSuggestions', true);
  bool get verification => _value('verification', true);
  bool get referral => _value('referral', true);
  bool get premiumPaywall => _value('premiumPaywall', true);

  /// Map in matrimony: remove from main nav; optional "Nearby" inside Matches.
  bool get mapInMatrimony => _value('mapInMatrimony', false);

  /// Circles/events in matrimony: hidden by default or repurposed as "Community meets".
  bool get communitiesInMatrimony => _value('communitiesInMatrimony', false);

  /// Horoscope section (matrimony profile).
  bool get horoscope => _value('horoscope', true);

  /// Parent/guardian role (matrimony only).
  bool get parentGuardianRole => _value('parentGuardianRole', true);

  /// Contact request gating (premium or after mutual interest).
  bool get contactRequestGating => _value('contactRequestGating', true);

  /// Profile boost / featured listing.
  bool get profileBoost => _value('profileBoost', true);
}

final remoteFeatureFlagsProvider = FutureProvider<Map<String, bool>>((
  ref,
) async {
  try {
    final res = await ref.read(apiClientProvider).get('/config/feature-flags');
    final raw = (res['flags'] as Map?)?.cast<String, dynamic>() ?? const {};
    final normalized = <String, bool>{
      for (final e in raw.entries) e.key: e.value == true,
    };
    AnalyticsService.instance.log(AnalyticsEvent.featureFlagsLoaded, {
      'count': normalized.length,
      'source': 'remote',
    });
    return normalized;
  } catch (_) {
    AnalyticsService.instance.log(AnalyticsEvent.featureFlagsLoaded, {
      'count': 0,
      'source': 'fallback',
    });
    return const {};
  }
});
