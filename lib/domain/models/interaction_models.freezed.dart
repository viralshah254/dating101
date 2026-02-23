// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'interaction_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Intro {
  String get id => throw _privateConstructorUsedError;
  String get fromUserId => throw _privateConstructorUsedError;
  String get toUserId => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  DateTime get sentAt => throw _privateConstructorUsedError;
  IntroStatus get status => throw _privateConstructorUsedError;

  /// Create a copy of Intro
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IntroCopyWith<Intro> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IntroCopyWith<$Res> {
  factory $IntroCopyWith(Intro value, $Res Function(Intro) then) =
      _$IntroCopyWithImpl<$Res, Intro>;
  @useResult
  $Res call({
    String id,
    String fromUserId,
    String toUserId,
    String? message,
    DateTime sentAt,
    IntroStatus status,
  });
}

/// @nodoc
class _$IntroCopyWithImpl<$Res, $Val extends Intro>
    implements $IntroCopyWith<$Res> {
  _$IntroCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Intro
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? message = freezed,
    Object? sentAt = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            fromUserId: null == fromUserId
                ? _value.fromUserId
                : fromUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            toUserId: null == toUserId
                ? _value.toUserId
                : toUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            message: freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String?,
            sentAt: null == sentAt
                ? _value.sentAt
                : sentAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as IntroStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$IntroImplCopyWith<$Res> implements $IntroCopyWith<$Res> {
  factory _$$IntroImplCopyWith(
    _$IntroImpl value,
    $Res Function(_$IntroImpl) then,
  ) = __$$IntroImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String fromUserId,
    String toUserId,
    String? message,
    DateTime sentAt,
    IntroStatus status,
  });
}

/// @nodoc
class __$$IntroImplCopyWithImpl<$Res>
    extends _$IntroCopyWithImpl<$Res, _$IntroImpl>
    implements _$$IntroImplCopyWith<$Res> {
  __$$IntroImplCopyWithImpl(
    _$IntroImpl _value,
    $Res Function(_$IntroImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Intro
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? message = freezed,
    Object? sentAt = null,
    Object? status = null,
  }) {
    return _then(
      _$IntroImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        fromUserId: null == fromUserId
            ? _value.fromUserId
            : fromUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        toUserId: null == toUserId
            ? _value.toUserId
            : toUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
        sentAt: null == sentAt
            ? _value.sentAt
            : sentAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as IntroStatus,
      ),
    );
  }
}

/// @nodoc

class _$IntroImpl implements _Intro {
  const _$IntroImpl({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.message,
    required this.sentAt,
    this.status = IntroStatus.pending,
  });

  @override
  final String id;
  @override
  final String fromUserId;
  @override
  final String toUserId;
  @override
  final String? message;
  @override
  final DateTime sentAt;
  @override
  @JsonKey()
  final IntroStatus status;

  @override
  String toString() {
    return 'Intro(id: $id, fromUserId: $fromUserId, toUserId: $toUserId, message: $message, sentAt: $sentAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IntroImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fromUserId, fromUserId) ||
                other.fromUserId == fromUserId) &&
            (identical(other.toUserId, toUserId) ||
                other.toUserId == toUserId) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    fromUserId,
    toUserId,
    message,
    sentAt,
    status,
  );

  /// Create a copy of Intro
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IntroImplCopyWith<_$IntroImpl> get copyWith =>
      __$$IntroImplCopyWithImpl<_$IntroImpl>(this, _$identity);
}

abstract class _Intro implements Intro {
  const factory _Intro({
    required final String id,
    required final String fromUserId,
    required final String toUserId,
    final String? message,
    required final DateTime sentAt,
    final IntroStatus status,
  }) = _$IntroImpl;

  @override
  String get id;
  @override
  String get fromUserId;
  @override
  String get toUserId;
  @override
  String? get message;
  @override
  DateTime get sentAt;
  @override
  IntroStatus get status;

