import '../../core/referral/referral_invite_link.dart';
import '../../domain/models/referral_info.dart';
import '../../domain/repositories/referral_repository.dart';

class FakeReferralRepository implements ReferralRepository {
  @override
  Future<ReferralInfo> getReferral() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ReferralInfo(
      code: 'DESI-XXXX',
      inviteLink: buildReferralInviteDownloadLink('DESI-XXXX'),
      pendingCount: 0,
      earnedRewards: [],
    );
  }

  @override
  Future<void> recordInvite({String? channel}) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
