import '../models/referral_info.dart';

/// Referral: GET /referral, POST /referral/invite. See BACKEND_API_REFERENCE §8a.
abstract class ReferralRepository {
  /// GET /referral — code, inviteLink, pendingCount, earnedRewards.
  Future<ReferralInfo> getReferral();

  /// POST /referral/invite — optional, record that user sent an invite.
  Future<void> recordInvite({String? channel});
}