  /// Create a copy of Intro
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IntroImplCopyWith<_$IntroImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Match {
  String get id => throw _privateConstructorUsedError;
  String get userId1 => throw _privateConstructorUsedError;
  String get userId2 => throw _privateConstructorUsedError;
  DateTime get matchedAt => throw _privateConstructorUsedError;

  /// Create a copy of Match
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatchCopyWith<Match> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchCopyWith<$Res> {
  factory $MatchCopyWith(Match value, $Res Function(Match) then) =
      _$MatchCopyWithImpl<$Res, Match>;
  @useResult
  $Res call({String id, String userId1, String userId2, DateTime matchedAt});
}

/// @nodoc
class _$MatchCopyWithImpl<$Res, $Val extends Match>
    implements $MatchCopyWith<$Res> {
  _$MatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Match
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId1 = null,
    Object? userId2 = null,
    Object? matchedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId1: null == userId1
                ? _value.userId1
                : userId1 // ignore: cast_nullable_to_non_nullable
                      as String,
            userId2: null == userId2
                ? _value.userId2
                : userId2 // ignore: cast_nullable_to_non_nullable
                      as String,
            matchedAt: null == matchedAt
                ? _value.matchedAt
                : matchedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MatchImplCopyWith<$Res> implements $MatchCopyWith<$Res> {
  factory _$$MatchImplCopyWith(
    _$MatchImpl value,
    $Res Function(_$MatchImpl) then,
  ) = __$$MatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String userId1, String userId2, DateTime matchedAt});
}

/// @nodoc
class __$$MatchImplCopyWithImpl<$Res>
    extends _$MatchCopyWithImpl<$Res, _$MatchImpl>
    implements _$$MatchImplCopyWith<$Res> {
  __$$MatchImplCopyWithImpl(
    _$MatchImpl _value,
    $Res Function(_$MatchImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Match
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId1 = null,
    Object? userId2 = null,
    Object? matchedAt = null,
  }) {
    return _then(
      _$MatchImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId1: null == userId1
            ? _value.userId1
            : userId1 // ignore: cast_nullable_to_non_nullable
                  as String,
        userId2: null == userId2
            ? _value.userId2
            : userId2 // ignore: cast_nullable_to_non_nullable
                  as String,
        matchedAt: null == matchedAt
            ? _value.matchedAt
            : matchedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$MatchImpl implements _Match {
  const _$MatchImpl({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.matchedAt,
  });

  @override
  final String id;
  @override
  final String userId1;
  @override
  final String userId2;
  @override
  final DateTime matchedAt;

  @override
  String toString() {
    return 'Match(id: $id, userId1: $userId1, userId2: $userId2, matchedAt: $matchedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId1, userId1) || other.userId1 == userId1) &&
            (identical(other.userId2, userId2) || other.userId2 == userId2) &&
            (identical(other.matchedAt, matchedAt) ||
                other.matchedAt == matchedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, userId1, userId2, matchedAt);

  /// Create a copy of Match
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchImplCopyWith<_$MatchImpl> get copyWith =>
      __$$MatchImplCopyWithImpl<_$MatchImpl>(this, _$identity);
}

abstract class _Match implements Match {
  const factory _Match({
    required final String id,
    required final String userId1,
    required final String userId2,
    required final DateTime matchedAt,
  }) = _$MatchImpl;

  @override
  String get id;
  @override
  String get userId1;
  @override
  String get userId2;
  @override
  DateTime get matchedAt;

  /// Create a copy of Match
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatchImplCopyWith<_$MatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Interest {
  String get id => throw _privateConstructorUsedError;
  String get fromUserId => throw _privateConstructorUsedError;
  String get toUserId => throw _privateConstructorUsedError;
  DateTime get sentAt => throw _privateConstructorUsedError;
  InterestStatus get status => throw _privateConstructorUsedError;

  /// Create a copy of Interest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InterestCopyWith<Interest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InterestCopyWith<$Res> {
  factory $InterestCopyWith(Interest value, $Res Function(Interest) then) =
      _$InterestCopyWithImpl<$Res, Interest>;
  @useResult
  $Res call({
    String id,
    String fromUserId,
    String toUserId,
    DateTime sentAt,
    InterestStatus status,
  });
}

/// @nodoc
class _$InterestCopyWithImpl<$Res, $Val extends Interest>
    implements $InterestCopyWith<$Res> {
  _$InterestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Interest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? sentAt = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            fromUserId: null == fromUserId
                ? _value.fromUserId
                : fromUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            toUserId: null == toUserId
                ? _value.toUserId
                : toUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            sentAt: null == sentAt
                ? _value.sentAt
                : sentAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as InterestStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InterestImplCopyWith<$Res>
    implements $InterestCopyWith<$Res> {
  factory _$$InterestImplCopyWith(
    _$InterestImpl value,
    $Res Function(_$InterestImpl) then,
  ) = __$$InterestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String fromUserId,
    String toUserId,
    DateTime sentAt,
    InterestStatus status,
  });
}

/// @nodoc
class __$$InterestImplCopyWithImpl<$Res>
    extends _$InterestCopyWithImpl<$Res, _$InterestImpl>
    implements _$$InterestImplCopyWith<$Res> {
  __$$InterestImplCopyWithImpl(
    _$InterestImpl _value,
    $Res Function(_$InterestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Interest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? sentAt = null,
    Object? status = null,
  }) {
    return _then(
      _$InterestImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        fromUserId: null == fromUserId
            ? _value.fromUserId
            : fromUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        toUserId: null == toUserId
            ? _value.toUserId
            : toUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        sentAt: null == sentAt
            ? _value.sentAt
            : sentAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as InterestStatus,
      ),
    );
  }
}

/// @nodoc

class _$InterestImpl implements _Interest {
  const _$InterestImpl({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.sentAt,
    this.status = InterestStatus.pending,
  });

  @override
  final String id;
  @override
  final String fromUserId;
  @override
  final String toUserId;
  @override
  final DateTime sentAt;
  @override
  @JsonKey()
  final InterestStatus status;

  @override
  String toString() {
    return 'Interest(id: $id, fromUserId: $fromUserId, toUserId: $toUserId, sentAt: $sentAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InterestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fromUserId, fromUserId) ||
                other.fromUserId == fromUserId) &&
            (identical(other.toUserId, toUserId) ||
                other.toUserId == toUserId) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, fromUserId, toUserId, sentAt, status);

  /// Create a copy of Interest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InterestImplCopyWith<_$InterestImpl> get copyWith =>
      __$$InterestImplCopyWithImpl<_$InterestImpl>(this, _$identity);
}

abstract class _Interest implements Interest {
  const factory _Interest({
    required final String id,
    required final String fromUserId,
    required final String toUserId,
    required final DateTime sentAt,
    final InterestStatus status,
  }) = _$InterestImpl;

  @override
  String get id;
  @override
  String get fromUserId;
  @override
  String get toUserId;
  @override
  DateTime get sentAt;
  @override
  InterestStatus get status;

  /// Create a copy of Interest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InterestImplCopyWith<_$InterestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ContactRequest {
  String get id => throw _privateConstructorUsedError;
  String get fromUserId => throw _privateConstructorUsedError;
  String get toUserId => throw _privateConstructorUsedError;
  DateTime get requestedAt => throw _privateConstructorUsedError;
  ContactRequestStatus get status => throw _privateConstructorUsedError;

  /// Create a copy of ContactRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContactRequestCopyWith<ContactRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContactRequestCopyWith<$Res> {
  factory $ContactRequestCopyWith(
    ContactRequest value,
    $Res Function(ContactRequest) then,
  ) = _$ContactRequestCopyWithImpl<$Res, ContactRequest>;
  @useResult
  $Res call({
    String id,
    String fromUserId,
    String toUserId,
    DateTime requestedAt,
    ContactRequestStatus status,
  });
}

/// @nodoc
class _$ContactRequestCopyWithImpl<$Res, $Val extends ContactRequest>
    implements $ContactRequestCopyWith<$Res> {
  _$ContactRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContactRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? requestedAt = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            fromUserId: null == fromUserId
                ? _value.fromUserId
                : fromUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            toUserId: null == toUserId
                ? _value.toUserId
                : toUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            requestedAt: null == requestedAt
                ? _value.requestedAt
                : requestedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ContactRequestStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ContactRequestImplCopyWith<$Res>
    implements $ContactRequestCopyWith<$Res> {
  factory _$$ContactRequestImplCopyWith(
    _$ContactRequestImpl value,
    $Res Function(_$ContactRequestImpl) then,
  ) = __$$ContactRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String fromUserId,
    String toUserId,
    DateTime requestedAt,
    ContactRequestStatus status,
  });
}

/// @nodoc
class __$$ContactRequestImplCopyWithImpl<$Res>
    extends _$ContactRequestCopyWithImpl<$Res, _$ContactRequestImpl>
    implements _$$ContactRequestImplCopyWith<$Res> {
  __$$ContactRequestImplCopyWithImpl(
    _$ContactRequestImpl _value,
    $Res Function(_$ContactRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContactRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? requestedAt = null,
    Object? status = null,
  }) {
    return _then(
      _$ContactRequestImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        fromUserId: null == fromUserId
            ? _value.fromUserId
            : fromUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        toUserId: null == toUserId
            ? _value.toUserId
            : toUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        requestedAt: null == requestedAt
            ? _value.requestedAt
            : requestedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ContactRequestStatus,
      ),
    );
  }
}

/// @nodoc

class _$ContactRequestImpl implements _ContactRequest {
  const _$ContactRequestImpl({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.requestedAt,
    this.status = ContactRequestStatus.pending,
  });

