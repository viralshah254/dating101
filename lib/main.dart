import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/mode/mode_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/repository_providers.dart';
import 'data/api/token_storage.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(tokens),
      ],
      child: const SaathiApp(),
    ),
  );
}
