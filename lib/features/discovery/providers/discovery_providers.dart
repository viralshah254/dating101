import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/models/discovery_filter_params.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/models/filter_options.dart';
import '../../../domain/repositories/discovery_repository.dart';

/// Travel mode: when non-null, discovery shows profiles for this city (from "Change city").
final discoveryTravelCityProvider = StateProvider<String?>((ref) => null);

/// Applied discovery filters (from filters sheet). When non-null, feed uses getExplore with these params.
final discoveryFilterParamsProvider = StateProvider<DiscoveryFilterParams?>(
  (ref) => null,
);

/// Discovery feed: recommended (with optional travel city) or filtered explore results.
final discoveryFeedProvider = FutureProvider.autoDispose<List<ProfileSummary>>((
  ref,
) async {
  final mode = ref.watch(appModeProvider) ?? AppMode.dating;
  final travelCity = ref.watch(discoveryTravelCityProvider);
  final filterParams = ref.watch(discoveryFilterParamsProvider);
  final repo = ref.watch(discoveryRepositoryProvider);

  if (filterParams != null && filterParams.hasFilters) {
    return repo.getExplore(
      mode: mode,
      ageMin: filterParams.ageMin,
      ageMax: filterParams.ageMax,
      city: filterParams.city,
      religion: filterParams.religion,
      education: filterParams.education,
      heightMinCm: filterParams.heightMinCm,
      heightMaxCm: filterParams.heightMaxCm,
      diet: filterParams.diet,
      bodyType: filterParams.bodyType,
      maritalStatus: filterParams.maritalStatus,
      limit: 20,
    );
  }
  return repo.getRecommended(mode: mode, city: travelCity, limit: 20);
});

/// Recommended list for current mode (dating discovery / matrimony matches).
/// Prefer [discoveryFeedProvider] for discovery screen (supports travel city + filters).
final recommendedProfilesProvider =
    FutureProvider.autoDispose<List<ProfileSummary>>((ref) async {
      final mode = ref.watch(appModeProvider) ?? AppMode.dating;
      final repo = ref.watch(discoveryRepositoryProvider);
      return repo.getRecommended(mode: mode, limit: 20);
    });

/// Single profile summary by id (for full profile screen).
final profileSummaryProvider = FutureProvider.autoDispose
    .family<ProfileSummary?, String>((ref, userId) async {
      final repo = ref.watch(profileRepositoryProvider);
      return repo.getProfileSummary(userId);
    });

/// Full UserProfile by id (for detailed profile view, matrimony).
final fullUserProfileProvider = FutureProvider.autoDispose
    .family<UserProfile?, String>((ref, userId) async {
      final repo = ref.watch(profileRepositoryProvider);
      return repo.getProfile(userId);
    });

/// Compatibility breakdown for a specific candidate.
final compatibilityProvider = FutureProvider.autoDispose
    .family<CompatibilityDetail?, String>((ref, candidateId) async {
      final repo = ref.watch(discoveryRepositoryProvider);
      try {
        return await repo.getCompatibility(candidateId);
      } catch (e) {
        debugPrint('[Compatibility] Failed to fetch for $candidateId: $e');
        return null;
      }
    });

/// Filter options for Explore tab (GET /discovery/filter-options). Use for dropdown options and defaults.
final filterOptionsProvider = FutureProvider.autoDispose<FilterOptions>((
  ref,
) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  return repo.getFilterOptions();
});
