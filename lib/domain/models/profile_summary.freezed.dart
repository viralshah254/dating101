// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ProfileSummary {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int? get age => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;

  /// When set, discovery card shows multiple photos with left/right tap to navigate.
  List<String>? get imageUrls => throw _privateConstructorUsedError;
  double? get distanceKm => throw _privateConstructorUsedError;
  bool get verified => throw _privateConstructorUsedError;
  String? get matchReason => throw _privateConstructorUsedError;
  String get bio => throw _privateConstructorUsedError;
  String? get promptAnswer => throw _privateConstructorUsedError;
  List<String> get interests => throw _privateConstructorUsedError;

  /// Interests this profile shares with the current viewer (from backend).
  List<String> get sharedInterests => throw _privateConstructorUsedError;
  String? get motherTongue => throw _privateConstructorUsedError;
  String? get occupation => throw _privateConstructorUsedError;
  int? get heightCm => throw _privateConstructorUsedError;
  String? get religion => throw _privateConstructorUsedError;
  String? get community => throw _privateConstructorUsedError;
  String? get educationDegree => throw _privateConstructorUsedError;
  String? get maritalStatus => throw _privateConstructorUsedError;
  String? get diet => throw _privateConstructorUsedError;
  String? get incomeLabel => throw _privateConstructorUsedError;
  String? get employer => throw _privateConstructorUsedError;
  String? get familyType => throw _privateConstructorUsedError;
  int get photoCount => throw _privateConstructorUsedError;

  /// Whether this user has an active premium subscription (for badge on profile/cards).
  bool get isPremium =>
      throw _privateConstructorUsedError; // ML compatibility scoring
  double? get compatibilityScore => throw _privateConstructorUsedError;
  String? get compatibilityLabel => throw _privateConstructorUsedError;
  List<String> get matchReasons => throw _privateConstructorUsedError;
  Map<String, double>? get breakdown => throw _privateConstructorUsedError;

  /// Who manages this profile (matrimony). Only shown when not self.
  ProfileRole? get roleManagingProfile => throw _privateConstructorUsedError;

  /// Create a copy of ProfileSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileSummaryCopyWith<ProfileSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileSummaryCopyWith<$Res> {
  factory $ProfileSummaryCopyWith(
    ProfileSummary value,
    $Res Function(ProfileSummary) then,
  ) = _$ProfileSummaryCopyWithImpl<$Res, ProfileSummary>;
  @useResult
  $Res call({
    String id,
    String name,
    int? age,
    String? city,
    String? imageUrl,
    List<String>? imageUrls,
    double? distanceKm,
    bool verified,
    String? matchReason,
    String bio,
    String? promptAnswer,
    List<String> interests,
    List<String> sharedInterests,
    String? motherTongue,
    String? occupation,
    int? heightCm,
    String? religion,
    String? community,
    String? educationDegree,
    String? maritalStatus,
    String? diet,
    String? incomeLabel,
    String? employer,
    String? familyType,
    int photoCount,
    bool isPremium,
    double? compatibilityScore,
    String? compatibilityLabel,
    List<String> matchReasons,
    Map<String, double>? breakdown,
    ProfileRole? roleManagingProfile,
  });
}

