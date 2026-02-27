import 'package:freezed_annotation/freezed_annotation.dart';

part 'family_details.freezed.dart';

@freezed
class FamilyDetails with _$FamilyDetails {
  const factory FamilyDetails({
    String? familyType, // nuclear / joint
    String? familyValues, // traditional / moderate / liberal
    String? familyLocation,
    String? familyBasedOutOfCountry,
    String? householdIncome,
    String? fatherOccupation,
    String? motherOccupation,
    String? fatherAge,
    String? motherAge,
    int? siblingsCount,
    int? siblingsMarried,
    String? brothers, // e.g. "None", "1", "2", "3", "4+"
    String? sisters,

    /// Optional; show "Family expectations" subsection when backend provides it.
    String? familyExpectations,
  }) = _FamilyDetails;
}
