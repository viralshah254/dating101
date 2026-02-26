/// Referral info from GET /referral. See BACKEND_API_REFERENCE §8a.
class ReferralInfo {
  const ReferralInfo({
    required this.code,
    required this.inviteLink,
    this.pendingCount = 0,
    this.earnedRewards = const [],
  });
  final String code;
  final String inviteLink;
  final int pendingCount;
  final List<dynamic> earnedRewards;
}
