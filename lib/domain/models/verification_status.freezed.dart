// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$VerificationStatus {
  bool get photoVerified => throw _privateConstructorUsedError;
  bool get idVerified => throw _privateConstructorUsedError;
  bool get emailVerified => throw _privateConstructorUsedError;
  bool get phoneVerified => throw _privateConstructorUsedError;
  bool get linkedInVerified => throw _privateConstructorUsedError;
  bool get educationVerified => throw _privateConstructorUsedError;

  /// 0.0 to 1.0; derived or stored
  double get score => throw _privateConstructorUsedError;

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VerificationStatusCopyWith<VerificationStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VerificationStatusCopyWith<$Res> {
  factory $VerificationStatusCopyWith(
    VerificationStatus value,
    $Res Function(VerificationStatus) then,
  ) = _$VerificationStatusCopyWithImpl<$Res, VerificationStatus>;
  @useResult
  $Res call({
    bool photoVerified,
    bool idVerified,
    bool emailVerified,
    bool phoneVerified,
    bool linkedInVerified,
    bool educationVerified,
    double score,
  });
}

/// @nodoc
class _$VerificationStatusCopyWithImpl<$Res, $Val extends VerificationStatus>
    implements $VerificationStatusCopyWith<$Res> {
  _$VerificationStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? photoVerified = null,
    Object? idVerified = null,
    Object? emailVerified = null,
    Object? phoneVerified = null,
    Object? linkedInVerified = null,
    Object? educationVerified = null,
    Object? score = null,
  }) {
    return _then(
      _value.copyWith(
            photoVerified: null == photoVerified
                ? _value.photoVerified
                : photoVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            idVerified: null == idVerified
                ? _value.idVerified
                : idVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            emailVerified: null == emailVerified
                ? _value.emailVerified
                : emailVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            phoneVerified: null == phoneVerified
                ? _value.phoneVerified
                : phoneVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            linkedInVerified: null == linkedInVerified
                ? _value.linkedInVerified
                : linkedInVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            educationVerified: null == educationVerified
                ? _value.educationVerified
                : educationVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VerificationStatusImplCopyWith<$Res>
    implements $VerificationStatusCopyWith<$Res> {
  factory _$$VerificationStatusImplCopyWith(
    _$VerificationStatusImpl value,
    $Res Function(_$VerificationStatusImpl) then,
  ) = __$$VerificationStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool photoVerified,
    bool idVerified,
    bool emailVerified,
    bool phoneVerified,
    bool linkedInVerified,
    bool educationVerified,
    double score,
  });
}

/// @nodoc
class __$$VerificationStatusImplCopyWithImpl<$Res>
    extends _$VerificationStatusCopyWithImpl<$Res, _$VerificationStatusImpl>
    implements _$$VerificationStatusImplCopyWith<$Res> {
  __$$VerificationStatusImplCopyWithImpl(
    _$VerificationStatusImpl _value,
    $Res Function(_$VerificationStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? photoVerified = null,
    Object? idVerified = null,
    Object? emailVerified = null,
    Object? phoneVerified = null,
    Object? linkedInVerified = null,
    Object? educationVerified = null,
    Object? score = null,
  }) {
    return _then(
      _$VerificationStatusImpl(
        photoVerified: null == photoVerified
            ? _value.photoVerified
            : photoVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        idVerified: null == idVerified
            ? _value.idVerified
            : idVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        emailVerified: null == emailVerified
            ? _value.emailVerified
            : emailVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        phoneVerified: null == phoneVerified
            ? _value.phoneVerified
            : phoneVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        linkedInVerified: null == linkedInVerified
            ? _value.linkedInVerified
            : linkedInVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        educationVerified: null == educationVerified
            ? _value.educationVerified
            : educationVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$VerificationStatusImpl implements _VerificationStatus {
  const _$VerificationStatusImpl({
    this.photoVerified = false,
    this.idVerified = false,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.linkedInVerified = false,
    this.educationVerified = false,
    this.score = 0.0,
  });

  @override
  @JsonKey()
  final bool photoVerified;
  @override
  @JsonKey()
  final bool idVerified;
  @override
  @JsonKey()
  final bool emailVerified;
  @override
  @JsonKey()
  final bool phoneVerified;
  @override
  @JsonKey()
  final bool linkedInVerified;
  @override
  @JsonKey()
  final bool educationVerified;

  /// 0.0 to 1.0; derived or stored
  @override
  @JsonKey()
  final double score;

  @override
  String toString() {
    return 'VerificationStatus(photoVerified: $photoVerified, idVerified: $idVerified, emailVerified: $emailVerified, phoneVerified: $phoneVerified, linkedInVerified: $linkedInVerified, educationVerified: $educationVerified, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerificationStatusImpl &&
            (identical(other.photoVerified, photoVerified) ||
                other.photoVerified == photoVerified) &&
            (identical(other.idVerified, idVerified) ||
                other.idVerified == idVerified) &&
            (identical(other.emailVerified, emailVerified) ||
                other.emailVerified == emailVerified) &&
            (identical(other.phoneVerified, phoneVerified) ||
                other.phoneVerified == phoneVerified) &&
            (identical(other.linkedInVerified, linkedInVerified) ||
                other.linkedInVerified == linkedInVerified) &&
            (identical(other.educationVerified, educationVerified) ||
                other.educationVerified == educationVerified) &&
            (identical(other.score, score) || other.score == score));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    photoVerified,
    idVerified,
    emailVerified,
    phoneVerified,
    linkedInVerified,
    educationVerified,
    score,
  );

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VerificationStatusImplCopyWith<_$VerificationStatusImpl> get copyWith =>
      __$$VerificationStatusImplCopyWithImpl<_$VerificationStatusImpl>(
        this,
        _$identity,
      );
}

abstract class _VerificationStatus implements VerificationStatus {
  const factory _VerificationStatus({
    final bool photoVerified,
    final bool idVerified,
    final bool emailVerified,
    final bool phoneVerified,
    final bool linkedInVerified,
    final bool educationVerified,
    final double score,
  }) = _$VerificationStatusImpl;

  @override
  bool get photoVerified;
  @override
  bool get idVerified;
  @override
  bool get emailVerified;
  @override
  bool get phoneVerified;
  @override
  bool get linkedInVerified;
  @override
  bool get educationVerified;

  /// 0.0 to 1.0; derived or stored
  @override
  double get score;

  /// Create a copy of VerificationStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VerificationStatusImplCopyWith<_$VerificationStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