/// @nodoc
class _$ProfileSummaryCopyWithImpl<$Res, $Val extends ProfileSummary>
    implements $ProfileSummaryCopyWith<$Res> {
  _$ProfileSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? age = freezed,
    Object? city = freezed,
    Object? imageUrl = freezed,
    Object? imageUrls = freezed,
    Object? distanceKm = freezed,
    Object? verified = null,
    Object? matchReason = freezed,
    Object? bio = null,
    Object? promptAnswer = freezed,
    Object? interests = null,
    Object? sharedInterests = null,
    Object? motherTongue = freezed,
    Object? occupation = freezed,
    Object? heightCm = freezed,
    Object? religion = freezed,
    Object? community = freezed,
    Object? educationDegree = freezed,
    Object? maritalStatus = freezed,
    Object? diet = freezed,
    Object? incomeLabel = freezed,
    Object? employer = freezed,
    Object? familyType = freezed,
    Object? photoCount = null,
    Object? isPremium = null,
    Object? compatibilityScore = freezed,
    Object? compatibilityLabel = freezed,
    Object? matchReasons = null,
    Object? breakdown = freezed,
    Object? roleManagingProfile = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            age: freezed == age
                ? _value.age
                : age // ignore: cast_nullable_to_non_nullable
                      as int?,
            city: freezed == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrls: freezed == imageUrls
                ? _value.imageUrls
                : imageUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            distanceKm: freezed == distanceKm
                ? _value.distanceKm
                : distanceKm // ignore: cast_nullable_to_non_nullable
                      as double?,
            verified: null == verified
                ? _value.verified
                : verified // ignore: cast_nullable_to_non_nullable
                      as bool,
            matchReason: freezed == matchReason
                ? _value.matchReason
                : matchReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            bio: null == bio
                ? _value.bio
                : bio // ignore: cast_nullable_to_non_nullable
                      as String,
            promptAnswer: freezed == promptAnswer
                ? _value.promptAnswer
                : promptAnswer // ignore: cast_nullable_to_non_nullable
                      as String?,
            interests: null == interests
                ? _value.interests
                : interests // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            sharedInterests: null == sharedInterests
                ? _value.sharedInterests
                : sharedInterests // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            motherTongue: freezed == motherTongue
                ? _value.motherTongue
                : motherTongue // ignore: cast_nullable_to_non_nullable
                      as String?,
            occupation: freezed == occupation
                ? _value.occupation
                : occupation // ignore: cast_nullable_to_non_nullable
                      as String?,
            heightCm: freezed == heightCm
                ? _value.heightCm
                : heightCm // ignore: cast_nullable_to_non_nullable
                      as int?,
            religion: freezed == religion
                ? _value.religion
                : religion // ignore: cast_nullable_to_non_nullable
                      as String?,
            community: freezed == community
                ? _value.community
                : community // ignore: cast_nullable_to_non_nullable
                      as String?,
            educationDegree: freezed == educationDegree
                ? _value.educationDegree
                : educationDegree // ignore: cast_nullable_to_non_nullable
                      as String?,
            maritalStatus: freezed == maritalStatus
                ? _value.maritalStatus
                : maritalStatus // ignore: cast_nullable_to_non_nullable
                      as String?,
            diet: freezed == diet
                ? _value.diet
                : diet // ignore: cast_nullable_to_non_nullable
                      as String?,
            incomeLabel: freezed == incomeLabel
                ? _value.incomeLabel
                : incomeLabel // ignore: cast_nullable_to_non_nullable
                      as String?,
            employer: freezed == employer
                ? _value.employer
                : employer // ignore: cast_nullable_to_non_nullable
                      as String?,
            familyType: freezed == familyType
                ? _value.familyType
                : familyType // ignore: cast_nullable_to_non_nullable
                      as String?,
            photoCount: null == photoCount
                ? _value.photoCount
                : photoCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isPremium: null == isPremium
                ? _value.isPremium
                : isPremium // ignore: cast_nullable_to_non_nullable
                      as bool,
            compatibilityScore: freezed == compatibilityScore
                ? _value.compatibilityScore
                : compatibilityScore // ignore: cast_nullable_to_non_nullable
                      as double?,
            compatibilityLabel: freezed == compatibilityLabel
                ? _value.compatibilityLabel
                : compatibilityLabel // ignore: cast_nullable_to_non_nullable
                      as String?,
            matchReasons: null == matchReasons
                ? _value.matchReasons
                : matchReasons // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            breakdown: freezed == breakdown
                ? _value.breakdown
                : breakdown // ignore: cast_nullable_to_non_nullable
                      as Map<String, double>?,
            roleManagingProfile: freezed == roleManagingProfile
                ? _value.roleManagingProfile
                : roleManagingProfile // ignore: cast_nullable_to_non_nullable
                      as ProfileRole?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProfileSummaryImplCopyWith<$Res>
    implements $ProfileSummaryCopyWith<$Res> {
  factory _$$ProfileSummaryImplCopyWith(
    _$ProfileSummaryImpl value,
    $Res Function(_$ProfileSummaryImpl) then,
  ) = __$$ProfileSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int? age,
    String? city,
    String? imageUrl,
    List<String>? imageUrls,
    double? distanceKm,
    bool verified,
    String? matchReason,
    String bio,
    String? promptAnswer,
    List<String> interests,
    List<String> sharedInterests,
    String? motherTongue,
    String? occupation,
    int? heightCm,
    String? religion,
    String? community,
    String? educationDegree,
    String? maritalStatus,
    String? diet,
    String? incomeLabel,
    String? employer,
    String? familyType,
    int photoCount,
    bool isPremium,
    double? compatibilityScore,
    String? compatibilityLabel,
    List<String> matchReasons,
    Map<String, double>? breakdown,
    ProfileRole? roleManagingProfile,
  });
}

