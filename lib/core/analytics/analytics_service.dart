import 'package:flutter/foundation.dart';

/// Week 11 — Analytics (Mixpanel/custom). Replace with real implementation.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;

  bool _enabled = true;

  void setEnabled(bool value) => _enabled = value;

  void logEvent(String name, [Map<String, Object?>? params]) {
    if (!_enabled) return;
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Analytics] $name ${params ?? {}}');
    }
    // TODO: Mixpanel / Firebase Analytics
    // Mixpanel.track(name, properties: params);
  }

  void logScreenView(String screenName) {
    logEvent('screen_view', {'screen': screenName});
  }

  void setUserId(String? id) {
    if (!_enabled) return;
    // TODO: Mixpanel.identify(id);
  }

  /// MVP success metrics
  void logProfileCompletion(int percent) =>
      logEvent('profile_completion', {'percent': percent});
  void logMatch(String matchId) => logEvent('match', {'match_id': matchId});
  void logReply(String threadId) => logEvent('reply', {'thread_id': threadId});
  void logPremiumConversion(String plan) =>
      logEvent('premium_conversion', {'plan': plan});
  void logRetentionD7() => logEvent('retention_d7');
  void logRetentionD30() => logEvent('retention_d30');
}
