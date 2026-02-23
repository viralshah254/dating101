import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/models/profile_summary.dart';

/// Recommended list for current mode (dating discovery / matrimony matches).
final recommendedProfilesProvider = FutureProvider.autoDispose<List<ProfileSummary>>((ref) async {
  final mode = ref.watch(appModeProvider) ?? AppMode.dating;
  final repo = ref.watch(discoveryRepositoryProvider);
  return repo.getRecommended(mode: mode, limit: 20);
});

/// Single profile summary by id (for full profile screen).
final profileSummaryProvider = FutureProvider.autoDispose.family<ProfileSummary?, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfileSummary(userId);
});