/// @nodoc
class __$$ProfileSummaryImplCopyWithImpl<$Res>
    extends _$ProfileSummaryCopyWithImpl<$Res, _$ProfileSummaryImpl>
    implements _$$ProfileSummaryImplCopyWith<$Res> {
  __$$ProfileSummaryImplCopyWithImpl(
    _$ProfileSummaryImpl _value,
    $Res Function(_$ProfileSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProfileSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? age = freezed,
    Object? city = freezed,
    Object? imageUrl = freezed,
    Object? imageUrls = freezed,
    Object? distanceKm = freezed,
    Object? verified = null,
    Object? matchReason = freezed,
    Object? bio = null,
    Object? promptAnswer = freezed,
    Object? interests = null,
    Object? sharedInterests = null,
    Object? motherTongue = freezed,
    Object? occupation = freezed,
    Object? heightCm = freezed,
    Object? religion = freezed,
    Object? community = freezed,
    Object? educationDegree = freezed,
    Object? maritalStatus = freezed,
    Object? diet = freezed,
    Object? incomeLabel = freezed,
    Object? employer = freezed,
    Object? familyType = freezed,
    Object? photoCount = null,
    Object? isPremium = null,
    Object? compatibilityScore = freezed,
    Object? compatibilityLabel = freezed,
    Object? matchReasons = null,
    Object? breakdown = freezed,
    Object? roleManagingProfile = freezed,
  }) {
    return _then(
      _$ProfileSummaryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        age: freezed == age
            ? _value.age
            : age // ignore: cast_nullable_to_non_nullable
                  as int?,
        city: freezed == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrls: freezed == imageUrls
            ? _value._imageUrls
            : imageUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        distanceKm: freezed == distanceKm
            ? _value.distanceKm
            : distanceKm // ignore: cast_nullable_to_non_nullable
                  as double?,
        verified: null == verified
            ? _value.verified
            : verified // ignore: cast_nullable_to_non_nullable
                  as bool,
        matchReason: freezed == matchReason
            ? _value.matchReason
            : matchReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        bio: null == bio
            ? _value.bio
            : bio // ignore: cast_nullable_to_non_nullable
                  as String,
        promptAnswer: freezed == promptAnswer
            ? _value.promptAnswer
            : promptAnswer // ignore: cast_nullable_to_non_nullable
                  as String?,
        interests: null == interests
            ? _value._interests
            : interests // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        sharedInterests: null == sharedInterests
            ? _value._sharedInterests
            : sharedInterests // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        motherTongue: freezed == motherTongue
            ? _value.motherTongue
            : motherTongue // ignore: cast_nullable_to_non_nullable
                  as String?,
        occupation: freezed == occupation
            ? _value.occupation
            : occupation // ignore: cast_nullable_to_non_nullable
                  as String?,
        heightCm: freezed == heightCm
            ? _value.heightCm
            : heightCm // ignore: cast_nullable_to_non_nullable
                  as int?,
        religion: freezed == religion
            ? _value.religion
            : religion // ignore: cast_nullable_to_non_nullable
                  as String?,
        community: freezed == community
            ? _value.community
            : community // ignore: cast_nullable_to_non_nullable
                  as String?,
        educationDegree: freezed == educationDegree
            ? _value.educationDegree
            : educationDegree // ignore: cast_nullable_to_non_nullable
                  as String?,
        maritalStatus: freezed == maritalStatus
            ? _value.maritalStatus
            : maritalStatus // ignore: cast_nullable_to_non_nullable
                  as String?,
        diet: freezed == diet
            ? _value.diet
            : diet // ignore: cast_nullable_to_non_nullable
                  as String?,
        incomeLabel: freezed == incomeLabel
            ? _value.incomeLabel
            : incomeLabel // ignore: cast_nullable_to_non_nullable
                  as String?,
        employer: freezed == employer
            ? _value.employer
            : employer // ignore: cast_nullable_to_non_nullable
                  as String?,
        familyType: freezed == familyType
            ? _value.familyType
            : familyType // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoCount: null == photoCount
            ? _value.photoCount
            : photoCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isPremium: null == isPremium
            ? _value.isPremium
            : isPremium // ignore: cast_nullable_to_non_nullable
                  as bool,
        compatibilityScore: freezed == compatibilityScore
            ? _value.compatibilityScore
            : compatibilityScore // ignore: cast_nullable_to_non_nullable
                  as double?,
        compatibilityLabel: freezed == compatibilityLabel
            ? _value.compatibilityLabel
            : compatibilityLabel // ignore: cast_nullable_to_non_nullable
                  as String?,
        matchReasons: null == matchReasons
            ? _value._matchReasons
            : matchReasons // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        breakdown: freezed == breakdown
            ? _value._breakdown
            : breakdown // ignore: cast_nullable_to_non_nullable
                  as Map<String, double>?,
        roleManagingProfile: freezed == roleManagingProfile
            ? _value.roleManagingProfile
            : roleManagingProfile // ignore: cast_nullable_to_non_nullable
                  as ProfileRole?,
      ),
    );
  }
}

