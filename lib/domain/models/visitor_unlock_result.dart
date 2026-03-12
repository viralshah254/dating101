import 'profile_summary.dart';

/// Result of unlocking one visitor (after watch-ad). Backend enforces 2/week.
class VisitorUnlockResult {
  const VisitorUnlockResult({
    required this.visitId,
    required this.visitor,
    this.unlocksRemainingThisWeek = 0,
    this.resetsAt,
  });
  final String visitId;
  final ProfileSummary visitor;
  final int unlocksRemainingThisWeek;
  final DateTime? resetsAt;
}
