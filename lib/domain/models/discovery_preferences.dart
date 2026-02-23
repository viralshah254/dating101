import 'package:freezed_annotation/freezed_annotation.dart';

part 'discovery_preferences.freezed.dart';

/// Dating: age range, distance, and other discovery filters.
@freezed
class DiscoveryPreferences with _$DiscoveryPreferences {
  const factory DiscoveryPreferences({
    @Default(18) int ageMin,
    @Default(99) int ageMax,
    @Default(50.0) double maxDistanceKm,
    List<String>? preferredCities,
    @Default(false) bool travelModeEnabled,
  }) = _DiscoveryPreferences;
}