/// @nodoc

class _$ProfileSummaryImpl implements _ProfileSummary {
  const _$ProfileSummaryImpl({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    this.imageUrl,
    final List<String>? imageUrls,
    this.distanceKm,
    this.verified = false,
    this.matchReason,
    this.bio = '',
    this.promptAnswer,
    final List<String> interests = const [],
    final List<String> sharedInterests = const [],
    this.motherTongue,
    this.occupation,
    this.heightCm,
    this.religion,
    this.community,
    this.educationDegree,
    this.maritalStatus,
    this.diet,
    this.incomeLabel,
    this.employer,
    this.familyType,
    this.photoCount = 0,
    this.isPremium = false,
    this.compatibilityScore,
    this.compatibilityLabel,
    final List<String> matchReasons = const [],
    final Map<String, double>? breakdown,
    this.roleManagingProfile,
  }) : _imageUrls = imageUrls,
       _interests = interests,
       _sharedInterests = sharedInterests,
       _matchReasons = matchReasons,
       _breakdown = breakdown;

  @override
  final String id;
  @override
  final String name;
  @override
  final int? age;
  @override
  final String? city;
  @override
  final String? imageUrl;

  /// When set, discovery card shows multiple photos with left/right tap to navigate.
  final List<String>? _imageUrls;

  /// When set, discovery card shows multiple photos with left/right tap to navigate.
  @override
  List<String>? get imageUrls {
    final value = _imageUrls;
    if (value == null) return null;
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final double? distanceKm;
  @override
  @JsonKey()
  final bool verified;
  @override
  final String? matchReason;
  @override
  @JsonKey()
  final String bio;
  @override
  final String? promptAnswer;
  final List<String> _interests;
  @override
  @JsonKey()
  List<String> get interests {
    if (_interests is EqualUnmodifiableListView) return _interests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_interests);
  }

  /// Interests this profile shares with the current viewer (from backend).
  final List<String> _sharedInterests;

