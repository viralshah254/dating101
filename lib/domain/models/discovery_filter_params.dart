/// Selected filter values for discovery explore/search (from filters sheet).
class DiscoveryFilterParams {
  const DiscoveryFilterParams({
    this.ageMin,
    this.ageMax,
    this.city,
    this.religion,
    this.education,
    this.diet,
    this.heightMinCm,
    this.heightMaxCm,
    this.bodyType,
    this.maritalStatus,
  });

  final int? ageMin;
  final int? ageMax;
  final String? city;
  final String? religion;
  final String? education;
  final String? diet;
  final int? heightMinCm;
  final int? heightMaxCm;

  /// Preferred body type filter, e.g. "Slim", "Athletic".
  final String? bodyType;

  /// Preferred marital status, e.g. "Never married", "Divorced".
  final String? maritalStatus;

  bool get hasFilters =>
      ageMin != null ||
      ageMax != null ||
      (city != null && city!.isNotEmpty) ||
      (religion != null && religion!.isNotEmpty) ||
      (education != null && education!.isNotEmpty) ||
      (diet != null && diet!.isNotEmpty) ||
      heightMinCm != null ||
      heightMaxCm != null ||
      (bodyType != null && bodyType!.isNotEmpty) ||
      (maritalStatus != null && maritalStatus!.isNotEmpty);

  DiscoveryFilterParams copyWith({
    int? ageMin,
    int? ageMax,
    String? city,
    String? religion,
    String? education,
    String? diet,
    int? heightMinCm,
    int? heightMaxCm,
    String? bodyType,
    String? maritalStatus,
  }) {
    return DiscoveryFilterParams(
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      city: city ?? this.city,
      religion: religion ?? this.religion,
      education: education ?? this.education,
      diet: diet ?? this.diet,
      heightMinCm: heightMinCm ?? this.heightMinCm,
      heightMaxCm: heightMaxCm ?? this.heightMaxCm,
      bodyType: bodyType ?? this.bodyType,
      maritalStatus: maritalStatus ?? this.maritalStatus,
    );
  }
}
