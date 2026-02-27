// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$FamilyDetails {
  String? get familyType =>
      throw _privateConstructorUsedError; // nuclear / joint
  String? get familyValues =>
      throw _privateConstructorUsedError; // traditional / moderate / liberal
  String? get familyLocation => throw _privateConstructorUsedError;
  String? get familyBasedOutOfCountry => throw _privateConstructorUsedError;
  String? get householdIncome => throw _privateConstructorUsedError;
  String? get fatherOccupation => throw _privateConstructorUsedError;
  String? get motherOccupation => throw _privateConstructorUsedError;
  String? get fatherAge => throw _privateConstructorUsedError;
  String? get motherAge => throw _privateConstructorUsedError;
  int? get siblingsCount => throw _privateConstructorUsedError;
  int? get siblingsMarried => throw _privateConstructorUsedError;
  String? get brothers =>
      throw _privateConstructorUsedError; // e.g. "None", "1", "2", "3", "4+"
  String? get sisters => throw _privateConstructorUsedError;

  /// Optional; show "Family expectations" subsection when backend provides it.
  String? get familyExpectations => throw _privateConstructorUsedError;

  /// Create a copy of FamilyDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FamilyDetailsCopyWith<FamilyDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyDetailsCopyWith<$Res> {
  factory $FamilyDetailsCopyWith(
    FamilyDetails value,
    $Res Function(FamilyDetails) then,
  ) = _$FamilyDetailsCopyWithImpl<$Res, FamilyDetails>;
  @useResult
  $Res call({
    String? familyType,
    String? familyValues,
    String? familyLocation,
    String? familyBasedOutOfCountry,
    String? householdIncome,
    String? fatherOccupation,
    String? motherOccupation,
    String? fatherAge,
    String? motherAge,
    int? siblingsCount,
    int? siblingsMarried,
    String? brothers,
    String? sisters,
    String? familyExpectations,
  });
}

