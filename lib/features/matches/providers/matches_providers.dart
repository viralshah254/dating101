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
import '../../../domain/models/visitor_entry.dart';

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
class RecommendedPaginatedNotifier extends AsyncNotifier<PaginatedFeedState> {
  @override
  Future<PaginatedFeedState> build() async {
    final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
    final repo = ref.read(discoveryRepositoryProvider);

    // Fire recommended and explore in parallel so that when the backend returns
    // zero recommendations the explore fallback is already in-flight — eliminating
    // the sequential second round-trip that previously added full RTT latency.
    final results = await Future.wait([
      repo.getRecommendedPage(mode: mode, limit: _recommendedPageSize, cursor: null),
      repo.getExplorePage(mode: mode, limit: _explorePageSize, cursor: null),
    ]);
    final recommended = results[0];
    final explore = results[1];

    if (recommended.profiles.isNotEmpty) {
      return PaginatedFeedState(
        profiles: recommended.profiles,
        nextCursor: recommended.nextCursor,
        isWidenedSearch: false,
      );
    }
    debugPrint('[Matches] No recommendations; using explore as fallback (parallel).');
    return PaginatedFeedState(
      profiles: explore.profiles,
      nextCursor: explore.nextCursor,
      isWidenedSearch: explore.profiles.isNotEmpty,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncValue.data(current.copyWith(loadingMore: true));
    try {
      final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
      final repo = ref.read(discoveryRepositoryProvider);
      final page = await repo.getRecommendedPage(
        mode: mode,
        limit: _recommendedPageSize,
        cursor: current.nextCursor,
      );
      final merged = [...current.profiles, ...page.profiles];
      final seen = <String>{};
      final deduped = merged.where((p) => seen.add(p.id)).toList();
      final updated = current.copyWith(
        profiles: deduped,
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
    AsyncNotifierProvider<RecommendedPaginatedNotifier, PaginatedFeedState>(
  RecommendedPaginatedNotifier.new,
);

/// Paginated Explore (Search) feed: first page 30, then load more on scroll.
class ExplorePaginatedNotifier
    extends FamilyAsyncNotifier<PaginatedFeedState,
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
      heightMaxCm: arg.filters.heightMaxCm,
      diet: arg.filters.diet,
      maritalStatus: arg.filters.maritalStatus,
      motherTongue: arg.filters.motherTongue,
      verifiedOnly: arg.filters.verifiedOnly,
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
    if (current == null || current.loadingMore || !current.hasMore) return;
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
        heightMaxCm: arg.filters.heightMaxCm,
        diet: arg.filters.diet,
        maritalStatus: arg.filters.maritalStatus,
        motherTongue: arg.filters.motherTongue,
        verifiedOnly: arg.filters.verifiedOnly,
        limit: _explorePageSize,
        cursor: current.nextCursor,
      );
      final mergedExplore = [...current.profiles, ...page.profiles];
      final seenExplore = <String>{};
      final dedupedExplore = mergedExplore.where((p) => seenExplore.add(p.id)).toList();
      final updated = current.copyWith(
        profiles: dedupedExplore,
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
    AsyncNotifierProvider.family<
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

/// Recommendations with fallback: if recommended returns 0, uses explore with no filters.
/// Both requests are fired in parallel to eliminate sequential round-trip latency.
final matchesRecommendedWithFallbackProvider =
    FutureProvider.autoDispose<DiscoveryFeedResult>((ref) async {
      final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
      final repo = ref.watch(discoveryRepositoryProvider);
      final fetched = await Future.wait([
        repo.getRecommended(mode: mode, limit: 20),
        repo.getExplore(mode: mode, limit: 20),
      ]);
      final recommended = fetched[0];
      final explore = fetched[1];
      if (recommended.isNotEmpty) {
        return DiscoveryFeedResult(profiles: recommended);
      }
      debugPrint('[Matches] No recommendations; explore fallback returned ${explore.length} profiles.');
      return DiscoveryFeedResult(profiles: explore, isWidenedSearch: explore.isNotEmpty);
    });

/// Mutual matches (GET /matches). Used for Matches tab and to exclude from Explore.
final mutualMatchesProvider =
    FutureProvider<List<MutualMatchEntry>>((ref) async {
      final repo = ref.watch(matchesRepositoryProvider);
      return repo.getMatches(page: 1, limit: 100);
    });

/// Set of user IDs we are already matched with. Use to hide them from Explore.
final matchedUserIdsProvider = FutureProvider<Set<String>>((
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
        heightMaxCm: args.filters.heightMaxCm,
        diet: args.filters.diet,
        maritalStatus: args.filters.maritalStatus,
        motherTongue: args.filters.motherTongue,
        verifiedOnly: args.filters.verifiedOnly,
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
            heightMaxCm: f.heightMaxCm,
            diet: f.diet,
            maritalStatus: f.maritalStatus,
            motherTongue: f.motherTongue,
            verifiedOnly: f.verifiedOnly,
            limit: 20,
          );

      final first = await fetch(filters);
      if (first.isNotEmpty) return DiscoveryFeedResult(profiles: first);

      if (!_hasFilters(filters)) return DiscoveryFeedResult(profiles: first);

      // Build relaxed filter sets (drop one non-strict dimension at a time).
      final candidates = <MatchesSearchFilters>[];
      if (filters.motherTongue != null && filters.motherTongue!.isNotEmpty) {
        candidates.add(filters.copyWith(clearMotherTongue: true));
      }
      if (filters.maritalStatus != null &&
          filters.maritalStatus!.isNotEmpty &&
          opts.maritalStatus?.strict != true) {
        candidates.add(filters.copyWith(clearMaritalStatus: true));
      }
      if (filters.diet != null &&
          filters.diet!.isNotEmpty &&
          opts.diet?.strict != true) {
        candidates.add(filters.copyWith(clearDiet: true));
      }
      if (filters.city != null &&
          filters.city!.isNotEmpty &&
          !opts.cities.strict) {
        candidates.add(filters.copyWith(clearCity: true));
      }
      if (filters.religion != null &&
          filters.religion!.isNotEmpty &&
          !opts.religions.strict) {
        candidates.add(filters.copyWith(clearReligion: true));
      }
      if (filters.education != null &&
          filters.education!.isNotEmpty &&
          !opts.education.strict) {
        candidates.add(filters.copyWith(clearEducation: true));
      }
      if (filters.heightMinCm != null) {
        candidates.add(filters.copyWith(clearHeight: true));
      }
      if ((filters.ageMin != null || filters.ageMax != null) &&
          !opts.age.strict) {
        candidates.add(filters.copyWith(clearAge: true));
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
    f.heightMaxCm != null ||
    (f.diet != null && f.diet!.isNotEmpty) ||
    (f.maritalStatus != null && f.maritalStatus!.isNotEmpty) ||
    (f.motherTongue != null && f.motherTongue!.isNotEmpty) ||
    f.verifiedOnly;

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

/// Visitor entries (with visitId) for Likes → Visitors tab. Free users see blurred name+age; unlock via ad (2/week) or premium.
final visitorsEntriesProvider = FutureProvider<List<VisitorEntry>>((
  ref,
) async {
  final repo = ref.watch(visitsRepositoryProvider);
  final result = await repo.getVisitors(page: 1, limit: 50);
  await repo.markVisitorsSeen();
  return result.visitors;
});

/// Visitors (who viewed my profile). Uses GET /visits/received and marks as seen on load.
final visitorsProvider = FutureProvider<List<ProfileSummary>>((
  ref,
) async {
  final result = await ref.watch(visitorsEntriesProvider.future);
  return result.map((e) => e.visitor).toList();
});

/// Visitor unlock quota: remaining unlocks this week (2 max). Set from unlock-one response or 403.
final visitorUnlocksQuotaProvider =
    StateProvider.autoDispose<({int remaining, DateTime? resetsAt})?>((ref) => null);

/// Profile IDs unlocked via "Watch ad" on Visitors tab this session. Premium users don't need unlock.
final unlockedVisitorIdsProvider = StateProvider<Set<String>>((ref) => {});

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

/// Sort options applied client-side to the current page of fetched profiles.
enum SortOption {
  bestMatch,
  recentlyActive,
  youngestFirst,
  oldestFirst,
  nearest;

  String get label {
    switch (this) {
      case SortOption.bestMatch:
        return 'Best Match';
      case SortOption.recentlyActive:
        return 'Recently Active';
      case SortOption.youngestFirst:
        return 'Youngest First';
      case SortOption.oldestFirst:
        return 'Oldest First';
      case SortOption.nearest:
        return 'Nearest';
    }
  }
}

/// Global sort preference, applied in all feed tabs.
final sortByProvider = StateProvider<SortOption>((ref) => SortOption.bestMatch);

/// Apply [sort] to a list of profiles in-memory.
List<ProfileSummary> applySortOption(
  List<ProfileSummary> profiles,
  SortOption sort,
) {
  final list = List<ProfileSummary>.from(profiles);
  switch (sort) {
    case SortOption.bestMatch:
      list.sort(
        (a, b) => (b.compatibilityScore ?? 0).compareTo(
          a.compatibilityScore ?? 0,
        ),
      );
    case SortOption.recentlyActive:
      break; // backend already orders by lastActiveAt
    case SortOption.youngestFirst:
      list.sort((a, b) {
        final ag = a.age, bg = b.age;
        if (ag == null && bg == null) return 0;
        if (ag == null) return 1;
        if (bg == null) return -1;
        return ag.compareTo(bg);
      });
    case SortOption.oldestFirst:
      list.sort((a, b) {
        final ag = a.age, bg = b.age;
        if (ag == null && bg == null) return 0;
        if (ag == null) return 1;
        if (bg == null) return -1;
        return bg.compareTo(ag);
      });
    case SortOption.nearest:
      list.sort((a, b) {
        final ad = a.distanceKm, bd = b.distanceKm;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
  }
  return list;
}

class MatchesSearchFilters {
  const MatchesSearchFilters({
    this.ageMin,
    this.ageMax,
    this.city,
    this.religion,
    this.education,
    this.heightMinCm,
    this.heightMaxCm,
    this.diet,
    this.maritalStatus,
    this.motherTongue,
    this.verifiedOnly = false,
  });

  final int? ageMin;
  final int? ageMax;
  final String? city;
  final String? religion;
  final String? education;
  final int? heightMinCm;
  final int? heightMaxCm;
  final String? diet;
  final String? maritalStatus;
  final String? motherTongue;
  final bool verifiedOnly;

  /// [clearCity]/[clearReligion] etc. set the respective string field to null.
  MatchesSearchFilters copyWith({
    int? ageMin,
    int? ageMax,
    String? city,
    String? religion,
    String? education,
    int? heightMinCm,
    int? heightMaxCm,
    String? diet,
    String? maritalStatus,
    String? motherTongue,
    bool? verifiedOnly,
    bool clearCity = false,
    bool clearReligion = false,
    bool clearEducation = false,
    bool clearDiet = false,
    bool clearMaritalStatus = false,
    bool clearMotherTongue = false,
    bool clearHeight = false,
    bool clearAge = false,
  }) {
    return MatchesSearchFilters(
      ageMin: clearAge ? null : (ageMin ?? this.ageMin),
      ageMax: clearAge ? null : (ageMax ?? this.ageMax),
      city: clearCity ? null : (city ?? this.city),
      religion: clearReligion ? null : (religion ?? this.religion),
      education: clearEducation ? null : (education ?? this.education),
      heightMinCm: clearHeight ? null : (heightMinCm ?? this.heightMinCm),
      heightMaxCm: clearHeight ? null : (heightMaxCm ?? this.heightMaxCm),
      diet: clearDiet ? null : (diet ?? this.diet),
      maritalStatus: clearMaritalStatus ? null : (maritalStatus ?? this.maritalStatus),
      motherTongue: clearMotherTongue ? null : (motherTongue ?? this.motherTongue),
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
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
          heightMaxCm == other.heightMaxCm &&
          diet == other.diet &&
          maritalStatus == other.maritalStatus &&
          motherTongue == other.motherTongue &&
          verifiedOnly == other.verifiedOnly;

  @override
  int get hashCode => Object.hash(
        ageMin, ageMax, city, religion, education,
        heightMinCm, heightMaxCm, diet, maritalStatus, motherTongue,
        verifiedOnly,
      );

  /// Convert to map for saved-search API (only non-null fields).
  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{};
    if (ageMin != null) m['ageMin'] = ageMin;
    if (ageMax != null) m['ageMax'] = ageMax;
    if (city != null && city!.isNotEmpty) m['city'] = city;
    if (religion != null && religion!.isNotEmpty) m['religion'] = religion;
    if (education != null && education!.isNotEmpty) m['education'] = education;
    if (heightMinCm != null) m['heightMinCm'] = heightMinCm;
    if (heightMaxCm != null) m['heightMaxCm'] = heightMaxCm;
    if (diet != null && diet!.isNotEmpty) m['diet'] = diet;
    if (maritalStatus != null && maritalStatus!.isNotEmpty) m['maritalStatus'] = maritalStatus;
    if (motherTongue != null && motherTongue!.isNotEmpty) m['motherTongue'] = motherTongue;
    if (verifiedOnly) m['verifiedOnly'] = true;
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
      heightMaxCm: m['heightMaxCm'] as int?,
      diet: m['diet'] as String?,
      maritalStatus: m['maritalStatus'] as String?,
      motherTongue: m['motherTongue'] as String?,
      verifiedOnly: m['verifiedOnly'] as bool? ?? false,
    );
  }
}
