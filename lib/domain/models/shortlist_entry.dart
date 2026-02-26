import 'profile_summary.dart';

/// One shortlist item: profile plus optional note and metadata.
class ShortlistEntry {
  const ShortlistEntry({
    required this.profile,
    this.note,
    this.shortlistId,
    this.createdAt,
  });

  final ProfileSummary profile;
  final String? note;
  final String? shortlistId;
  final DateTime? createdAt;
}
