import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/app_location_service.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../../../domain/models/mutual_match_entry.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../domain/models/saved_search.dart';

/// Result of a discovery feed that may have used a fallback (widened search).
class DiscoveryFeedResult {
  const DiscoveryFeedResult({
    required this.profiles,
    this.isWidenedSearch = false,
  });
  final List<ProfileSummary> profiles;
  final bool isWidenedSearch;
}

/// State for paginated Recommended or Explore feed (lazy loading).
class PaginatedFeedState {
  const PaginatedFeedState({
    required this.profiles,
    this.nextCursor,
    this.isWidenedSearch = false,
    this.loadingMore = false,
  });
  final List<ProfileSummary> profiles;
  final String? nextCursor;
  final bool isWidenedSearch;
  final bool loadingMore;

  PaginatedFeedState copyWith({
    List<ProfileSummary>? profiles,
    Object? nextCursor = _unchanged,
    bool? isWidenedSearch,
    bool? loadingMore,
  }) =>
      PaginatedFeedState(
        profiles: profiles ?? this.profiles,
        nextCursor: identical(nextCursor, _unchanged) ? this.nextCursor : nextCursor as String?,
        isWidenedSearch: isWidenedSearch ?? this.isWidenedSearch,
        loadingMore: loadingMore ?? this.loadingMore,
      );

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;
}

const _unchanged = Object();

const _recommendedPageSize = 30;
const _explorePageSize = 30;

