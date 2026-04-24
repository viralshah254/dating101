/// String values for [AdActionType] on the backend (`dating-backend/src/services/ad-token.ts`).
abstract final class AdActionType {
  AdActionType._();

  static const priorityInterest = 'priority_interest';
  static const messageSend = 'message_send';
  static const requestUnlock = 'request_unlock';
  static const shortlistUnlock = 'shortlist_unlock';
  static const inboxUnlock = 'inbox_unlock';
  static const visitorUnlock = 'visitor_unlock';
  static const extraInterest = 'extra_interest';
  static const likedYouUnlock = 'liked_you_unlock';
  static const photoUnlock = 'photo_unlock';
}
