import '../mode/app_mode.dart';

/// Shell path for the **chat list** (threads). In matrimony the same index shows as `/likes`.
String chatListShellPath(AppMode appMode) {
  if (appMode == AppMode.dating) return '/chats';
  return '/likes';
}

/// Shell path for **shortlist** (matrimony). Dating has no shortlist tab — fall back to inbox.
String shortlistShellPath(AppMode appMode) {
  if (appMode == AppMode.dating) return '/notifications';
  return '/chats';
}

/// Dating **Likes** tab lives at `/likes`. In matrimony that path is the chat list (unused for visitors).
String likesShellPath(AppMode appMode) {
  if (appMode == AppMode.dating) return '/likes';
  return '/notifications';
}

/// Payload keys the backend sends in FCM `data` (see docs/BACKEND_PUSH_NOTIFICATIONS.md).
class NotificationPayload {
  static const type = 'type';
  static const screen = 'screen';
  static const threadId = 'threadId';
  static const otherUserId = 'otherUserId';
  static const profileId = 'profileId';
  static const interactionId = 'interactionId';
  static const matchId = 'matchId';
  static const threadMode = 'threadMode';
  static const messageRequestId = 'messageRequestId';
  static const verificationType = 'verificationType';
}

String? _str(Map<String, dynamic> data, String key) {
  final v = data[key];
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// Resolve the effective [AppMode] from a threadMode string in the FCM payload.
/// Falls back to [appMode] if the value is not recognized.
AppMode _resolveThreadMode(String? raw, AppMode fallback) {
  if (raw == 'dating') return AppMode.dating;
  if (raw == 'matrimony') return AppMode.matrimony;
  return fallback;
}

/// Builds a GoRouter path from FCM data. [appMode] must be the effective shell mode (dating vs matrimony/both).
String? notificationDataToPath(
  Map<String, dynamic>? data, {
  required AppMode appMode,
}) {
  if (data == null || data.isEmpty) return null;
  final type = _str(data, NotificationPayload.type);
  final screen = _str(data, NotificationPayload.screen);
  final threadId = _str(data, NotificationPayload.threadId);
  final otherUserId = _str(data, NotificationPayload.otherUserId);
  final profileId = _str(data, NotificationPayload.profileId);
  final matchId = _str(data, NotificationPayload.matchId);
  final rawThreadMode = _str(data, NotificationPayload.threadMode);

  // Derive mode from threadMode payload first, then fall back to current app shell mode.
  final effectiveMode = _resolveThreadMode(rawThreadMode, appMode);

  String chatPathWithOther({AppMode? mode}) {
    final m = mode ?? effectiveMode;
    if (threadId != null && threadId.isNotEmpty) {
      final params = <String>[];
      if (otherUserId != null && otherUserId.isNotEmpty) {
        params.add('otherUserId=${Uri.encodeComponent(otherUserId)}');
      }
      // Pass threadMode so the chat screen opens in the correct mode shell.
      if (rawThreadMode != null && rawThreadMode.isNotEmpty) {
        params.add('threadMode=${Uri.encodeComponent(rawThreadMode)}');
      }
      final q = params.isNotEmpty ? '?${params.join('&')}' : '';
      return '/chat/$threadId$q';
    }
    return chatListShellPath(m);
  }

  // `screen` hints take precedence (backend sets these for most types now).
  if (screen != null && screen.isNotEmpty) {
    switch (screen) {
      case 'requests':
        return '/requests';
      case 'chats':
        return chatListShellPath(effectiveMode);
      case 'matches':
        return '/';
      case 'visitors':
        return appMode == AppMode.dating ? '/likes?tab=visitors' : '/notifications';
      case 'likes':
        return '/likes?tab=you_liked';
      case 'profile_settings':
        return '/profile-settings';
      case 'notifications':
        return '/notifications';
      case 'shortlist':
        return shortlistShellPath(effectiveMode);
      case 'profile':
        if (profileId != null && profileId.isNotEmpty) return '/profile/$profileId';
        return '/notifications';
      case 'chat':
        return chatPathWithOther();
    }
  }

  switch (type) {
    case 'new_message':
    case 'message':
      return chatPathWithOther();
    case 'message_request':
      return '${chatListShellPath(effectiveMode)}?tab=requests';
    case 'message_request_accepted':
      return chatPathWithOther();
    case 'message_request_declined':
      return '${chatListShellPath(effectiveMode)}?tab=requests';
    case 'mutual_match':
    case 'interest_accepted':
      // Prefer opening the chat thread so users can start talking immediately.
      if (threadId != null && threadId.isNotEmpty) return chatPathWithOther();
      if (matchId != null && matchId.isNotEmpty) return '/';
      if (profileId != null) return '/profile/$profileId';
      return '/';
    case 'interest_received':
    case 'priority_interest_received':
      return '/requests';
    case 'interest_reminder':
      if (profileId != null && profileId.isNotEmpty) return '/profile/$profileId';
      return '/requests';
    case 'interest_reminder_prompt':
      return appMode == AppMode.dating ? '/likes?tab=you_liked' : shortlistShellPath(appMode);
    case 'interest_declined':
      return '/';
    case 'profile_visited':
      return likesShellPath(appMode) == '/likes' ? '/likes?tab=visitors' : '/notifications';
    case 'contact_request_accepted':
      if (profileId != null && profileId.isNotEmpty) return '/profile/$profileId';
      return '/';
    case 'contact_request_declined':
      return '/';
    case 'shortlisted_you':
      if (profileId != null && profileId.isNotEmpty) return '/profile/$profileId';
      return shortlistShellPath(appMode);
    case 'photo_view_request':
      return '/requests';
    case 'photo_view_accepted':
      if (profileId != null && profileId.isNotEmpty) return '/profile/$profileId';
      return '/requests';
    case 'photo_view_declined':
      return '/notifications';
    case 'morning_reminder':
    case 'inactive_reminder':
      return '/';
    // ── Admin / system notifications ────────────────────────────────────────
    case 'admin_message':
    case 'admin_warning':
      return '/notifications';
    // ── Verification ────────────────────────────────────────────────────────
    case 'verification_approved':
    case 'verification_rejected':
      // Route to profile settings where the user can see verification status
      // and re-submit if rejected.
      return '/profile-settings';
    default:
      return '/notifications';
  }
}
