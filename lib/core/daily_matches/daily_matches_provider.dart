import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mode/app_mode.dart';
import '../mode/mode_provider.dart';
import '../providers/repository_providers.dart';
import '../../domain/models/profile_summary.dart';
import 'daily_matches_storage.dart';

final dailyMatchesStorageProvider = Provider<DailyMatchesStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DailyMatchesStorage(prefs);
});

/// Fetches daily matches for matrimony. Only valid when mode is matrimony.
final dailyMatchesProvider =
    FutureProvider.autoDispose<List<ProfileSummary>>((ref) async {
  final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
  if (!mode.isMatrimony) return [];
  final repo = ref.read(discoveryRepositoryProvider);
  return repo.getDailyMatches(limit: 9);
});
