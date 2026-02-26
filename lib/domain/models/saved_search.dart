/// A saved search: named filters the user can re-run; optional new-match count for badge.
class SavedSearch {
  const SavedSearch({
    required this.id,
    this.name,
    required this.filters,
    this.createdAt,
    this.notifyOnNewMatch = true,
    this.newMatchCount = 0,
  });

  final String id;
  final String? name;
  final Map<String, dynamic> filters;
  final DateTime? createdAt;
  final bool notifyOnNewMatch;
  final int newMatchCount;

  /// Display label: name if set, else short summary from filters (e.g. "Bangalore, 28–35").
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    final parts = <String>[];
    if (filters['city'] != null && (filters['city'] as String).isNotEmpty) {
      parts.add(filters['city'] as String);
    }
    final ageMin = filters['ageMin'];
    final ageMax = filters['ageMax'];
    if (ageMin != null || ageMax != null) {
      parts.add('${ageMin ?? '?'}–${ageMax ?? '?'}');
    }
    if (parts.isEmpty) return 'Saved search';
    return parts.join(', ');
  }
}
