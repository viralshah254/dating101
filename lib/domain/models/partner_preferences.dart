import 'package:freezed_annotation/freezed_annotation.dart';

part 'partner_preferences.freezed.dart';

/// Matrimony: what the user is looking for in a partner.
@freezed
class PartnerPreferences with _$PartnerPreferences {
  const factory PartnerPreferences({
    String? genderPreference,
    @Default(21) int ageMin,
    @Default(45) int ageMax,
    int? heightMinCm,
    int? heightMaxCm,
    List<String>? preferredLocations,
    List<String>? preferredReligions,
    List<String>? preferredCommunities,
    List<String>? preferredMotherTongues,
    String? educationPreference,
    String? occupationPreference,
    List<String>? maritalStatusPreference,
    String? dietPreference,
    String? incomePreference,
    String? drinkingPreference,
    String? smokingPreference,
    String? settledAbroadPreference,
    List<String>? preferredCountries,
    String? cityPreferenceMode,
    double? distanceMaxKm,
    bool? horoscopeMatchPreferred,
  }) = _PartnerPreferences;
}
