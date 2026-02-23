// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discovery_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DiscoveryPreferences {
  int get ageMin => throw _privateConstructorUsedError;
  int get ageMax => throw _privateConstructorUsedError;
  double get maxDistanceKm => throw _privateConstructorUsedError;
  List<String>? get preferredCities => throw _privateConstructorUsedError;
  bool get travelModeEnabled => throw _privateConstructorUsedError;

  /// Create a copy of DiscoveryPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiscoveryPreferencesCopyWith<DiscoveryPreferences> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiscoveryPreferencesCopyWith<$Res> {
  factory $DiscoveryPreferencesCopyWith(
    DiscoveryPreferences value,
    $Res Function(DiscoveryPreferences) then,
  ) = _$DiscoveryPreferencesCopyWithImpl<$Res, DiscoveryPreferences>;
  @useResult
  $Res call({
    int ageMin,
    int ageMax,
    double maxDistanceKm,
    List<String>? preferredCities,
    bool travelModeEnabled,
  });
}

/// @nodoc
class _$DiscoveryPreferencesCopyWithImpl<
  $Res,
  $Val extends DiscoveryPreferences
>
    implements $DiscoveryPreferencesCopyWith<$Res> {
  _$DiscoveryPreferencesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiscoveryPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ageMin = null,
    Object? ageMax = null,
    Object? maxDistanceKm = null,
    Object? preferredCities = freezed,
    Object? travelModeEnabled = null,
  }) {
    return _then(
      _value.copyWith(
            ageMin: null == ageMin
                ? _value.ageMin
                : ageMin // ignore: cast_nullable_to_non_nullable
                      as int,
            ageMax: null == ageMax
                ? _value.ageMax
                : ageMax // ignore: cast_nullable_to_non_nullable
                      as int,
            maxDistanceKm: null == maxDistanceKm
                ? _value.maxDistanceKm
                : maxDistanceKm // ignore: cast_nullable_to_non_nullable
                      as double,
            preferredCities: freezed == preferredCities
                ? _value.preferredCities
                : preferredCities // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            travelModeEnabled: null == travelModeEnabled
                ? _value.travelModeEnabled
                : travelModeEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DiscoveryPreferencesImplCopyWith<$Res>
    implements $DiscoveryPreferencesCopyWith<$Res> {
  factory _$$DiscoveryPreferencesImplCopyWith(
    _$DiscoveryPreferencesImpl value,
    $Res Function(_$DiscoveryPreferencesImpl) then,
  ) = __$$DiscoveryPreferencesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int ageMin,
    int ageMax,
    double maxDistanceKm,
    List<String>? preferredCities,
    bool travelModeEnabled,
  });
}

/// @nodoc
class __$$DiscoveryPreferencesImplCopyWithImpl<$Res>
    extends _$DiscoveryPreferencesCopyWithImpl<$Res, _$DiscoveryPreferencesImpl>
    implements _$$DiscoveryPreferencesImplCopyWith<$Res> {
  __$$DiscoveryPreferencesImplCopyWithImpl(
    _$DiscoveryPreferencesImpl _value,
    $Res Function(_$DiscoveryPreferencesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DiscoveryPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ageMin = null,
    Object? ageMax = null,
    Object? maxDistanceKm = null,
    Object? preferredCities = freezed,
    Object? travelModeEnabled = null,
  }) {
    return _then(
      _$DiscoveryPreferencesImpl(
        ageMin: null == ageMin
            ? _value.ageMin
            : ageMin // ignore: cast_nullable_to_non_nullable
                  as int,
        ageMax: null == ageMax
            ? _value.ageMax
            : ageMax // ignore: cast_nullable_to_non_nullable
                  as int,
        maxDistanceKm: null == maxDistanceKm
            ? _value.maxDistanceKm
            : maxDistanceKm // ignore: cast_nullable_to_non_nullable
                  as double,
        preferredCities: freezed == preferredCities
            ? _value._preferredCities
            : preferredCities // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        travelModeEnabled: null == travelModeEnabled
            ? _value.travelModeEnabled
            : travelModeEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$DiscoveryPreferencesImpl implements _DiscoveryPreferences {
  const _$DiscoveryPreferencesImpl({
    this.ageMin = 18,
    this.ageMax = 99,
    this.maxDistanceKm = 50.0,
    final List<String>? preferredCities,
    this.travelModeEnabled = false,
  }) : _preferredCities = preferredCities;

  @override
  @JsonKey()
  final int ageMin;
  @override
  @JsonKey()
  final int ageMax;
  @override
  @JsonKey()
  final double maxDistanceKm;
  final List<String>? _preferredCities;
  @override
  List<String>? get preferredCities {
    final value = _preferredCities;
    if (value == null) return null;
    if (_preferredCities is EqualUnmodifiableListView) return _preferredCities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final bool travelModeEnabled;

  @override
  String toString() {
    return 'DiscoveryPreferences(ageMin: $ageMin, ageMax: $ageMax, maxDistanceKm: $maxDistanceKm, preferredCities: $preferredCities, travelModeEnabled: $travelModeEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiscoveryPreferencesImpl &&
            (identical(other.ageMin, ageMin) || other.ageMin == ageMin) &&
            (identical(other.ageMax, ageMax) || other.ageMax == ageMax) &&
            (identical(other.maxDistanceKm, maxDistanceKm) ||
                other.maxDistanceKm == maxDistanceKm) &&
            const DeepCollectionEquality().equals(
              other._preferredCities,
              _preferredCities,
            ) &&
            (identical(other.travelModeEnabled, travelModeEnabled) ||
                other.travelModeEnabled == travelModeEnabled));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    ageMin,
    ageMax,
    maxDistanceKm,
    const DeepCollectionEquality().hash(_preferredCities),
    travelModeEnabled,
  );

  /// Create a copy of DiscoveryPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiscoveryPreferencesImplCopyWith<_$DiscoveryPreferencesImpl>
  get copyWith =>
      __$$DiscoveryPreferencesImplCopyWithImpl<_$DiscoveryPreferencesImpl>(
        this,
        _$identity,
      );
}

abstract class _DiscoveryPreferences implements DiscoveryPreferences {
  const factory _DiscoveryPreferences({
    final int ageMin,
    final int ageMax,
    final double maxDistanceKm,
    final List<String>? preferredCities,
    final bool travelModeEnabled,
  }) = _$DiscoveryPreferencesImpl;

  @override
  int get ageMin;
  @override
  int get ageMax;
  @override
  double get maxDistanceKm;
  @override
  List<String>? get preferredCities;
  @override
  bool get travelModeEnabled;

  /// Create a copy of DiscoveryPreferences
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiscoveryPreferencesImplCopyWith<_$DiscoveryPreferencesImpl>
  get copyWith => throw _privateConstructorUsedError;
}