  @override
  final String id;
  @override
  final String fromUserId;
  @override
  final String toUserId;
  @override
  final DateTime requestedAt;
  @override
  @JsonKey()
  final ContactRequestStatus status;

  @override
  String toString() {
    return 'ContactRequest(id: $id, fromUserId: $fromUserId, toUserId: $toUserId, requestedAt: $requestedAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContactRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fromUserId, fromUserId) ||
                other.fromUserId == fromUserId) &&
            (identical(other.toUserId, toUserId) ||
                other.toUserId == toUserId) &&
            (identical(other.requestedAt, requestedAt) ||
                other.requestedAt == requestedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, fromUserId, toUserId, requestedAt, status);

  /// Create a copy of ContactRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContactRequestImplCopyWith<_$ContactRequestImpl> get copyWith =>
      __$$ContactRequestImplCopyWithImpl<_$ContactRequestImpl>(
        this,
        _$identity,
      );
}

abstract class _ContactRequest implements ContactRequest {
  const factory _ContactRequest({
    required final String id,
    required final String fromUserId,
    required final String toUserId,
    required final DateTime requestedAt,
    final ContactRequestStatus status,
  }) = _$ContactRequestImpl;

  @override
  String get id;
  @override
  String get fromUserId;
  @override
  String get toUserId;
  @override
  DateTime get requestedAt;
  @override
  ContactRequestStatus get status;

  /// Create a copy of ContactRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContactRequestImplCopyWith<_$ContactRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
