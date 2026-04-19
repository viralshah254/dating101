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
import 'data/api/api_client.dart';
import 'data/api/token_storage.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.initialize();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) debugPrint('[Firebase] No default app after init');
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
