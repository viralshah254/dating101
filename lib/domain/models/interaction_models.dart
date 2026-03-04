import 'package:freezed_annotation/freezed_annotation.dart';

import 'profile_summary.dart';

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

/// One item in the requests inbox (GET /interactions/received) or sent list.
class InteractionInboxItem {
  const InteractionInboxItem({
    required this.interactionId,
    required this.otherUser,
    this.message,
    this.seenByRecipient = false,
    this.status = 'pending',
    this.type = 'interest',
    required this.createdAt,
  });
  final String interactionId;
  final ProfileSummary otherUser;
  final String? message;
  final bool seenByRecipient;
  final String status;
  final String type;
  final DateTime createdAt;
}

/// Result of unlocking one received (inbox) interaction after watch-ad. Backend enforces 2/week.
class InboxUnlockResult {
  const InboxUnlockResult({
    required this.item,
    this.unlocksRemainingThisWeek = 0,
    this.resetsAt,
  });
  final InteractionInboxItem item;
  final int unlocksRemainingThisWeek;
  final DateTime? resetsAt;
}

/// Result of expressing interest or priority interest (Shubhmilan interactions API).
class ExpressInterestResult {
  const ExpressInterestResult({
    required this.interactionId,
    required this.mutualMatch,
    this.matchId,
    this.chatThreadId,
    this.priorityRemaining,
  });
  final String interactionId;
  final bool mutualMatch;
  final String? matchId;
  final String? chatThreadId;
  /// Daily priority-interest count remaining (priority interest only).
  final int? priorityRemaining;
}
