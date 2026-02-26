import 'package:freezed_annotation/freezed_annotation.dart';

part 'family_details.freezed.dart';

@freezed
class FamilyDetails with _$FamilyDetails {
  const factory FamilyDetails({
    String? familyType, // nuclear / joint
    String? familyValues, // traditional / moderate / liberal
    String? fatherOccupation,
    String? motherOccupation,
    int? siblingsCount,
    int? siblingsMarried,
    /// Optional; show "Family expectations" subsection when backend provides it.
    String? familyExpectations,
  }) = _FamilyDetails;
}
