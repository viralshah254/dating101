// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dating_extensions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DatingExtensions {
  String? get datingIntent =>
      throw _privateConstructorUsedError; // serious / casual / marriage / friends first / etc.
  List<PromptAnswer>? get prompts => throw _privateConstructorUsedError;
  String? get voiceIntroUrl => throw _privateConstructorUsedError;
  bool get travelModeEnabled => throw _privateConstructorUsedError;
  DiscoveryPreferences? get discoveryPreferences =>
      throw _privateConstructorUsedError;

  /// Create a copy of DatingExtensions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DatingExtensionsCopyWith<DatingExtensions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DatingExtensionsCopyWith<$Res> {
  factory $DatingExtensionsCopyWith(
    DatingExtensions value,
    $Res Function(DatingExtensions) then,
  ) = _$DatingExtensionsCopyWithImpl<$Res, DatingExtensions>;
  @useResult
  $Res call({
    String? datingIntent,
    List<PromptAnswer>? prompts,
    String? voiceIntroUrl,
    bool travelModeEnabled,
    DiscoveryPreferences? discoveryPreferences,
  });

  $DiscoveryPreferencesCopyWith<$Res>? get discoveryPreferences;
}

/// @nodoc
class _$DatingExtensionsCopyWithImpl<$Res, $Val extends DatingExtensions>
    implements $DatingExtensionsCopyWith<$Res> {
  _$DatingExtensionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DatingExtensions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? datingIntent = freezed,
    Object? prompts = freezed,
    Object? voiceIntroUrl = freezed,
    Object? travelModeEnabled = null,
    Object? discoveryPreferences = freezed,
  }) {
    return _then(
      _value.copyWith(
            datingIntent: freezed == datingIntent
                ? _value.datingIntent
                : datingIntent // ignore: cast_nullable_to_non_nullable
                      as String?,
            prompts: freezed == prompts
                ? _value.prompts
                : prompts // ignore: cast_nullable_to_non_nullable
                      as List<PromptAnswer>?,
            voiceIntroUrl: freezed == voiceIntroUrl
                ? _value.voiceIntroUrl
                : voiceIntroUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            travelModeEnabled: null == travelModeEnabled
                ? _value.travelModeEnabled
                : travelModeEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            discoveryPreferences: freezed == discoveryPreferences
                ? _value.discoveryPreferences
                : discoveryPreferences // ignore: cast_nullable_to_non_nullable
                      as DiscoveryPreferences?,
          )
          as $Val,
    );
  }

  /// Create a copy of DatingExtensions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DiscoveryPreferencesCopyWith<$Res>? get discoveryPreferences {
    if (_value.discoveryPreferences == null) {
      return null;
    }

    return $DiscoveryPreferencesCopyWith<$Res>(_value.discoveryPreferences!, (
      value,
    ) {
      return _then(_value.copyWith(discoveryPreferences: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DatingExtensionsImplCopyWith<$Res>
    implements $DatingExtensionsCopyWith<$Res> {
  factory _$$DatingExtensionsImplCopyWith(
    _$DatingExtensionsImpl value,
    $Res Function(_$DatingExtensionsImpl) then,
  ) = __$$DatingExtensionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? datingIntent,
    List<PromptAnswer>? prompts,
    String? voiceIntroUrl,
    bool travelModeEnabled,
    DiscoveryPreferences? discoveryPreferences,
  });

  @override
  $DiscoveryPreferencesCopyWith<$Res>? get discoveryPreferences;
}

/// @nodoc
class __$$DatingExtensionsImplCopyWithImpl<$Res>
    extends _$DatingExtensionsCopyWithImpl<$Res, _$DatingExtensionsImpl>
    implements _$$DatingExtensionsImplCopyWith<$Res> {
  __$$DatingExtensionsImplCopyWithImpl(
    _$DatingExtensionsImpl _value,
    $Res Function(_$DatingExtensionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DatingExtensions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? datingIntent = freezed,
    Object? prompts = freezed,
    Object? voiceIntroUrl = freezed,
    Object? travelModeEnabled = null,
    Object? discoveryPreferences = freezed,
  }) {
    return _then(
      _$DatingExtensionsImpl(
        datingIntent: freezed == datingIntent
            ? _value.datingIntent
            : datingIntent // ignore: cast_nullable_to_non_nullable
                  as String?,
        prompts: freezed == prompts
            ? _value._prompts
            : prompts // ignore: cast_nullable_to_non_nullable
                  as List<PromptAnswer>?,
        voiceIntroUrl: freezed == voiceIntroUrl
            ? _value.voiceIntroUrl
            : voiceIntroUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        travelModeEnabled: null == travelModeEnabled
            ? _value.travelModeEnabled
            : travelModeEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        discoveryPreferences: freezed == discoveryPreferences
            ? _value.discoveryPreferences
            : discoveryPreferences // ignore: cast_nullable_to_non_nullable
                  as DiscoveryPreferences?,
      ),
    );
  }
}

/// @nodoc

class _$DatingExtensionsImpl implements _DatingExtensions {
  const _$DatingExtensionsImpl({
    this.datingIntent,
    final List<PromptAnswer>? prompts,
    this.voiceIntroUrl,
    this.travelModeEnabled = false,
    this.discoveryPreferences,
  }) : _prompts = prompts;

  @override
  final String? datingIntent;
  // serious / casual / marriage / friends first / etc.
  final List<PromptAnswer>? _prompts;
  // serious / casual / marriage / friends first / etc.
  @override
  List<PromptAnswer>? get prompts {
    final value = _prompts;
    if (value == null) return null;
    if (_prompts is EqualUnmodifiableListView) return _prompts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? voiceIntroUrl;
  @override
  @JsonKey()
  final bool travelModeEnabled;
  @override
  final DiscoveryPreferences? discoveryPreferences;

  @override
  String toString() {
    return 'DatingExtensions(datingIntent: $datingIntent, prompts: $prompts, voiceIntroUrl: $voiceIntroUrl, travelModeEnabled: $travelModeEnabled, discoveryPreferences: $discoveryPreferences)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DatingExtensionsImpl &&
            (identical(other.datingIntent, datingIntent) ||
                other.datingIntent == datingIntent) &&
            const DeepCollectionEquality().equals(other._prompts, _prompts) &&
            (identical(other.voiceIntroUrl, voiceIntroUrl) ||
                other.voiceIntroUrl == voiceIntroUrl) &&
            (identical(other.travelModeEnabled, travelModeEnabled) ||
                other.travelModeEnabled == travelModeEnabled) &&
            (identical(other.discoveryPreferences, discoveryPreferences) ||
                other.discoveryPreferences == discoveryPreferences));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    datingIntent,
    const DeepCollectionEquality().hash(_prompts),
    voiceIntroUrl,
    travelModeEnabled,
    discoveryPreferences,
  );

  /// Create a copy of DatingExtensions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DatingExtensionsImplCopyWith<_$DatingExtensionsImpl> get copyWith =>
      __$$DatingExtensionsImplCopyWithImpl<_$DatingExtensionsImpl>(
        this,
        _$identity,
      );
}

abstract class _DatingExtensions implements DatingExtensions {
  const factory _DatingExtensions({
    final String? datingIntent,
    final List<PromptAnswer>? prompts,
    final String? voiceIntroUrl,
    final bool travelModeEnabled,
    final DiscoveryPreferences? discoveryPreferences,
  }) = _$DatingExtensionsImpl;

  @override
  String? get datingIntent; // serious / casual / marriage / friends first / etc.
  @override
  List<PromptAnswer>? get prompts;
  @override
  String? get voiceIntroUrl;
  @override
  bool get travelModeEnabled;
  @override
  DiscoveryPreferences? get discoveryPreferences;

  /// Create a copy of DatingExtensions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DatingExtensionsImplCopyWith<_$DatingExtensionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PromptAnswer {
  String get questionId => throw _privateConstructorUsedError;
  String get questionText => throw _privateConstructorUsedError;
  String get answer => throw _privateConstructorUsedError;

  /// Create a copy of PromptAnswer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PromptAnswerCopyWith<PromptAnswer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PromptAnswerCopyWith<$Res> {
  factory $PromptAnswerCopyWith(
    PromptAnswer value,
    $Res Function(PromptAnswer) then,
  ) = _$PromptAnswerCopyWithImpl<$Res, PromptAnswer>;
  @useResult
  $Res call({String questionId, String questionText, String answer});
}

/// @nodoc
class _$PromptAnswerCopyWithImpl<$Res, $Val extends PromptAnswer>
    implements $PromptAnswerCopyWith<$Res> {
  _$PromptAnswerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PromptAnswer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questionId = null,
    Object? questionText = null,
    Object? answer = null,
  }) {
    return _then(
      _value.copyWith(
            questionId: null == questionId
                ? _value.questionId
                : questionId // ignore: cast_nullable_to_non_nullable
                      as String,
            questionText: null == questionText
                ? _value.questionText
                : questionText // ignore: cast_nullable_to_non_nullable
                      as String,
            answer: null == answer
                ? _value.answer
                : answer // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PromptAnswerImplCopyWith<$Res>
    implements $PromptAnswerCopyWith<$Res> {
  factory _$$PromptAnswerImplCopyWith(
    _$PromptAnswerImpl value,
    $Res Function(_$PromptAnswerImpl) then,
  ) = __$$PromptAnswerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String questionId, String questionText, String answer});
}

/// @nodoc
class __$$PromptAnswerImplCopyWithImpl<$Res>
    extends _$PromptAnswerCopyWithImpl<$Res, _$PromptAnswerImpl>
    implements _$$PromptAnswerImplCopyWith<$Res> {
  __$$PromptAnswerImplCopyWithImpl(
    _$PromptAnswerImpl _value,
    $Res Function(_$PromptAnswerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PromptAnswer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questionId = null,
    Object? questionText = null,
    Object? answer = null,
  }) {
    return _then(
      _$PromptAnswerImpl(
        questionId: null == questionId
            ? _value.questionId
            : questionId // ignore: cast_nullable_to_non_nullable
                  as String,
        questionText: null == questionText
            ? _value.questionText
            : questionText // ignore: cast_nullable_to_non_nullable
                  as String,
        answer: null == answer
            ? _value.answer
            : answer // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$PromptAnswerImpl implements _PromptAnswer {
  const _$PromptAnswerImpl({
    required this.questionId,
    required this.questionText,
    required this.answer,
  });

  @override
  final String questionId;
  @override
  final String questionText;
  @override
  final String answer;

  @override
  String toString() {
    return 'PromptAnswer(questionId: $questionId, questionText: $questionText, answer: $answer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PromptAnswerImpl &&
            (identical(other.questionId, questionId) ||
                other.questionId == questionId) &&
            (identical(other.questionText, questionText) ||
                other.questionText == questionText) &&
            (identical(other.answer, answer) || other.answer == answer));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, questionId, questionText, answer);

  /// Create a copy of PromptAnswer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PromptAnswerImplCopyWith<_$PromptAnswerImpl> get copyWith =>
      __$$PromptAnswerImplCopyWithImpl<_$PromptAnswerImpl>(this, _$identity);
}

abstract class _PromptAnswer implements PromptAnswer {
  const factory _PromptAnswer({
    required final String questionId,
    required final String questionText,
    required final String answer,
  }) = _$PromptAnswerImpl;

  @override
  String get questionId;
  @override
  String get questionText;
  @override
  String get answer;

  /// Create a copy of PromptAnswer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PromptAnswerImplCopyWith<_$PromptAnswerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
