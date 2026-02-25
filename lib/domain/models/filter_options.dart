/// Options and defaults for Explore tab filters (GET /discovery/filter-options).
class FilterOptions {
  const FilterOptions({
    required this.age,
    required this.cities,
    required this.religions,
    required this.education,
    this.height,
    this.diet,
    this.maritalStatus,
  });

  final FilterAgeRange age;
  final FilterDimension cities;
  final FilterDimension religions;
  final FilterDimension education;
  final FilterHeightRange? height;
  final FilterDimension? diet;
  final FilterDimension? maritalStatus;
}

class FilterAgeRange {
  const FilterAgeRange({
    required this.min,
    required this.max,
    required this.defaultMin,
    required this.defaultMax,
    required this.strict,
  });
  final int min;
  final int max;
  final int defaultMin;
  final int defaultMax;
  final bool strict;
}

class FilterDimension {
  const FilterDimension({
    required this.options,
    required this.strict,
    this.defaultSelected,
  });
  final List<String> options;
  final bool strict;
  final String? defaultSelected;
}

class FilterHeightRange {
  const FilterHeightRange({
    required this.minCm,
    required this.maxCm,
    this.defaultMinCm,
    this.defaultMaxCm,
    required this.strict,
  });
  final int minCm;
  final int maxCm;
  final int? defaultMinCm;
  final int? defaultMaxCm;
  final bool strict;
}
