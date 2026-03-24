import 'package:intl/intl.dart';

/// API / Neon timestamps are stored as UTC ISO-8601. Use this so all calendar
/// labels and "today / yesterday" logic match the user's device timezone.
DateTime toLocalWallClock(DateTime d) => d.isUtc ? d.toLocal() : d;

/// Parse server strings and normalize to local wall clock for display.
DateTime? parseApiDateTime(String? s) {
  if (s == null || s.isEmpty) return null;
  final p = DateTime.tryParse(s);
  return p == null ? null : toLocalWallClock(p);
}

String _ordinalDayEn(int day) {
  if (day >= 11 && day <= 13) return '${day}th';
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

/// e.g. 12th December 2025
String formatOrdinalFullDate(DateTime d) {
  final t = toLocalWallClock(d);
  return '${_ordinalDayEn(t.day)} ${DateFormat.MMMM().format(t)} ${t.year}';
}

/// Same calendar year omits the year (e.g. 12th December).
String formatOrdinalDate(DateTime d) {
  final t = toLocalWallClock(d);
  final now = DateTime.now();
  final monthDay = '${_ordinalDayEn(t.day)} ${DateFormat.MMMM().format(t)}';
  if (t.year != now.year) return '$monthDay ${t.year}';
  return monthDay;
}

bool isSameLocalDay(DateTime a, DateTime b) {
  final la = toLocalWallClock(a);
  final lb = toLocalWallClock(b);
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

/// Chat list row (right column): prefer other user's last activity, not last message time.
/// Falls back to [lastMessageAt] only when we have no online / last-active signal.
String? formatChatThreadListTrailingTime({
  required bool otherUserOnline,
  DateTime? otherLastActiveAt,
  DateTime? lastMessageAt,
}) {
  if (otherUserOnline) return 'Active now';
  if (otherLastActiveAt != null) {
    final rel = formatChatListTime(otherLastActiveAt);
    if (rel == null) return null;
    if (rel == 'Just now') return 'Seen just now';
    return 'Seen $rel';
  }
  return formatChatListTime(lastMessageAt);
}

/// Chat thread list (right-hand time): compact relative "ago", then ordinal date.
String? formatChatListTime(DateTime? d) {
  if (d == null) return null;
  final t = toLocalWallClock(d);
  final now = DateTime.now();
  var diff = now.difference(t);
  if (diff.isNegative) diff = Duration.zero;
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? '1 min ago' : '$m mins ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? '1 hr ago' : '$h hrs ago';
  }
  if (diff.inDays < 7) {
    final days = diff.inDays;
    return days == 1 ? '1 day ago' : '$days days ago';
  }
  return formatOrdinalDate(t);
}

/// Timestamp line under each chat bubble (local time).
String formatChatBubbleTime(DateTime d) {
  final t = toLocalWallClock(d);
  final now = DateTime.now();
  var diff = now.difference(t);
  if (diff.isNegative) diff = Duration.zero;
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? '1 min ago' : '$m mins ago';
  }
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(t.year, t.month, t.day);
  if (messageDay == today) {
    return DateFormat.jm().format(t);
  }
  final yesterday = today.subtract(const Duration(days: 1));
  if (messageDay == yesterday) {
    return 'Yesterday, ${DateFormat.jm().format(t)}';
  }
  if (diff.inDays < 7) {
    return DateFormat('EEE').add_jm().format(t);
  }
  return '${formatOrdinalDate(t)}, ${DateFormat.jm().format(t)}';
}

/// Center pill between message groups (Today / Yesterday / ordinal date).
String formatChatDateSeparator(DateTime sentAt) {
  final t = toLocalWallClock(sentAt);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(t.year, t.month, t.day);
  if (messageDay == today) return 'Today';
  if (messageDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
  if (t.year == now.year) {
    return '${_ordinalDayEn(t.day)} ${DateFormat.MMMM().format(t)}';
  }
  return formatOrdinalFullDate(t);
}

/// Chat header subtitle: online or last seen with "ago" / ordinal fallback.
String? formatProfileLastSeenSubtitle({required bool online, DateTime? lastActive}) {
  if (online) return 'Active now';
  if (lastActive == null) return null;
  final t = toLocalWallClock(lastActive);
  final now = DateTime.now();
  var diff = now.difference(t);
  if (diff.isNegative) diff = Duration.zero;
  if (diff.inSeconds < 60) return 'Last seen just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? 'Last seen 1 min ago' : 'Last seen $m mins ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? 'Last seen 1 hr ago' : 'Last seen $h hrs ago';
  }
  if (diff.inDays < 7) {
    final days = diff.inDays;
    return days == 1 ? 'Last seen 1 day ago' : 'Last seen $days days ago';
  }
  return 'Last seen ${formatOrdinalFullDate(t)}';
}