/// Paginated Recommended feed: first page 30, then load more on scroll.
class RecommendedPaginatedNotifier extends AutoDisposeAsyncNotifier<PaginatedFeedState> {
  @override
  Future<PaginatedFeedState> build() async {
    final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
    final repo = ref.read(discoveryRepositoryProvider);
    final page = await repo.getRecommendedPage(
      mode: mode,
      limit: _recommendedPageSize,
      cursor: null,
    );
    if (page.profiles.isNotEmpty) {
      return PaginatedFeedState(
        profiles: page.profiles,
        nextCursor: page.nextCursor,
        isWidenedSearch: false,
      );
    }
    debugPrint(
      '[Matches] No recommendations; using explore as fallback (paginated).',
    );
    final fallback = await repo.getExplorePage(
      mode: mode,
      limit: _recommendedPageSize,
      cursor: null,
    );
    return PaginatedFeedState(
      profiles: fallback.profiles,
      nextCursor: fallback.nextCursor,
      isWidenedSearch: fallback.profiles.isNotEmpty,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null ||
        current.loadingMore ||
        !current.hasMore) return;
    state = AsyncValue.data(current.copyWith(loadingMore: true));
    try {
      final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
      final repo = ref.read(discoveryRepositoryProvider);
      final page = await repo.getRecommendedPage(
        mode: mode,
        limit: _recommendedPageSize,
        cursor: current.nextCursor,
      );
      final updated = current.copyWith(
        profiles: [...current.profiles, ...page.profiles],
        nextCursor: page.nextCursor,
        loadingMore: false,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.data(current.copyWith(loadingMore: false));
      state = AsyncValue.error(e, st);
    }
  }
}

final recommendedPaginatedProvider =
    AsyncNotifierProvider.autoDispose<RecommendedPaginatedNotifier, PaginatedFeedState>(
  RecommendedPaginatedNotifier.new,
);

/// Paginated Explore (Search) feed: first page 30, then load more on scroll.
class ExplorePaginatedNotifier
    extends AutoDisposeFamilyAsyncNotifier<PaginatedFeedState,
        ({AppMode mode, MatchesSearchFilters filters})> {
  @override
  Future<PaginatedFeedState> build(
    ({AppMode mode, MatchesSearchFilters filters}) arg,
  ) async {
    final repo = ref.read(discoveryRepositoryProvider);
    final page = await repo.getExplorePage(
      mode: arg.mode,
      ageMin: arg.filters.ageMin,
      ageMax: arg.filters.ageMax,
      city: arg.filters.city,
      religion: arg.filters.religion,
      education: arg.filters.education,
      heightMinCm: arg.filters.heightMinCm,
      diet: arg.filters.diet,
      limit: _explorePageSize,
      cursor: null,
    );
    return PaginatedFeedState(
      profiles: page.profiles,
      nextCursor: page.nextCursor,
      isWidenedSearch: false,
    );
  }

  /// Call with the same (mode, filters) used to watch the provider.
  Future<void> loadMore(({AppMode mode, MatchesSearchFilters filters}) arg) async {
    final current = state.valueOrNull;
    if (current == null ||
        current.loadingMore ||
        !current.hasMore) return;
    state = AsyncValue.data(current.copyWith(loadingMore: true));
    try {
      final repo = ref.read(discoveryRepositoryProvider);
      final page = await repo.getExplorePage(
        mode: arg.mode,
        ageMin: arg.filters.ageMin,
        ageMax: arg.filters.ageMax,
        city: arg.filters.city,
        religion: arg.filters.religion,
        education: arg.filters.education,
        heightMinCm: arg.filters.heightMinCm,
        diet: arg.filters.diet,
        limit: _explorePageSize,
        cursor: current.nextCursor,
      );
      final updated = current.copyWith(
        profiles: [...current.profiles, ...page.profiles],
        nextCursor: page.nextCursor,
        loadingMore: false,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.data(current.copyWith(loadingMore: false));
      state = AsyncValue.error(e, st);
    }
  }
}

final explorePaginatedProvider =
    AsyncNotifierProvider.autoDispose.family<
        ExplorePaginatedNotifier,
        PaginatedFeedState,
        ({AppMode mode, MatchesSearchFilters filters})>(
  ExplorePaginatedNotifier.new,
);

final matchesRecommendedProvider =
    FutureProvider.autoDispose<List<ProfileSummary>>((ref) async {
      final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
      final repo = ref.watch(discoveryRepositoryProvider);
      debugPrint('[Matches] Fetching recommended profiles (mode=$mode)...');
      final results = await repo.getRecommended(mode: mode, limit: 20);
      debugPrint('[Matches] Got ${results.length} recommended profiles');
      return results;
    });

/// Recommendations with fallback: if recommended returns 0, call explore with no filters and show "We've widened the search" banner.
final matchesRecommendedWithFallbackProvider =
    FutureProvider.autoDispose<DiscoveryFeedResult>((ref) async {
      final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
      final repo = ref.watch(discoveryRepositoryProvider);
      final results = await repo.getRecommended(mode: mode, limit: 20);
      if (results.isNotEmpty) {
        return DiscoveryFeedResult(profiles: results);
      }
      debugPrint(
        '[Matches] No recommendations (backend may have returned count-only); '
        'using explore with no filters as fallback.',
      );
      final fallback = await repo.getExplore(mode: mode, limit: 20);
      debugPrint('[Matches] Fallback explore returned ${fallback.length} profiles');
      return DiscoveryFeedResult(
        profiles: fallback,
        isWidenedSearch: fallback.isNotEmpty,
      );
    });

/// Mutual matches (GET /matches). Used for Matches tab and to exclude from Explore.
final mutualMatchesProvider =
    FutureProvider.autoDispose<List<MutualMatchEntry>>((ref) async {
      final repo = ref.watch(matchesRepositoryProvider);
      return repo.getMatches(page: 1, limit: 100);
    });

/// Set of user IDs we are already matched with. Use to hide them from Explore.
final matchedUserIdsProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) async {
  final list = await ref.watch(mutualMatchesProvider.future);
  return list.map((e) => e.profile.id).toSet();
});

/// Explore tab: GET /discovery/explore with mode + optional filters. No filters = everyone in mode.
final matchesExploreProvider = FutureProvider.autoDispose
    .family<
      List<ProfileSummary>,
      ({AppMode mode, MatchesSearchFilters filters})
    >((ref, args) async {
      final repo = ref.watch(discoveryRepositoryProvider);
      debugPrint(
        '[Matches] Fetching explore (mode=${args.mode}, hasFilters=${_hasFilters(args.filters)})...',
      );
      final results = await repo.getExplore(
        mode: args.mode,
        ageMin: args.filters.ageMin,
        ageMax: args.filters.ageMax,
        city: args.filters.city,
        religion: args.filters.religion,
        education: args.filters.education,
        heightMinCm: args.filters.heightMinCm,
        diet: args.filters.diet,
        limit: 20,
      );
      debugPrint('[Matches] Explore got ${results.length} profiles');
      return results;
    });

