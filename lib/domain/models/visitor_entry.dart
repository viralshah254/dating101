import 'profile_summary.dart';

/// A profile visit: who viewed my profile and when.
class VisitorEntry {
  const VisitorEntry({
    required this.visitId,
    required this.visitor,
    required this.visitedAt,
    this.source,
  });
  final String visitId;
  final ProfileSummary visitor;
  final DateTime visitedAt;
  final String? source;
}

/// Result of GET /visits/received.
class VisitorsResult {
  const VisitorsResult({
    required this.visitors,
    this.newCount = 0,
  });
  final List<VisitorEntry> visitors;
  final int newCount;
}
