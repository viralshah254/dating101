import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/ads/ad_service.dart';
import 'core/mode/mode_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/repository_providers.dart';
import 'core/referral/install_referrer_reader.dart';
import 'data/api/api_client.dart';
import 'data/api/token_storage.dart';
import 'features/premium/services/paywall_trigger_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.initialize();
  try {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } on FirebaseException catch (e) {
        // Native layer may already have registered [DEFAULT] while Dart's [Firebase.apps] is still empty.
        if (e.code != 'duplicate-app' && kDebugMode) {
          debugPrint('[Firebase] Init failed: $e');
        }
      }
    }
    if (kDebugMode) debugPrint('[Firebase] Initialized');
    // FCM is only available on iOS/Android; skip on macOS/Windows/web (MissingPluginException)
    try {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } on MissingPluginException {
      if (kDebugMode) debugPrint('[FCM] Not available on this platform');
    }
  } catch (e) {
    if (kDebugMode) debugPrint('[Firebase] Init failed: $e');
  }
  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStorage();
  await tokens.load();

  // Record this app open for the day-streak paywall trigger.
  await PaywallTriggerService.recordAppOpen();

  // On Android, read the Play Store install referrer (populated by the shared
  // download link ?ref=CODE → referrer=ref%3DCODE on the Play Store URL).
  // Stored once; pre-fills the referral code field on the sign-up screen.
  const kPendingRef = 'pending_referral_code';
  if (prefs.getString(kPendingRef) == null) {
    final installRef = await readInstallReferralCode();
    if (installRef != null) {
      await prefs.setString(kPendingRef, installRef);
    }
  }

  // Proactively refresh the access token while the app is still initialising.
  // This eliminates the "N requests × (401 + retry)" cold-start penalty: by the
  // time the first screen fires its parallel API calls the token is already fresh.
  if (tokens.isLoggedIn && !resolvedApiConfig.useFakeBackend) {
    final warmup = ApiClient(
      baseUrl: resolvedApiConfig.baseUrl,
      tokenStorage: tokens,
    );
    await warmup.warmUpToken();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(tokens),
      ],
      child: const ShubhmilanApp(),
    ),
  );
}