/// Explore with fallback: if explore returns 0 with filters, retry with relaxed filters (respecting strict from filter-options) and set isWidenedSearch.
final matchesExploreWithFallbackProvider = FutureProvider.autoDispose
    .family<
      DiscoveryFeedResult,
      ({AppMode mode, MatchesSearchFilters filters})
    >((ref, args) async {
      final repo = ref.watch(discoveryRepositoryProvider);
      final opts = await ref.watch(filterOptionsProvider.future);
      final filters = args.filters;

      Future<List<ProfileSummary>> fetch(MatchesSearchFilters f) =>
          repo.getExplore(
            mode: args.mode,
            ageMin: f.ageMin,
            ageMax: f.ageMax,
            city: f.city,
            religion: f.religion,
            education: f.education,
            heightMinCm: f.heightMinCm,
            diet: f.diet,
            limit: 20,
          );

      final first = await fetch(filters);
      if (first.isNotEmpty) return DiscoveryFeedResult(profiles: first);

      if (!_hasFilters(filters)) return DiscoveryFeedResult(profiles: first);

      // Build relaxed filter sets (drop one non-strict dimension at a time). Build explicitly so we can clear a field to null.
      final candidates = <MatchesSearchFilters>[];
      if (filters.diet != null &&
          filters.diet!.isNotEmpty &&
          opts.diet?.strict != true) {
        candidates.add(
          MatchesSearchFilters(
            ageMin: filters.ageMin,
            ageMax: filters.ageMax,
            city: filters.city,
            religion: filters.religion,
            education: filters.education,
            heightMinCm: filters.heightMinCm,
            diet: null,
          ),
        );
      }
      if (filters.city != null &&
          filters.city!.isNotEmpty &&
          !opts.cities.strict) {
        candidates.add(
          MatchesSearchFilters(
            ageMin: filters.ageMin,
            ageMax: filters.ageMax,
            city: null,
            religion: filters.religion,
            education: filters.education,
            heightMinCm: filters.heightMinCm,
            diet: filters.diet,
          ),
        );
      }
      if (filters.religion != null &&
          filters.religion!.isNotEmpty &&
          !opts.religions.strict) {
        candidates.add(
          MatchesSearchFilters(
            ageMin: filters.ageMin,
            ageMax: filters.ageMax,
            city: filters.city,
            religion: null,
            education: filters.education,
            heightMinCm: filters.heightMinCm,
            diet: filters.diet,
          ),
        );
      }
      if (filters.education != null &&
          filters.education!.isNotEmpty &&
          !opts.education.strict) {
        candidates.add(
          MatchesSearchFilters(
            ageMin: filters.ageMin,
            ageMax: filters.ageMax,
            city: filters.city,
            religion: filters.religion,
            education: null,
            heightMinCm: filters.heightMinCm,
            diet: filters.diet,
          ),
        );
      }
      if (filters.heightMinCm != null) {
        candidates.add(
          MatchesSearchFilters(
            ageMin: filters.ageMin,
            ageMax: filters.ageMax,
            city: filters.city,
            religion: filters.religion,
            education: filters.education,
            heightMinCm: null,
            diet: filters.diet,
          ),
        );
      }
      if ((filters.ageMin != null || filters.ageMax != null) &&
          !opts.age.strict) {
        candidates.add(
          MatchesSearchFilters(
            ageMin: null,
            ageMax: null,
            city: filters.city,
            religion: filters.religion,
            education: filters.education,
            heightMinCm: filters.heightMinCm,
            diet: filters.diet,
          ),
        );
      }
      candidates.add(const MatchesSearchFilters()); // no filters

      for (final relaxed in candidates) {
        final results = await fetch(relaxed);
        if (results.isNotEmpty) {
          debugPrint(
            '[Matches] Explore fallback: got ${results.length} with relaxed filters',
          );
          return DiscoveryFeedResult(profiles: results, isWidenedSearch: true);
        }
      }
      return DiscoveryFeedResult(profiles: []);
    });

bool _hasFilters(MatchesSearchFilters f) =>
    f.ageMin != null ||
    f.ageMax != null ||
    (f.city != null && f.city!.isNotEmpty) ||
    (f.religion != null && f.religion!.isNotEmpty) ||
    (f.education != null && f.education!.isNotEmpty) ||
    f.heightMinCm != null ||
    (f.diet != null && f.diet!.isNotEmpty);