  /// Interests this profile shares with the current viewer (from backend).
  @override
  @JsonKey()
  List<String> get sharedInterests {
    if (_sharedInterests is EqualUnmodifiableListView) return _sharedInterests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sharedInterests);
  }

  @override
  final String? motherTongue;
  @override
  final String? occupation;
  @override
  final int? heightCm;
  @override
  final String? religion;
  @override
  final String? community;
  @override
  final String? educationDegree;
  @override
  final String? maritalStatus;
  @override
  final String? diet;
  @override
  final String? incomeLabel;
  @override
  final String? employer;
  @override
  final String? familyType;
  @override
  @JsonKey()
  final int photoCount;

  /// Whether this user has an active premium subscription (for badge on profile/cards).
  @override
  @JsonKey()
  final bool isPremium;
  // ML compatibility scoring
  @override
  final double? compatibilityScore;
  @override
  final String? compatibilityLabel;
  final List<String> _matchReasons;
  @override
  @JsonKey()
  List<String> get matchReasons {
    if (_matchReasons is EqualUnmodifiableListView) return _matchReasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_matchReasons);
  }

  final Map<String, double>? _breakdown;
  @override
  Map<String, double>? get breakdown {
    final value = _breakdown;
    if (value == null) return null;
    if (_breakdown is EqualUnmodifiableMapView) return _breakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Who manages this profile (matrimony). Only shown when not self.
  @override
  final ProfileRole? roleManagingProfile;

  @override
  String toString() {
    return 'ProfileSummary(id: $id, name: $name, age: $age, city: $city, imageUrl: $imageUrl, imageUrls: $imageUrls, distanceKm: $distanceKm, verified: $verified, matchReason: $matchReason, bio: $bio, promptAnswer: $promptAnswer, interests: $interests, sharedInterests: $sharedInterests, motherTongue: $motherTongue, occupation: $occupation, heightCm: $heightCm, religion: $religion, community: $community, educationDegree: $educationDegree, maritalStatus: $maritalStatus, diet: $diet, incomeLabel: $incomeLabel, employer: $employer, familyType: $familyType, photoCount: $photoCount, isPremium: $isPremium, compatibilityScore: $compatibilityScore, compatibilityLabel: $compatibilityLabel, matchReasons: $matchReasons, breakdown: $breakdown, roleManagingProfile: $roleManagingProfile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality().equals(
              other._imageUrls,
              _imageUrls,
            ) &&
            (identical(other.distanceKm, distanceKm) ||
                other.distanceKm == distanceKm) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.matchReason, matchReason) ||
                other.matchReason == matchReason) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.promptAnswer, promptAnswer) ||
                other.promptAnswer == promptAnswer) &&
            const DeepCollectionEquality().equals(
              other._interests,
              _interests,
            ) &&
            const DeepCollectionEquality().equals(
              other._sharedInterests,
              _sharedInterests,
            ) &&
            (identical(other.motherTongue, motherTongue) ||
                other.motherTongue == motherTongue) &&
            (identical(other.occupation, occupation) ||
                other.occupation == occupation) &&
            (identical(other.heightCm, heightCm) ||
                other.heightCm == heightCm) &&
            (identical(other.religion, religion) ||
                other.religion == religion) &&
            (identical(other.community, community) ||
                other.community == community) &&
            (identical(other.educationDegree, educationDegree) ||
                other.educationDegree == educationDegree) &&
            (identical(other.maritalStatus, maritalStatus) ||
                other.maritalStatus == maritalStatus) &&
            (identical(other.diet, diet) || other.diet == diet) &&
            (identical(other.incomeLabel, incomeLabel) ||
                other.incomeLabel == incomeLabel) &&
            (identical(other.employer, employer) ||
                other.employer == employer) &&
            (identical(other.familyType, familyType) ||
                other.familyType == familyType) &&
            (identical(other.photoCount, photoCount) ||
                other.photoCount == photoCount) &&
            (identical(other.isPremium, isPremium) ||
                other.isPremium == isPremium) &&
            (identical(other.compatibilityScore, compatibilityScore) ||
                other.compatibilityScore == compatibilityScore) &&
            (identical(other.compatibilityLabel, compatibilityLabel) ||
                other.compatibilityLabel == compatibilityLabel) &&
            const DeepCollectionEquality().equals(
              other._matchReasons,
              _matchReasons,
            ) &&
            const DeepCollectionEquality().equals(
              other._breakdown,
              _breakdown,
            ) &&
            (identical(other.roleManagingProfile, roleManagingProfile) ||
                other.roleManagingProfile == roleManagingProfile));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    age,
    city,
    imageUrl,
    const DeepCollectionEquality().hash(_imageUrls),
    distanceKm,
    verified,
    matchReason,
    bio,
    promptAnswer,
    const DeepCollectionEquality().hash(_interests),
    const DeepCollectionEquality().hash(_sharedInterests),
    motherTongue,
    occupation,
    heightCm,
    religion,
    community,
    educationDegree,
    maritalStatus,
    diet,
    incomeLabel,
    employer,
    familyType,
    photoCount,
    isPremium,
    compatibilityScore,
    compatibilityLabel,
    const DeepCollectionEquality().hash(_matchReasons),
    const DeepCollectionEquality().hash(_breakdown),
    roleManagingProfile,
  ]);

  /// Create a copy of ProfileSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileSummaryImplCopyWith<_$ProfileSummaryImpl> get copyWith =>
      __$$ProfileSummaryImplCopyWithImpl<_$ProfileSummaryImpl>(
        this,
        _$identity,
      );
}

