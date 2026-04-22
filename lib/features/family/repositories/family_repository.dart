import '../../../data/api/api_client.dart';

/// Repository for all family-circle API calls.
class FamilyRepository {
  const FamilyRepository(this._api);
  final ApiClient _api;

  // ── Members ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMembers() async {
    final resp = await _api.get('/family/members');
    final list = resp['members'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> inviteMember({
    required String relationship,
    List<String> permissions = const ['view_shortlist', 'add_notes'],
  }) async {
    final resp = await _api.post('/family/invite', body: {
      'relationship': relationship,
      'permissions': permissions,
    });
    return resp;
  }

  Future<void> revokeMember(String memberId) async {
    await _api.delete('/family/members/$memberId');
  }

  // ── Shortlist (family view) ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getFamilyShortlist(String ownerUserId) async {
    final resp = await _api.get('/family/shortlist?ownerUserId=$ownerUserId');
    final list = resp['shortlist'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> updateNote({
    required String ownerUserId,
    required String targetUserId,
    required String? note,
  }) async {
    await _api.post('/family/notes', body: {
      'ownerUserId': ownerUserId,
      'targetUserId': targetUserId,
      'note': note,
    });
  }

  // ── Family mode & chat policy ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getFamilyMode() async {
    return await _api.get('/profile/me/family-mode');
  }

  Future<Map<String, dynamic>> updateFamilyMode({
    String? familyMode,
    String? familyChatPolicy,
  }) async {
    final body = <String, dynamic>{};
    if (familyMode != null) body['familyMode'] = familyMode;
    if (familyChatPolicy != null) body['familyChatPolicy'] = familyChatPolicy;
    return await _api.patch('/profile/me/family-mode', body: body);
  }

  // ── Handover ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> startHandover() async {
    return await _api.post('/family/handover/start', body: {});
  }

  Future<Map<String, dynamic>> acceptHandover(String token) async {
    return await _api.post('/family/handover/accept', body: {'token': token});
  }
}
