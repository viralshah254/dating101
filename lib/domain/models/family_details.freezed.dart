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
  String? get fatherOccupation => throw _privateConstructorUsedError;
  String? get motherOccupation => throw _privateConstructorUsedError;
  int? get siblingsCount => throw _privateConstructorUsedError;
  int? get siblingsMarried => throw _privateConstructorUsedError;

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
    String? fatherOccupation,
    String? motherOccupation,
    int? siblingsCount,
    int? siblingsMarried,
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
    Object? fatherOccupation = freezed,
    Object? motherOccupation = freezed,
    Object? siblingsCount = freezed,
    Object? siblingsMarried = freezed,
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
            fatherOccupation: freezed == fatherOccupation
                ? _value.fatherOccupation
                : fatherOccupation // ignore: cast_nullable_to_non_nullable
                      as String?,
            motherOccupation: freezed == motherOccupation
                ? _value.motherOccupation
                : motherOccupation // ignore: cast_nullable_to_non_nullable
                      as String?,
            siblingsCount: freezed == siblingsCount
                ? _value.siblingsCount
                : siblingsCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            siblingsMarried: freezed == siblingsMarried
                ? _value.siblingsMarried
                : siblingsMarried // ignore: cast_nullable_to_non_nullable
                      as int?,
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
    String? fatherOccupation,
    String? motherOccupation,
    int? siblingsCount,
    int? siblingsMarried,
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
    Object? fatherOccupation = freezed,
    Object? motherOccupation = freezed,
    Object? siblingsCount = freezed,
    Object? siblingsMarried = freezed,
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
        fatherOccupation: freezed == fatherOccupation
            ? _value.fatherOccupation
            : fatherOccupation // ignore: cast_nullable_to_non_nullable
                  as String?,
        motherOccupation: freezed == motherOccupation
            ? _value.motherOccupation
            : motherOccupation // ignore: cast_nullable_to_non_nullable
                  as String?,
        siblingsCount: freezed == siblingsCount
            ? _value.siblingsCount
            : siblingsCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        siblingsMarried: freezed == siblingsMarried
            ? _value.siblingsMarried
            : siblingsMarried // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$FamilyDetailsImpl implements _FamilyDetails {
  const _$FamilyDetailsImpl({
    this.familyType,
    this.familyValues,
    this.fatherOccupation,
    this.motherOccupation,
    this.siblingsCount,
    this.siblingsMarried,
  });

  @override
  final String? familyType;
  // nuclear / joint
  @override
  final String? familyValues;
  // traditional / moderate / liberal
  @override
  final String? fatherOccupation;
  @override
  final String? motherOccupation;
  @override
  final int? siblingsCount;
  @override
  final int? siblingsMarried;

  @override
  String toString() {
    return 'FamilyDetails(familyType: $familyType, familyValues: $familyValues, fatherOccupation: $fatherOccupation, motherOccupation: $motherOccupation, siblingsCount: $siblingsCount, siblingsMarried: $siblingsMarried)';
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
            (identical(other.fatherOccupation, fatherOccupation) ||
                other.fatherOccupation == fatherOccupation) &&
            (identical(other.motherOccupation, motherOccupation) ||
                other.motherOccupation == motherOccupation) &&
            (identical(other.siblingsCount, siblingsCount) ||
                other.siblingsCount == siblingsCount) &&
            (identical(other.siblingsMarried, siblingsMarried) ||
                other.siblingsMarried == siblingsMarried));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    familyType,
    familyValues,
    fatherOccupation,
    motherOccupation,
    siblingsCount,
    siblingsMarried,
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
    final String? fatherOccupation,
    final String? motherOccupation,
    final int? siblingsCount,
    final int? siblingsMarried,
  }) = _$FamilyDetailsImpl;

  @override
  String? get familyType; // nuclear / joint
  @override
  String? get familyValues; // traditional / moderate / liberal
  @override
  String? get fatherOccupation;
  @override
  String? get motherOccupation;
  @override
  int? get siblingsCount;
  @override
  int? get siblingsMarried;

  /// Create a copy of FamilyDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FamilyDetailsImplCopyWith<_$FamilyDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
