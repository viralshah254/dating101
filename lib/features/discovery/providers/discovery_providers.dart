import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/profile_view_merge.dart';
import '../../../domain/models/discovery_filter_params.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/models/filter_options.dart';
import '../../../domain/repositories/discovery_repository.dart';
import '../../matches/providers/matches_providers.dart' show recommendedPaginatedProvider;

/// Why Discover is showing the loading surface (filters / city / first open).
enum DiscoveryLoadingCue {
  none,
  initial,
  filters,
  location,
}

final discoveryLoadingCueProvider =
    StateProvider<DiscoveryLoadingCue>((ref) => DiscoveryLoadingCue.none);

/// Travel mode: when non-null, discovery shows profiles for this city (from "Change city").
final discoveryTravelCityProvider = StateProvider<String?>((ref) => null);

/// When set, discovery should advance past this profile (e.g. after liking from full profile so the card is dismissed when returning).
final discoveryAdvancePastProfileIdProvider = StateProvider<String?>((ref) => null);

/// Applied discovery filters (from filters sheet). When non-null, feed uses getExplore with these params.
final discoveryFilterParamsProvider = StateProvider<DiscoveryFilterParams?>(
  (ref) => null,
);

/// Discovery feed: recommended (with optional travel city) or filtered explore results.
///
/// When no filter overrides are active, this provider delegates to
/// [recommendedPaginatedProvider] so that navigating between the swipe-card
/// Discover screen and the matrimony Matches screen shares one cached HTTP
/// response instead of issuing duplicate requests.
final discoveryFeedProvider = FutureProvider<List<ProfileSummary>>((
  ref,
) async {
  final mode = ref.watch(appModeProvider) ?? AppMode.dating;
  final travelCity = ref.watch(discoveryTravelCityProvider);
  final filterParams = ref.watch(discoveryFilterParamsProvider);
  final repo = ref.watch(discoveryRepositoryProvider);

  final effectiveCity = filterParams?.city ?? travelCity;

  // Filtered or travel-city requests cannot share the paginated cache.
  if ((filterParams != null && filterParams.hasFilters) || travelCity != null) {
    if (filterParams != null && filterParams.hasFilters) {
      return repo.getExplore(
        mode: mode,
        ageMin: filterParams.ageMin,
        ageMax: filterParams.ageMax,
        city: effectiveCity,
        religion: filterParams.religion,
        education: filterParams.education,
        heightMinCm: filterParams.heightMinCm,
        heightMaxCm: filterParams.heightMaxCm,
        diet: filterParams.diet,
        bodyType: filterParams.bodyType,
        maritalStatus: filterParams.maritalStatus,
        motherTongue: filterParams.motherTongue,
        limit: 20,
      );
    }
    return repo.getRecommended(mode: mode, city: travelCity, limit: 20);
  }

  // No overrides — share the paginated first page to avoid a duplicate HTTP call.
  final paginated = await ref.watch(recommendedPaginatedProvider.future);
  if (paginated.profiles.isNotEmpty) {
    return paginated.profiles;
  }
  // Belt-and-suspenders: if the shared paginated state is still empty, pull explore once
  // (e.g. transient failure on the parallel recommended+explore first load).
  debugPrint('[Discovery] Recommended feed empty; explore fallback for swipe stack');
  return repo.getExplore(mode: mode, limit: 20);
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

/// Matrimony full profile: merges [GET /profile/:id] with [GET /summary] so photos
/// and card-level fields stay in sync when the full payload is sparse or degraded.
final matrimonyProfileViewProvider = FutureProvider.autoDispose
    .family<UserProfile?, String>((ref, userId) async {
      final repo = ref.watch(profileRepositoryProvider);
      final results = await Future.wait([
        repo.getProfile(userId),
        repo.getProfileSummary(userId),
      ]);
      final full = results[0] as UserProfile?;
      final summary = results[1] as ProfileSummary?;
      if (full == null) return null;
      return mergeFullUserProfileWithSummary(full, summary);
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
/// Not autoDispose so filter options are cached across navigation.
final filterOptionsProvider = FutureProvider<FilterOptions>((ref) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  return repo.getFilterOptions();
});
