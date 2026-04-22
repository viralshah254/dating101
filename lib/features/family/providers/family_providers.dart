import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../repositories/family_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return FamilyRepository(api);
});

// ── Members ───────────────────────────────────────────────────────────────────

final familyMembersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getMembers();
});

// ── Family mode & chat policy ─────────────────────────────────────────────────

final familyModeProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getFamilyMode();
});

// ── Notifier for updating family mode ─────────────────────────────────────────

class FamilyModeNotifier extends AutoDisposeAsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final repo = ref.watch(familyRepositoryProvider);
    return repo.getFamilyMode();
  }

  Future<void> patch({String? familyMode, String? familyChatPolicy}) async {
    final repo = ref.read(familyRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.updateFamilyMode(
          familyMode: familyMode,
          familyChatPolicy: familyChatPolicy,
        ));
  }
}

final familyModeNotifierProvider =
    AutoDisposeAsyncNotifierProvider<FamilyModeNotifier, Map<String, dynamic>>(
        FamilyModeNotifier.new);
