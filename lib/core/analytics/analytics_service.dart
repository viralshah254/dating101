import 'package:flutter/foundation.dart';

enum AnalyticsEvent {
  screenView('screen_view'),

  // Auth funnel
  otpSent('otp_sent'),
  otpVerified('otp_verified'),
  loginCompleted('login_completed'),
  sessionRefreshed('session_refreshed'),
  sessionExpired('session_expired'),

  // Onboarding funnel
  onboardingStepViewed('onboarding_step_viewed'),
  onboardingStepCompleted('onboarding_step_completed'),
  onboardingCompleted('onboarding_completed'),
  onboardingBlockedByQualityGate('onboarding_blocked_quality_gate'),

  // Discovery / matching funnel
  discoveryFeedLoaded('discovery_feed_loaded'),
  profileViewed('profile_viewed'),
  interestSent('interest_sent'),
  interestAccepted('interest_accepted'),
  mutualMatchCreated('mutual_match_created'),

  // Chat funnel
  chatThreadOpened('chat_thread_opened'),
  messageSent('message_sent'),
  messageRequestSent('message_request_sent'),
  messageRequestAccepted('message_request_accepted'),

  // Ads
  adLoadStarted('ad_load_started'),
  adLoadResult('ad_load_result'),
  adShown('ad_shown'),

  // Paywall / subscriptions funnel
  paywallViewed('paywall_viewed'),
  paywallPlanSelected('paywall_plan_selected'),
  paywallSubscribeStarted('paywall_subscribe_started'),
  paywallSubscribeSucceeded('paywall_subscribe_succeeded'),
  paywallSubscribeFailed('paywall_subscribe_failed'),
  paywallRestoreStarted('paywall_restore_started'),
  paywallRestoreSucceeded('paywall_restore_succeeded'),
  paywallRestoreFailed('paywall_restore_failed'),

  // Feature infrastructure
  featureFlagsLoaded('feature_flags_loaded'),
  gatedRouteBlocked('gated_route_blocked'),

  // Errors
  apiError('api_error'),
  unexpectedError('unexpected_error');

  const AnalyticsEvent(this.name);
  final String name;
}

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;

  bool _enabled = true;

  void setEnabled(bool value) => _enabled = value;

  void log(AnalyticsEvent event, [Map<String, Object?>? params]) {
    logEvent(event.name, params);
  }

  void logEvent(String name, [Map<String, Object?>? params]) {
    if (!_enabled) return;
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Analytics] $name ${params ?? {}}');
    }
    // Mixpanel.track(name, properties: params);
  }

  void logScreenView(String screenName) {
    log(AnalyticsEvent.screenView, {'screen': screenName});
  }

  void setUserId(String? id) {
    if (!_enabled) return;
    // Mixpanel.identify(id);
  }

  void logOnboardingStepViewed({
    required String mode,
    required String stepId,
    required int stepIndex,
    required int totalSteps,
  }) {
    log(AnalyticsEvent.onboardingStepViewed, {
      'mode': mode,
      'step_id': stepId,
      'step_index': stepIndex,
      'total_steps': totalSteps,
    });
  }

  void logOnboardingStepCompleted({
    required String mode,
    required String stepId,
    required int stepIndex,
    required int totalSteps,
  }) {
    log(AnalyticsEvent.onboardingStepCompleted, {
      'mode': mode,
      'step_id': stepId,
      'step_index': stepIndex,
      'total_steps': totalSteps,
    });
  }

  void logOnboardingCompleted({
    required String mode,
    required int totalSteps,
    required int profileCompletionPercent,
  }) {
    log(AnalyticsEvent.onboardingCompleted, {
      'mode': mode,
      'total_steps': totalSteps,
      'profile_completion_percent': profileCompletionPercent,
    });
  }

  void logOnboardingQualityBlocked({
    required String mode,
    required int photoCount,
    required int interestsCount,
    required int bioLength,
  }) {
    log(AnalyticsEvent.onboardingBlockedByQualityGate, {
      'mode': mode,
      'photo_count': photoCount,
      'interests_count': interestsCount,
      'bio_length': bioLength,
    });
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  void logOtpSent({required String maskedPhone}) =>
      log(AnalyticsEvent.otpSent, {'masked_phone': maskedPhone});

  void logOtpVerified({required bool isNewUser}) =>
      log(AnalyticsEvent.otpVerified, {'is_new_user': isNewUser});

  void logLoginCompleted({required bool isNewUser, required String mode}) =>
      log(AnalyticsEvent.loginCompleted, {'is_new_user': isNewUser, 'mode': mode});

  void logSessionExpired() => log(AnalyticsEvent.sessionExpired);

  // ── Discovery / Matching ─────────────────────────────────────────────────

  void logInterestSent({required String toUserId, required String mode}) =>
      log(AnalyticsEvent.interestSent, {'to_user_id': toUserId, 'mode': mode});

  void logInterestAccepted({required String fromUserId, required String mode}) =>
      log(AnalyticsEvent.interestAccepted, {'from_user_id': fromUserId, 'mode': mode});

  void logMutualMatch({required String matchId, required String mode}) =>
      log(AnalyticsEvent.mutualMatchCreated, {'match_id': matchId, 'mode': mode});

  // ── Chat ─────────────────────────────────────────────────────────────────

  void logMessageSent({required String threadId, required bool isPremium, required bool usedAd}) =>
      log(AnalyticsEvent.messageSent, {
        'thread_id': threadId,
        'is_premium': isPremium,
        'used_ad': usedAd,
      });

  // ── Paywall / IAP ─────────────────────────────────────────────────────────

  void logPaywallRestoreStarted({required String platform}) =>
      log(AnalyticsEvent.paywallRestoreStarted, {'platform': platform});

  void logPaywallRestoreSucceeded({required String planId, required String platform}) =>
      log(AnalyticsEvent.paywallRestoreSucceeded, {'plan_id': planId, 'platform': platform});

  void logPaywallRestoreFailed({required String platform, required String reason}) =>
      log(AnalyticsEvent.paywallRestoreFailed, {'platform': platform, 'reason': reason});

  // ── Errors ────────────────────────────────────────────────────────────────

  void logApiError({required String code, required int statusCode, required String path}) =>
      log(AnalyticsEvent.apiError, {'code': code, 'status_code': statusCode, 'path': path});

  // ── MVP success metrics (legacy helpers) ─────────────────────────────────

  void logProfileCompletion(int percent) =>
      logEvent('profile_completion', {'percent': percent});
  void logMatch(String matchId) => logEvent('match', {'match_id': matchId});
  void logReply(String threadId) => logEvent('reply', {'thread_id': threadId});
  void logPremiumConversion(String plan) =>
      logEvent('premium_conversion', {'plan': plan});
  void logRetentionD7() => logEvent('retention_d7');
  void logRetentionD30() => logEvent('retention_d30');
}
