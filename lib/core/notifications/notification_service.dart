import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Top-level handler for FCM when app is in background. Must be registered in main().
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No navigation here; tap is handled via onMessageOpenedApp when user opens app.
}

/// Handles FCM: permission, token, foreground/background/terminated messages,
/// and deep-link navigation from notification taps.
///
/// Backend sends all push notifications; this service only:
/// - Requests permission and gets FCM token
/// - Registers token with backend (caller's responsibility after login)
/// - Handles incoming messages and invokes [onTap] with FCM `data` when user taps
abstract class NotificationService {
  /// Initialize listeners. Call once after Firebase.initializeApp().
  Future<void> initialize();

  /// Request notification permission (iOS). On Android returns current settings.
  Future<NotificationSettings> requestPermission();

  /// Get current FCM token for registering with backend. Returns null if not granted.
  Future<String?> getToken();

  /// Call when user logs in to register token with backend.
  /// Implementations should call API (e.g. POST /profile/me/fcm-token).
  Future<void> registerTokenWithBackend(String token);

  /// Set callback to navigate when a notification is tapped (deep link).
  void setOnNotificationTap(void Function(Map<String, dynamic> data) onTap);

  /// Clean up on logout (e.g. delete token on backend if supported).
  Future<void> onLogout();
}

/// Default implementation using Firebase Messaging.
class FirebaseNotificationService extends NotificationService {
  FirebaseNotificationService({
    required this.onRegisterToken,
    this.onLogoutCallback,
  });

  final Future<void> Function(String token) onRegisterToken;
  final Future<void> Function()? onLogoutCallback;

  void Function(Map<String, dynamic> data)? _onNotificationTap;
  bool _initialized = false;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _localNotificationsReady = false;
  /// True after [MissingPluginException] — native code not linked (need full `flutter run`, not hot reload).
  bool _localNotificationsBroken = false;

  @override
  void setOnNotificationTap(void Function(Map<String, dynamic> data) onTap) {
    _onNotificationTap = onTap;
  }

  Future<void> _ensureLocalNotifications() async {
    if (_localNotificationsReady || _localNotificationsBroken) return;
    try {
      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final p = response.payload;
          if (p == null || p.isEmpty || _onNotificationTap == null) return;
          try {
            final decoded = jsonDecode(p);
            if (decoded is Map) {
              _onNotificationTap!(
                decoded.map((k, v) => MapEntry(k.toString(), v)),
              );
            }
          } catch (_) {}
        },
      );
      _localNotificationsReady = true;
    } on MissingPluginException catch (e) {
      _localNotificationsBroken = true;
      if (kDebugMode) {
        debugPrint(
          '[FCM] flutter_local_notifications: native plugin missing ($e). '
          'Stop the app completely, then run `flutter clean && flutter pub get && flutter run` '
          '(hot reload does not register new plugins).',
        );
      }
    }
  }

  /// Android: FCM does not show a heads-up banner while the app is in the **foreground**.
  /// Mirror the notification payload locally so tests and real chats are visible.
  Future<void> _showForegroundLocalNotification(RemoteMessage message) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_localNotificationsBroken) return;
    final n = message.notification;
    if (n == null) return;
    try {
      await _ensureLocalNotifications();
      if (!_localNotificationsReady) return;
      final id = message.messageId?.hashCode.abs() ??
          DateTime.now().millisecondsSinceEpoch.remainder(1 << 30);
      final payload = jsonEncode(message.data);
      await _localNotifications.show(
        id,
        n.title ?? 'Notification',
        n.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High importance notifications',
            channelDescription: 'Messages, matches, and alerts',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: payload,
      );
    } on MissingPluginException catch (e) {
      _localNotificationsBroken = true;
      if (kDebugMode) {
        debugPrint('[FCM] Local notification show failed (rebuild app): $e');
      }
    }
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        if (kDebugMode) {
          debugPrint('[FCM] Foreground message: ${message.notification?.title}');
        }
        await _showForegroundLocalNotification(message);
      });

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _navigateFromData(initial.data);

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        onRegisterToken(newToken);
      });

      _initialized = true;
    } on MissingPluginException {
      debugPrint('[FCM] Not available on this platform (iOS/Android only)');
    } catch (e) {
      debugPrint('[FCM] Init error: $e');
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  void _navigateFromData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty || _onNotificationTap == null) return;
    _onNotificationTap!(Map<String, dynamic>.from(data));
  }

  @override
  Future<NotificationSettings> requestPermission() async {
    try {
      return await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } on MissingPluginException {
      rethrow;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      // Android 13+ (API 33): POST_NOTIFICATIONS must be granted or getToken often stays null.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final notif = await Permission.notification.status;
        if (!notif.isGranted) {
          final req = await Permission.notification.request();
          if (!req.isGranted) {
            if (kDebugMode) {
              debugPrint(
                '[FCM] Android notification permission denied or permanently denied — '
                'token will not register until user allows notifications in Settings.',
              );
            }
            return null;
          }
        }
      }

      final permission = await FirebaseMessaging.instance.getNotificationSettings();
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) debugPrint('[FCM] getNotificationSettings: denied');
        return null;
      }
      if (permission.authorizationStatus == AuthorizationStatus.notDetermined) {
        final granted = await requestPermission();
        if (granted.authorizationStatus != AuthorizationStatus.authorized &&
            granted.authorizationStatus != AuthorizationStatus.provisional) {
          if (kDebugMode) debugPrint('[FCM] requestPermission: not authorized');
          return null;
        }
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (kDebugMode && token != null) {
        debugPrint('[FCM] getToken ok len=${token.length}');
      }
      if (kDebugMode && token == null) {
        debugPrint('[FCM] getToken returned null (check Play services / Firebase project / emulator image)');
      }
      return token;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> registerTokenWithBackend(String token) async {
    await onRegisterToken(token);
  }

  @override
  Future<void> onLogout() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } on MissingPluginException {
      // FCM not available on this platform
    } catch (_) {}
    await onLogoutCallback?.call();
  }
}