final matchesSearchProvider = FutureProvider.autoDispose
    .family<List<ProfileSummary>, MatchesSearchFilters>((ref, filters) async {
      final repo = ref.watch(discoveryRepositoryProvider);
      return repo.search(
        ageMin: filters.ageMin,
        ageMax: filters.ageMax,
        city: filters.city,
        religion: filters.religion,
        education: filters.education,
        heightMinCm: filters.heightMinCm,
        diet: filters.diet,
        limit: 20,
      );
    });

final matchesNearbyProvider = FutureProvider.autoDispose<List<ProfileSummary>>((
  ref,
) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  final loc = await AppLocationService.instance.getCurrentCreationLocation();
  final lat = loc?.latitude ?? 19.076;
  final lng = loc?.longitude ?? 72.877;
  return repo.getNearby(lat: lat, lng: lng, radiusKm: 25, limit: 20);
});

/// Visitors (who viewed my profile). Uses GET /visits/received and marks as seen on load.
final visitorsProvider = FutureProvider.autoDispose<List<ProfileSummary>>((
  ref,
) async {
  final repo = ref.watch(visitsRepositoryProvider);
  final result = await repo.getVisitors(page: 1, limit: 50);
  await repo.markVisitorsSeen();
  return result.visitors.map((e) => e.visitor).toList();
});

/// Records a profile visit when viewing someone's full profile (POST /visits). Fire-and-forget.
final recordProfileVisitProvider = FutureProvider.autoDispose
    .family<void, String>((ref, profileId) async {
      final repo = ref.read(visitsRepositoryProvider);
      await repo.recordVisit(profileId, source: 'profile_view');
    });

/// Saved searches (matrimony). GET /discovery/saved-searches.
final savedSearchesProvider = FutureProvider.autoDispose<List<SavedSearch>>((
  ref,
) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  return repo.getSavedSearches();
});

class MatchesSearchFilters {
  const MatchesSearchFilters({
    this.ageMin,
    this.ageMax,
    this.city,
    this.religion,
    this.education,
    this.heightMinCm,
    this.diet,
  });

  final int? ageMin;
  final int? ageMax;
  final String? city;
  final String? religion;
  final String? education;
  final int? heightMinCm;
  final String? diet;

  MatchesSearchFilters copyWith({
    int? ageMin,
    int? ageMax,
    String? city,
    String? religion,
    String? education,
    int? heightMinCm,
    String? diet,
  }) {
    return MatchesSearchFilters(
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      city: city ?? this.city,
      religion: religion ?? this.religion,
      education: education ?? this.education,
      heightMinCm: heightMinCm ?? this.heightMinCm,
      diet: diet ?? this.diet,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchesSearchFilters &&
          ageMin == other.ageMin &&
          ageMax == other.ageMax &&
          city == other.city &&
          religion == other.religion &&
          education == other.education &&
          heightMinCm == other.heightMinCm &&
          diet == other.diet;

  @override
  int get hashCode =>
      Object.hash(ageMin, ageMax, city, religion, education, heightMinCm, diet);

  /// Convert to map for saved-search API (only non-null fields).
  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{};
    if (ageMin != null) m['ageMin'] = ageMin;
    if (ageMax != null) m['ageMax'] = ageMax;
    if (city != null && city!.isNotEmpty) m['city'] = city;
    if (religion != null && religion!.isNotEmpty) m['religion'] = religion;
    if (education != null && education!.isNotEmpty) m['education'] = education;
    if (heightMinCm != null) m['heightMinCm'] = heightMinCm;
    if (diet != null && diet!.isNotEmpty) m['diet'] = diet;
    return m;
  }

  /// Create from saved-search filters map (e.g. from API).
  static MatchesSearchFilters fromMap(Map<String, dynamic>? m) {
    if (m == null || m.isEmpty) return const MatchesSearchFilters();
    return MatchesSearchFilters(
      ageMin: m['ageMin'] as int?,
      ageMax: m['ageMax'] as int?,
      city: m['city'] as String?,
      religion: m['religion'] as String?,
      education: m['education'] as String?,
      heightMinCm: m['heightMinCm'] as int?,
      diet: m['diet'] as String?,
    );
  }
}
