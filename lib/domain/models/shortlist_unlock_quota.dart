import 'who_shortlisted_me_entry.dart';

/// Result of unlocking one "who shortlisted you" entry (after watch-ad). Backend enforces 5/week.
class ShortlistUnlockResult {
  const ShortlistUnlockResult({
    required this.entry,
    this.unlocksRemainingThisWeek = 0,
    this.resetsAt,
  });
  final WhoShortlistedMeEntry entry;
  final int unlocksRemainingThisWeek;
  final DateTime? resetsAt;
}