abstract class _ProfileSummary implements ProfileSummary {
  const factory _ProfileSummary({
    required final String id,
    required final String name,
    required final int? age,
    required final String? city,
    final String? imageUrl,
    final List<String>? imageUrls,
    final double? distanceKm,
    final bool verified,
    final String? matchReason,
    final String bio,
    final String? promptAnswer,
    final List<String> interests,
    final List<String> sharedInterests,
    final String? motherTongue,
    final String? occupation,
    final int? heightCm,
    final String? religion,
    final String? community,
    final String? educationDegree,
    final String? maritalStatus,
    final String? diet,
    final String? incomeLabel,
    final String? employer,
    final String? familyType,
    final int photoCount,
    final bool isPremium,
    final double? compatibilityScore,
    final String? compatibilityLabel,
    final List<String> matchReasons,
    final Map<String, double>? breakdown,
    final ProfileRole? roleManagingProfile,
  }) = _$ProfileSummaryImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  int? get age;
  @override
  String? get city;
  @override
  String? get imageUrl;

  /// When set, discovery card shows multiple photos with left/right tap to navigate.
  @override
  List<String>? get imageUrls;
  @override
  double? get distanceKm;
  @override
  bool get verified;
  @override
  String? get matchReason;
  @override
  String get bio;
  @override
  String? get promptAnswer;
  @override
  List<String> get interests;

  /// Interests this profile shares with the current viewer (from backend).
  @override
  List<String> get sharedInterests;
  @override
  String? get motherTongue;
  @override
  String? get occupation;
  @override
  int? get heightCm;
  @override
  String? get religion;
  @override
  String? get community;
  @override
  String? get educationDegree;
  @override
  String? get maritalStatus;
  @override
  String? get diet;
  @override
  String? get incomeLabel;
  @override
  String? get employer;
  @override
  String? get familyType;
  @override
  int get photoCount;

  /// Whether this user has an active premium subscription (for badge on profile/cards).
  @override
  bool get isPremium; // ML compatibility scoring
  @override
  double? get compatibilityScore;
  @override
  String? get compatibilityLabel;
  @override
  List<String> get matchReasons;
  @override
  Map<String, double>? get breakdown;

  /// Who manages this profile (matrimony). Only shown when not self.
  @override
  ProfileRole? get roleManagingProfile;

  /// Create a copy of ProfileSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileSummaryImplCopyWith<_$ProfileSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
