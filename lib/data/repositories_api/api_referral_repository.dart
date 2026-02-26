import '../../domain/models/referral_info.dart';
import '../../domain/repositories/referral_repository.dart';
import '../api/api_client.dart';

class ApiReferralRepository implements ReferralRepository {
  ApiReferralRepository({required this.api});
  final ApiClient api;

  @override
  Future<ReferralInfo> getReferral() async {
    final body = await api.get('/referral');
    return ReferralInfo(
      code: body['code'] as String? ?? '',
      inviteLink: body['inviteLink'] as String? ?? '',
      pendingCount: body['pendingCount'] as int? ?? 0,
      earnedRewards: body['earnedRewards'] is List ? (body['earnedRewards'] as List) : [],
    );
  }

  @override
  Future<void> recordInvite({String? channel}) async {
    await api.post('/referral/invite', body: channel != null ? {'channel': channel} : <String, dynamic>{});
  }
}