/// @nodoc
class _$FamilyDetailsCopyWithImpl<$Res, $Val extends FamilyDetails>
    implements $FamilyDetailsCopyWith<$Res> {
  _$FamilyDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FamilyDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? familyType = freezed,
    Object? familyValues = freezed,
    Object? familyLocation = freezed,
    Object? familyBasedOutOfCountry = freezed,
    Object? householdIncome = freezed,
    Object? fatherOccupation = freezed,
    Object? motherOccupation = freezed,
    Object? fatherAge = freezed,
    Object? motherAge = freezed,
    Object? siblingsCount = freezed,
    Object? siblingsMarried = freezed,
    Object? brothers = freezed,
    Object? sisters = freezed,
    Object? familyExpectations = freezed,
  }) {
    return _then(
      _value.copyWith(
            familyType: freezed == familyType
                ? _value.familyType
                : familyType // ignore: cast_nullable_to_non_nullable
                      as String?,
            familyValues: freezed == familyValues
                ? _value.familyValues
                : familyValues // ignore: cast_nullable_to_non_nullable
                      as String?,
            familyLocation: freezed == familyLocation
                ? _value.familyLocation
                : familyLocation // ignore: cast_nullable_to_non_nullable
                      as String?,
            familyBasedOutOfCountry: freezed == familyBasedOutOfCountry
                ? _value.familyBasedOutOfCountry
                : familyBasedOutOfCountry // ignore: cast_nullable_to_non_nullable
                      as String?,
            householdIncome: freezed == householdIncome
                ? _value.householdIncome
                : householdIncome // ignore: cast_nullable_to_non_nullable
                      as String?,
            fatherOccupation: freezed == fatherOccupation
                ? _value.fatherOccupation
                : fatherOccupation // ignore: cast_nullable_to_non_nullable
                      as String?,
            motherOccupation: freezed == motherOccupation
                ? _value.motherOccupation
                : motherOccupation // ignore: cast_nullable_to_non_nullable
                      as String?,
            fatherAge: freezed == fatherAge
                ? _value.fatherAge
                : fatherAge // ignore: cast_nullable_to_non_nullable
                      as String?,
            motherAge: freezed == motherAge
                ? _value.motherAge
                : motherAge // ignore: cast_nullable_to_non_nullable
                      as String?,
            siblingsCount: freezed == siblingsCount
                ? _value.siblingsCount
                : siblingsCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            siblingsMarried: freezed == siblingsMarried
                ? _value.siblingsMarried
                : siblingsMarried // ignore: cast_nullable_to_non_nullable
                      as int?,
            brothers: freezed == brothers
                ? _value.brothers
                : brothers // ignore: cast_nullable_to_non_nullable
                      as String?,
            sisters: freezed == sisters
                ? _value.sisters
                : sisters // ignore: cast_nullable_to_non_nullable
                      as String?,
            familyExpectations: freezed == familyExpectations
                ? _value.familyExpectations
                : familyExpectations // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FamilyDetailsImplCopyWith<$Res>
    implements $FamilyDetailsCopyWith<$Res> {
  factory _$$FamilyDetailsImplCopyWith(
    _$FamilyDetailsImpl value,
    $Res Function(_$FamilyDetailsImpl) then,
  ) = __$$FamilyDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? familyType,
    String? familyValues,
    String? familyLocation,
    String? familyBasedOutOfCountry,
    String? householdIncome,
    String? fatherOccupation,
    String? motherOccupation,
    String? fatherAge,
    String? motherAge,
    int? siblingsCount,
    int? siblingsMarried,
    String? brothers,
    String? sisters,
    String? familyExpectations,
  });
}

/// @nodoc
class __$$FamilyDetailsImplCopyWithImpl<$Res>
    extends _$FamilyDetailsCopyWithImpl<$Res, _$FamilyDetailsImpl>
    implements _$$FamilyDetailsImplCopyWith<$Res> {
  __$$FamilyDetailsImplCopyWithImpl(
    _$FamilyDetailsImpl _value,
    $Res Function(_$FamilyDetailsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FamilyDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? familyType = freezed,
    Object? familyValues = freezed,
    Object? familyLocation = freezed,
    Object? familyBasedOutOfCountry = freezed,
    Object? householdIncome = freezed,
    Object? fatherOccupation = freezed,
    Object? motherOccupation = freezed,
    Object? fatherAge = freezed,
    Object? motherAge = freezed,
    Object? siblingsCount = freezed,
    Object? siblingsMarried = freezed,
    Object? brothers = freezed,
    Object? sisters = freezed,
    Object? familyExpectations = freezed,
  }) {
    return _then(
      _$FamilyDetailsImpl(
        familyType: freezed == familyType
            ? _value.familyType
            : familyType // ignore: cast_nullable_to_non_nullable
                  as String?,
        familyValues: freezed == familyValues
            ? _value.familyValues
            : familyValues // ignore: cast_nullable_to_non_nullable
                  as String?,
        familyLocation: freezed == familyLocation
            ? _value.familyLocation
            : familyLocation // ignore: cast_nullable_to_non_nullable
                  as String?,
        familyBasedOutOfCountry: freezed == familyBasedOutOfCountry
            ? _value.familyBasedOutOfCountry
            : familyBasedOutOfCountry // ignore: cast_nullable_to_non_nullable
                  as String?,
        householdIncome: freezed == householdIncome
            ? _value.householdIncome
            : householdIncome // ignore: cast_nullable_to_non_nullable
                  as String?,
        fatherOccupation: freezed == fatherOccupation
            ? _value.fatherOccupation
            : fatherOccupation // ignore: cast_nullable_to_non_nullable
                  as String?,
        motherOccupation: freezed == motherOccupation
            ? _value.motherOccupation
            : motherOccupation // ignore: cast_nullable_to_non_nullable
                  as String?,
        fatherAge: freezed == fatherAge
            ? _value.fatherAge
            : fatherAge // ignore: cast_nullable_to_non_nullable
                  as String?,
        motherAge: freezed == motherAge
            ? _value.motherAge
            : motherAge // ignore: cast_nullable_to_non_nullable
                  as String?,
        siblingsCount: freezed == siblingsCount
            ? _value.siblingsCount
            : siblingsCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        siblingsMarried: freezed == siblingsMarried
            ? _value.siblingsMarried
            : siblingsMarried // ignore: cast_nullable_to_non_nullable
                  as int?,
        brothers: freezed == brothers
            ? _value.brothers
            : brothers // ignore: cast_nullable_to_non_nullable
                  as String?,
        sisters: freezed == sisters
            ? _value.sisters
            : sisters // ignore: cast_nullable_to_non_nullable
                  as String?,
        familyExpectations: freezed == familyExpectations
            ? _value.familyExpectations
            : familyExpectations // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$FamilyDetailsImpl implements _FamilyDetails {
  const _$FamilyDetailsImpl({
    this.familyType,
    this.familyValues,
    this.familyLocation,
    this.familyBasedOutOfCountry,
    this.householdIncome,
    this.fatherOccupation,
    this.motherOccupation,
    this.fatherAge,
    this.motherAge,
    this.siblingsCount,
    this.siblingsMarried,
    this.brothers,
    this.sisters,
    this.familyExpectations,
  });

  @override
  final String? familyType;
  // nuclear / joint
  @override
  final String? familyValues;
  // traditional / moderate / liberal
  @override
  final String? familyLocation;
  @override
  final String? familyBasedOutOfCountry;
  @override
  final String? householdIncome;
  @override
  final String? fatherOccupation;
  @override
  final String? motherOccupation;
  @override
  final String? fatherAge;
  @override
  final String? motherAge;
  @override
  final int? siblingsCount;
  @override
  final int? siblingsMarried;
  @override
  final String? brothers;
  // e.g. "None", "1", "2", "3", "4+"
  @override
  final String? sisters;

  /// Optional; show "Family expectations" subsection when backend provides it.
  @override
  final String? familyExpectations;

  @override
  String toString() {
    return 'FamilyDetails(familyType: $familyType, familyValues: $familyValues, familyLocation: $familyLocation, familyBasedOutOfCountry: $familyBasedOutOfCountry, householdIncome: $householdIncome, fatherOccupation: $fatherOccupation, motherOccupation: $motherOccupation, fatherAge: $fatherAge, motherAge: $motherAge, siblingsCount: $siblingsCount, siblingsMarried: $siblingsMarried, brothers: $brothers, sisters: $sisters, familyExpectations: $familyExpectations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyDetailsImpl &&
            (identical(other.familyType, familyType) ||
                other.familyType == familyType) &&
            (identical(other.familyValues, familyValues) ||
                other.familyValues == familyValues) &&
            (identical(other.familyLocation, familyLocation) ||
                other.familyLocation == familyLocation) &&
            (identical(
                  other.familyBasedOutOfCountry,
                  familyBasedOutOfCountry,
                ) ||
                other.familyBasedOutOfCountry == familyBasedOutOfCountry) &&
            (identical(other.householdIncome, householdIncome) ||
                other.householdIncome == householdIncome) &&
            (identical(other.fatherOccupation, fatherOccupation) ||
                other.fatherOccupation == fatherOccupation) &&
            (identical(other.motherOccupation, motherOccupation) ||
                other.motherOccupation == motherOccupation) &&
            (identical(other.fatherAge, fatherAge) ||
                other.fatherAge == fatherAge) &&
            (identical(other.motherAge, motherAge) ||
                other.motherAge == motherAge) &&
            (identical(other.siblingsCount, siblingsCount) ||
                other.siblingsCount == siblingsCount) &&
            (identical(other.siblingsMarried, siblingsMarried) ||
                other.siblingsMarried == siblingsMarried) &&
            (identical(other.brothers, brothers) ||
                other.brothers == brothers) &&
            (identical(other.sisters, sisters) || other.sisters == sisters) &&
            (identical(other.familyExpectations, familyExpectations) ||
                other.familyExpectations == familyExpectations));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    familyType,
    familyValues,
    familyLocation,
    familyBasedOutOfCountry,
    householdIncome,
    fatherOccupation,
    motherOccupation,
    fatherAge,
    motherAge,
    siblingsCount,
    siblingsMarried,
    brothers,
    sisters,
    familyExpectations,
  );

  /// Create a copy of FamilyDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyDetailsImplCopyWith<_$FamilyDetailsImpl> get copyWith =>
      __$$FamilyDetailsImplCopyWithImpl<_$FamilyDetailsImpl>(this, _$identity);
}

abstract class _FamilyDetails implements FamilyDetails {
  const factory _FamilyDetails({
    final String? familyType,
    final String? familyValues,
    final String? familyLocation,
    final String? familyBasedOutOfCountry,
    final String? householdIncome,
    final String? fatherOccupation,
    final String? motherOccupation,
    final String? fatherAge,
    final String? motherAge,
    final int? siblingsCount,
    final int? siblingsMarried,
    final String? brothers,
    final String? sisters,
    final String? familyExpectations,
  }) = _$FamilyDetailsImpl;

  @override
  String? get familyType; // nuclear / joint
  @override
  String? get familyValues; // traditional / moderate / liberal
  @override
  String? get familyLocation;
  @override
  String? get familyBasedOutOfCountry;
  @override
  String? get householdIncome;
  @override
  String? get fatherOccupation;
  @override
  String? get motherOccupation;
  @override
  String? get fatherAge;
  @override
  String? get motherAge;
  @override
  int? get siblingsCount;
  @override
  int? get siblingsMarried;
  @override
  String? get brothers; // e.g. "None", "1", "2", "3", "4+"
  @override
  String? get sisters;

  /// Optional; show "Family expectations" subsection when backend provides it.
  @override
  String? get familyExpectations;

  /// Create a copy of FamilyDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FamilyDetailsImplCopyWith<_$FamilyDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
