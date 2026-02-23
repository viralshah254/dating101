import 'package:freezed_annotation/freezed_annotation.dart';

import 'family_details.dart';

part 'matrimony_extensions.freezed.dart';

/// Role creating/managing the profile (matrimony).
enum ProfileRole {
  self,
  parent,
  guardian,
  sibling,
  friend,
}

@freezed
class MatrimonyExtensions with _$MatrimonyExtensions {
  const factory MatrimonyExtensions({
    @Default(ProfileRole.self) ProfileRole roleManagingProfile,
    String? religion,
    String? casteOrCommunity,
    String? motherTongue,
    String? maritalStatus,
    int? heightCm,
    String? educationDegree,
    String? educationInstitution,
    String? occupation,
    String? employer,
    String? industry,
    IncomeRange? incomeRange,
    FamilyDetails? familyDetails,
    String? diet,
    String? drinking,
    String? smoking,
    HoroscopeDetails? horoscope,
  }) = _MatrimonyExtensions;
}

@freezed
class IncomeRange with _$IncomeRange {
  const factory IncomeRange({
    String? minLabel, // e.g. "5L"
    String? maxLabel,
    String? currency,
  }) = _IncomeRange;
}

@freezed
class HoroscopeDetails with _$HoroscopeDetails {
  const factory HoroscopeDetails({
    String? dateOfBirth,
    String? timeOfBirth,
    String? birthPlace,
    String? manglik,
    String? nakshatra,
    String? horoscopeDocUrl,
  }) = _HoroscopeDetails;
}
