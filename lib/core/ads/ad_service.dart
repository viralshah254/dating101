import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Test ad unit IDs — replace with production IDs before release.
/// https://developers.google.com/admob/flutter/test-ads
class AdUnitIds {
  AdUnitIds._();

  static String get interstitial {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return '';
  }

  static String get rewarded {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    return '';
  }
}

/// Reason for showing an ad (used for analytics and conditional logic).
enum AdRewardReason {
  /// Free user sending a message (message goes to requests).
  sendMessage,
  /// Free user sending one priority interest (after ad).
  priorityInterest,
  /// User (premium or free) viewing/accepting a request — ad before view & respond.
  viewAndRespondToRequest,
  /// Free user unlocking one visitor profile (Likes → Visitors). 2 per week.
  unlockVisitor,
}

/// Service for loading and showing interstitial/rewarded ads.
/// Use test IDs in debug; switch to production in release.
class AdService {
  AdService() {
    _interstitialByReason = {
      AdRewardReason.sendMessage: null,
      AdRewardReason.priorityInterest: null,
      AdRewardReason.viewAndRespondToRequest: null,
      AdRewardReason.unlockVisitor: null,
    };
  }

  static bool _initialized = false;

  /// Call once at app startup (e.g. after runApp).
  static Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    if (kDebugMode) {
      debugPrint('[Ads] Mobile Ads SDK initialized (test mode)');
    }
  }

  late Map<AdRewardReason, InterstitialAd?> _interstitialByReason;

  /// Loads an interstitial for the given [reason]. Returns true when loaded, false on failure.
  /// Completes only when the ad is actually loaded (or failed), so callers can await before showing.
  Future<bool> loadInterstitial(AdRewardReason reason) async {
    final id = AdUnitIds.interstitial;
    if (id.isEmpty) return false;

    final completer = Completer<bool>();
    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              _interstitialByReason[reason] = null;
            },
            onAdFailedToShowFullScreenContent: (a, err) {
              a.dispose();
              _interstitialByReason[reason] = null;
              if (kDebugMode) debugPrint('[Ads] Interstitial failed to show: $err');
            },
          );
          _interstitialByReason[reason] = ad;
          if (kDebugMode) debugPrint('[Ads] Interstitial loaded for $reason');
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (err) {
          if (kDebugMode) debugPrint('[Ads] Interstitial failed to load: $err');
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  /// Shows a loaded interstitial for [reason]. Returns true if ad was shown, false if not loaded or failed.
  /// After showing, the ad is disposed; call [loadInterstitial] again for next time.
  Future<bool> showInterstitial(AdRewardReason reason) async {
    final ad = _interstitialByReason[reason];
    if (ad == null) {
      if (kDebugMode) debugPrint('[Ads] No interstitial loaded for $reason');
      return false;
    }
    await ad.show();
    _interstitialByReason[reason] = null;
    return true;
  }

  /// Preload interstitials for all reward reasons (call on app open or after showing).
  Future<void> preloadAll() async {
    for (final r in AdRewardReason.values) {
      await loadInterstitial(r);
    }
  }

  /// Show ad for [reason]; if not loaded, waits for load to finish then shows. Returns true if ad was shown.
  Future<bool> loadAndShowInterstitial(AdRewardReason reason) async {
    if (_interstitialByReason[reason] == null) {
      final loaded = await loadInterstitial(reason);
      if (!loaded) return false;
    }
    return showInterstitial(reason);
  }
}
