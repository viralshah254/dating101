import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
/// - Handles incoming messages and navigates when user taps
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
  /// Pass a function that calls GoRouter.of(context).go(path) or context.go(path).
  void setOnNotificationTap(void Function(String path) onTap);

  /// Clean up on logout (e.g. delete token on backend if supported).
  Future<void> onLogout();
}

/// Payload keys the backend sends in FCM data (see docs/BACKEND_PUSH_NOTIFICATIONS.md).
class NotificationPayload {
  static const type = 'type';
  static const screen = 'screen';
  static const threadId = 'threadId';
  static const otherUserId = 'otherUserId';
  static const profileId = 'profileId';
  static const interactionId = 'interactionId';
  static const matchId = 'matchId';
}

/// Builds deep link path from FCM data map. Matches app routes in app_router.dart.
String? notificationDataToPath(Map<String, dynamic>? data) {
  if (data == null || data.isEmpty) return null;
  final type = data[NotificationPayload.type] as String?;
  final screen = data[NotificationPayload.screen] as String?;
  final threadId = data[NotificationPayload.threadId] as String?;
  final otherUserId = data[NotificationPayload.otherUserId] as String?;
  final profileId = data[NotificationPayload.profileId] as String?;
  final matchId = data[NotificationPayload.matchId] as String?;

  // Prefer explicit screen route
  if (screen != null && screen.isNotEmpty) {
    switch (screen) {
      case 'requests':
        return '/requests';
      case 'chats':
        return '/chats';
      case 'matches':
        return '/'; // Home tab has matches
      case 'visitors':
        return '/community';
      case 'profile_settings':
        return '/profile-settings';
    }
  }

  // Route by type
  switch (type) {
    case 'new_message':
    case 'message':
      if (threadId != null && threadId.isNotEmpty) {
        final q = otherUserId != null ? '?otherUserId=${Uri.encodeComponent(otherUserId)}' : '';
        return '/chat/$threadId$q';
      }
      return '/chats';
    case 'mutual_match':
    case 'interest_accepted':
      if (matchId != null && matchId.isNotEmpty) return '/'; // Matches tab
      if (profileId != null) return '/profile/$profileId';
      return '/';
    case 'interest_received':
    case 'priority_interest_received':
      return '/requests';
    case 'interest_declined':
      return '/';
    case 'profile_visited':
      return '/community'; // Visitors tab
    case 'contact_request_accepted':
      if (profileId != null && profileId.isNotEmpty) return '/profile/$profileId';
      return '/';
    case 'contact_request_declined':
      return '/';
    default:
      return '/';
  }
}

/// Default implementation using Firebase Messaging.
class FirebaseNotificationService extends NotificationService {
  FirebaseNotificationService({
    required this.onRegisterToken,
    this.onLogoutCallback,
  });

  final Future<void> Function(String token) onRegisterToken;
  final Future<void> Function()? onLogoutCallback;

  void Function(String path)? _onNotificationTap;
  bool _initialized = false;

  @override
  void setOnNotificationTap(void Function(String path) onTap) {
    _onNotificationTap = onTap;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      // Background/terminated: handle when user taps notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Foreground: show in-app or let OS show (we don't show custom UI here)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      });

      // Initial message (app opened from terminated state via notification)
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _navigateFromData(initial.data);

      // Re-register when FCM token changes (e.g. reinstall, app data cleared)
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
    final path = notificationDataToPath(data);
    if (path != null && _onNotificationTap != null) {
      _onNotificationTap!(path);
    }
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
      final permission = await FirebaseMessaging.instance.getNotificationSettings();
      if (permission.authorizationStatus == AuthorizationStatus.denied) return null;
      if (permission.authorizationStatus == AuthorizationStatus.notDetermined) {
        final granted = await requestPermission();
        if (granted.authorizationStatus != AuthorizationStatus.authorized &&
            granted.authorizationStatus != AuthorizationStatus.provisional) {
          return null;
        }
      }
      return await FirebaseMessaging.instance.getToken();
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
