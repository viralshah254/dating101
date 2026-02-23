import 'package:freezed_annotation/freezed_annotation.dart';

part 'interaction_models.freezed.dart';

/// Dating: intro sent (with optional message).
@freezed
class Intro with _$Intro {
  const factory Intro({
    required String id,
    required String fromUserId,
    required String toUserId,
    String? message,
    required DateTime sentAt,
    @Default(IntroStatus.pending) IntroStatus status,
  }) = _Intro;
}

enum IntroStatus { pending, accepted, declined }

/// Dating: match state when both have liked/intro'd.
@freezed
class Match with _$Match {
  const factory Match({
    required String id,
    required String userId1,
    required String userId2,
    required DateTime matchedAt,
  }) = _Match;
}

/// Matrimony: interest sent/received.
@freezed
class Interest with _$Interest {
  const factory Interest({
    required String id,
    required String fromUserId,
    required String toUserId,
    required DateTime sentAt,
    @Default(InterestStatus.pending) InterestStatus status,
  }) = _Interest;
}

enum InterestStatus { pending, accepted, rejected, withdrawn }

/// Matrimony: contact request (after mutual interest or premium).
@freezed
class ContactRequest with _$ContactRequest {
  const factory ContactRequest({
    required String id,
    required String fromUserId,
    required String toUserId,
    required DateTime requestedAt,
    @Default(ContactRequestStatus.pending) ContactRequestStatus status,
  }) = _ContactRequest;
}

enum ContactRequestStatus { pending, approved, denied }
