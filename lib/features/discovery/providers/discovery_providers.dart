import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/models/filter_options.dart';
import '../../../domain/repositories/discovery_repository.dart';

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

/// Full UserProfile by id (for detailed profile view, matrimony).
final fullUserProfileProvider = FutureProvider.autoDispose.family<UserProfile?, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile(userId);
});

/// Compatibility breakdown for a specific candidate.
final compatibilityProvider = FutureProvider.autoDispose.family<CompatibilityDetail?, String>((ref, candidateId) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  try {
    return await repo.getCompatibility(candidateId);
  } catch (e) {
    debugPrint('[Compatibility] Failed to fetch for $candidateId: $e');
    return null;
  }
});

/// Filter options for Explore tab (GET /discovery/filter-options). Use for dropdown options and defaults.
final filterOptionsProvider = FutureProvider.autoDispose<FilterOptions>((ref) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  return repo.getFilterOptions();
});
