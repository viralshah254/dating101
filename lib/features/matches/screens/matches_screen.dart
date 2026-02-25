import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../../requests/providers/requests_providers.dart';
import '../../shortlist/providers/shortlist_providers.dart';
import '../providers/matches_providers.dart';
import '../widgets/match_profile_card.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  MatchesSearchFilters _filters = const MatchesSearchFilters();
  int _activeFilterCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateFilterCount() {
    int c = 0;
    if (_filters.ageMin != null || _filters.ageMax != null) c++;
    if (_filters.city != null && _filters.city!.isNotEmpty) c++;
    if (_filters.religion != null && _filters.religion!.isNotEmpty) c++;
    if (_filters.education != null && _filters.education!.isNotEmpty) c++;
    if (_filters.heightMinCm != null) c++;
    setState(() => _activeFilterCount = c);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.indiaGreen;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: true,
            title: Text(
              l.navMatches,
              style: AppTypography.headlineSmall.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              _FilterButton(
                activeCount: _activeFilterCount,
                accent: accent,
                onTap: () => _showFilterSheet(context, ref),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _TabBarSection(
                controller: _tabController,
                accent: accent,
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _RecommendedTab(
              onTapProfile: _openProfile,
              onLike: _onLike,
              onSuperLike: _onSuperLike,
              onShortlist: _onShortlist,
              onMessage: _onMessage,
              onUpgrade: _onUpgrade,
            ),
            _VisitorsTab(
              onTapProfile: _openProfile,
              onLike: _onLike,
              onSuperLike: _onSuperLike,
              onShortlist: _onShortlist,
              onMessage: _onMessage,
              onUpgrade: _onUpgrade,
            ),
            _ExploreTab(
              filters: _filters,
              onTapProfile: _openProfile,
              onLike: _onLike,
              onSuperLike: _onSuperLike,
              onShortlist: _onShortlist,
              onMessage: _onMessage,
              onUpgrade: _onUpgrade,
            ),
          ],
        ),
      ),
    );
  }

  void _openProfile(ProfileSummary p) => context.push('/profile/${p.id}');

  void _onLike(ProfileSummary p) async {
    try {
      final repo = ref.read(interactionsRepositoryProvider);
      final result = await repo.expressInterest(p.id, source: 'recommended');
      if (!mounted) return;
      ref.invalidate(matchesRecommendedProvider);
      ref.invalidate(matchesSearchProvider);
      ref.invalidate(matchesNearbyProvider);
      ref.invalidate(sentInteractionsProvider);
      if (result.mutualMatch && result.chatThreadId != null) {
        context.push('/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(p.id)}');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _onSuperLike(ProfileSummary p) {
    _showPriorityInterestDialog(p);
  }

  Future<void> _showPriorityInterestDialog(ProfileSummary p) async {
    final message = await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _PriorityInterestDialog(profileName: p.name),
    );
    if (!mounted) return;
    try {
      final repo = ref.read(interactionsRepositoryProvider);
      final result = await repo.expressPriorityInterest(
        p.id,
        message: message,
        source: 'recommended',
      );
      if (!mounted) return;
      ref.invalidate(matchesRecommendedProvider);
      ref.invalidate(matchesSearchProvider);
      ref.invalidate(matchesNearbyProvider);
      ref.invalidate(sentInteractionsProvider);
      if (result.mutualMatch && result.chatThreadId != null) {
        context.push('/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(p.id)}');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _onShortlist(ProfileSummary p) async {
    try {
      await ref.read(shortlistRepositoryProvider).addToShortlist(p.id);
      if (!mounted) return;
      ref.invalidate(shortlistProvider);
      ref.invalidate(shortlistedIdsProvider);
      ref.invalidate(matchesRecommendedProvider);
      ref.invalidate(matchesSearchProvider);
      ref.invalidate(matchesNearbyProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _onMessage(ProfileSummary p) async {
    try {
      final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
      final modeStr = mode.isMatrimony ? 'matrimony' : 'dating';
      final threadId = await ref.read(chatRepositoryProvider).createThread(p.id, mode: modeStr);
      if (!mounted) return;
      context.push('/chat/$threadId?otherUserId=${Uri.encodeComponent(p.id)}');
    } catch (_) {
      if (!mounted) return;
      context.push('/chats');
    }
  }

  void _onUpgrade() => context.push('/paywall');

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.indiaGreen;
    final surface = Theme.of(context).colorScheme.surface;

    final filterOptionsAsync = ref.read(filterOptionsProvider);

    RangeValues ageRange = RangeValues(
      (_filters.ageMin ?? 21).toDouble(),
      (_filters.ageMax ?? 45).toDouble(),
    );
    String? city = _filters.city;
    String? religion = _filters.religion;
    String? education = _filters.education;

    final opts = filterOptionsAsync.valueOrNull;
    final ageMin = opts?.age.min ?? 18;
    final ageMax = opts?.age.max ?? 60;
    final defaultAgeMin = opts?.age.defaultMin ?? 21;
    final defaultAgeMax = opts?.age.defaultMax ?? 45;
    if (opts != null && _filters.ageMin == null && _filters.ageMax == null) {
      ageRange = RangeValues(defaultAgeMin.toDouble(), defaultAgeMax.toDouble());
    }
    final cities = opts?.cities.options.isNotEmpty == true
        ? opts!.cities.options
        : const [
            'London', 'Mumbai', 'Delhi', 'Dubai', 'New York', 'Bangalore',
          ];
    final religions = opts?.religions.options.isNotEmpty == true
        ? opts!.religions.options
        : const [
            'Hindu', 'Muslim', 'Christian', 'Sikh', 'Jain', 'Buddhist',
          ];
    final educationOptions = opts?.education.options.isNotEmpty == true
        ? opts!.education.options
        : const [
            "Bachelor's", "Master's", 'Doctorate', 'Diploma', 'High School',
          ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.filters,
                          style: AppTypography.headlineSmall.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              ageRange = RangeValues(defaultAgeMin.toDouble(), defaultAgeMax.toDouble());
                              city = null;
                              religion = null;
                              education = null;
                            });
                          },
                          child: Text(
                            'Clear all',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FilterSection(
                            label: 'Age range',
                            onSurface: onSurface,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${ageRange.start.round()}',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${ageRange.end.round()}',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                RangeSlider(
                                  values: ageRange,
                                  min: ageMin.toDouble(),
                                  max: ageMax.toDouble(),
                                  divisions: (ageMax - ageMin).clamp(1, 50),
                                  activeColor: accent,
                                  onChanged: (v) => setSheetState(() => ageRange = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FilterSection(
                            label: 'City',
                            onSurface: onSurface,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: cities
                                  .map((c) => _ChoiceChipFilter(
                                        label: c,
                                        selected: city == c,
                                        accent: accent,
                                        onTap: () => setSheetState(
                                            () => city = city == c ? null : c),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FilterSection(
                            label: 'Religion',
                            onSurface: onSurface,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: religions
                                  .map((r) => _ChoiceChipFilter(
                                        label: r,
                                        selected: religion == r,
                                        accent: accent,
                                        onTap: () => setSheetState(
                                            () => religion = religion == r ? null : r),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FilterSection(
                            label: 'Education',
                            onSurface: onSurface,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: educationOptions
                                  .map((e) => _ChoiceChipFilter(
                                        label: e,
                                        selected: education == e,
                                        accent: accent,
                                        onTap: () => setSheetState(() =>
                                            education = education == e ? null : e),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      12 + MediaQuery.of(ctx).padding.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border(
                        top: BorderSide(
                          color: onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              final ageMinVal = ageRange.start.round();
                              final ageMaxVal = ageRange.end.round();
                              _filters = MatchesSearchFilters(
                                ageMin: ageMinVal == defaultAgeMin ? null : ageMinVal,
                                ageMax: ageMaxVal == defaultAgeMax ? null : ageMaxVal,
                                city: city,
                                religion: religion,
                                education: education,
                              );
                              _updateFilterCount();
                              if (_activeFilterCount > 0) {
                                _tabController.animateTo(1);
                              }
                            });
                            Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            l.apply,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Tabs ───────────────────────────────────────────────────────────────

class _TabBarSection extends StatelessWidget {
  const _TabBarSection({required this.controller, required this.accent});
  final TabController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: onSurface.withValues(alpha: 0.6),
        labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.labelLarge,
        tabs: const [
          Tab(text: 'For You', height: 38),
          Tab(text: 'Visitors', height: 38),
          Tab(text: 'Explore', height: 38),
        ],
      ),
    );
  }
}

// ─── Recommended tab ────────────────────────────────────────────────────

class _RecommendedTab extends ConsumerWidget {
  const _RecommendedTab({
    required this.onTapProfile,
    required this.onLike,
    required this.onSuperLike,
    required this.onShortlist,
    required this.onMessage,
    required this.onUpgrade,
  });
  final void Function(ProfileSummary) onTapProfile;
  final void Function(ProfileSummary) onLike;
  final void Function(ProfileSummary) onSuperLike;
  final void Function(ProfileSummary) onShortlist;
  final void Function(ProfileSummary) onMessage;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortlistedIds = ref.watch(shortlistedIdsProvider).valueOrNull ?? <String>{};
    final sentInterestIds = ref.watch(sentInterestProfileIdsProvider).valueOrNull ?? <String>{};
    final sentPriorityIds = ref.watch(sentPriorityInterestProfileIdsProvider).valueOrNull ?? <String>{};
    final async = ref.watch(matchesRecommendedProvider);
    return async.when(
      data: (profiles) => _ProfileList(
        profiles: profiles,
        shortlistedIds: shortlistedIds,
        sentInterestIds: sentInterestIds,
        sentPriorityInterestIds: sentPriorityIds,
        onTap: onTapProfile,
        onLike: onLike,
        onSuperLike: onSuperLike,
        onShortlist: onShortlist,
        onMessage: onMessage,
        onUpgrade: onUpgrade,
        emptyIcon: Icons.diversity_3_rounded,
        emptyTitle: 'No recommendations yet',
        emptyBody: 'Complete your profile and preferences to get AI-powered matches.',
      ),
      loading: () => const _ShimmerList(),
      error: (_, __) => _ErrorState(onRetry: () => ref.invalidate(matchesRecommendedProvider)),
    );
  }
}

// ─── Visitors tab (who viewed your profile) ─────────────────────────────

class _VisitorsTab extends ConsumerWidget {
  const _VisitorsTab({
    required this.onTapProfile,
    required this.onLike,
    required this.onSuperLike,
    required this.onShortlist,
    required this.onMessage,
    required this.onUpgrade,
  });
  final void Function(ProfileSummary) onTapProfile;
  final void Function(ProfileSummary) onLike;
  final void Function(ProfileSummary) onSuperLike;
  final void Function(ProfileSummary) onShortlist;
  final void Function(ProfileSummary) onMessage;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortlistedIds = ref.watch(shortlistedIdsProvider).valueOrNull ?? <String>{};
    final sentInterestIds = ref.watch(sentInterestProfileIdsProvider).valueOrNull ?? <String>{};
    final sentPriorityIds = ref.watch(sentPriorityInterestProfileIdsProvider).valueOrNull ?? <String>{};
    final async = ref.watch(visitorsProvider);
    return async.when(
      data: (profiles) => _ProfileList(
        profiles: profiles,
        shortlistedIds: shortlistedIds,
        sentInterestIds: sentInterestIds,
        sentPriorityInterestIds: sentPriorityIds,
        onTap: onTapProfile,
        onLike: onLike,
        onSuperLike: onSuperLike,
        onShortlist: onShortlist,
        onMessage: onMessage,
        onUpgrade: onUpgrade,
        emptyIcon: Icons.visibility_outlined,
        emptyTitle: 'No visitors yet',
        emptyBody: 'Profiles who viewed you will appear here. Complete your profile to get noticed.',
      ),
      loading: () => const _ShimmerList(),
      error: (_, __) => _ErrorState(onRetry: () => ref.invalidate(visitorsProvider)),
    );
  }
}

// ─── Explore tab (search / filter) ──────────────────────────────────────

class _ExploreTab extends ConsumerWidget {
  const _ExploreTab({
    required this.filters,
    required this.onTapProfile,
    required this.onLike,
    required this.onSuperLike,
    required this.onShortlist,
    required this.onMessage,
    required this.onUpgrade,
  });
  final MatchesSearchFilters filters;
  final void Function(ProfileSummary) onTapProfile;
  final void Function(ProfileSummary) onLike;
  final void Function(ProfileSummary) onSuperLike;
  final void Function(ProfileSummary) onShortlist;
  final void Function(ProfileSummary) onMessage;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFilters = filters.ageMin != null ||
        filters.ageMax != null ||
        (filters.city != null && filters.city!.isNotEmpty) ||
        (filters.religion != null && filters.religion!.isNotEmpty) ||
        (filters.education != null && filters.education!.isNotEmpty);

    if (!hasFilters) {
      return const _EmptyState(
        icon: Icons.explore_outlined,
        title: 'Explore profiles',
        body: 'Use the filter icon above to search by age, city, religion, education and more.',
      );
    }

    final shortlistedIds = ref.watch(shortlistedIdsProvider).valueOrNull ?? <String>{};
    final sentInterestIds = ref.watch(sentInterestProfileIdsProvider).valueOrNull ?? <String>{};
    final sentPriorityIds = ref.watch(sentPriorityInterestProfileIdsProvider).valueOrNull ?? <String>{};
    final async = ref.watch(matchesSearchProvider(filters));
    return async.when(
      data: (profiles) => _ProfileList(
        profiles: profiles,
        shortlistedIds: shortlistedIds,
        sentInterestIds: sentInterestIds,
        sentPriorityInterestIds: sentPriorityIds,
        onTap: onTapProfile,
        onLike: onLike,
        onSuperLike: onSuperLike,
        onShortlist: onShortlist,
        onMessage: onMessage,
        onUpgrade: onUpgrade,
        emptyIcon: Icons.search_off,
        emptyTitle: 'No matches found',
        emptyBody: 'Try adjusting your filters for more results.',
      ),
      loading: () => const _ShimmerList(),
      error: (_, __) => _ErrorState(
        onRetry: () => ref.invalidate(matchesSearchProvider(filters)),
      ),
    );
  }
}

// ─── Shared widgets ─────────────────────────────────────────────────────

class _ProfileList extends StatelessWidget {
  const _ProfileList({
    required this.profiles,
    this.shortlistedIds,
    this.sentInterestIds,
    this.sentPriorityInterestIds,
    required this.onTap,
    required this.onLike,
    required this.onSuperLike,
    required this.onShortlist,
    required this.onMessage,
    required this.onUpgrade,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyBody,
  });
  final List<ProfileSummary> profiles;
  final Set<String>? shortlistedIds;
  final Set<String>? sentInterestIds;
  final Set<String>? sentPriorityInterestIds;
  final void Function(ProfileSummary) onTap;
  final void Function(ProfileSummary) onLike;
  final void Function(ProfileSummary) onSuperLike;
  final void Function(ProfileSummary) onShortlist;
  final void Function(ProfileSummary) onMessage;
  final VoidCallback onUpgrade;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyBody;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return _EmptyState(icon: emptyIcon, title: emptyTitle, body: emptyBody);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: profiles.length,
      itemBuilder: (context, i) {
        final p = profiles[i];
        final isShortlisted = shortlistedIds?.contains(p.id) ?? false;
        final isInterested = sentInterestIds?.contains(p.id) ?? false;
        final isPriorityInterested = sentPriorityInterestIds?.contains(p.id) ?? false;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MatchProfileCard(
            profile: p,
            isShortlisted: isShortlisted,
            isInterested: isInterested,
            isPriorityInterested: isPriorityInterested,
            onTap: () => onTap(p),
            onLike: () => onLike(p),
            onSuperLike: () => onSuperLike(p),
            onShortlist: () => onShortlist(p),
            onMessage: () => onMessage(p),
            onUpgrade: onUpgrade,
          ).animate().fadeIn(delay: (40 * i).ms).slideY(begin: 0.04, end: 0),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.indiaGreen;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: accent.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: AppTypography.bodyMedium.copyWith(
                color: onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l.errorGeneric, style: AppTypography.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.indiaGreen),
              child: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 4,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: onSurface.withValues(alpha: 0.06)),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.activeCount,
    required this.accent,
    required this.onTap,
  });
  final int activeCount;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: activeCount > 0
                    ? accent.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: activeCount > 0 ? accent : null,
              ),
            ),
            if (activeCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.label,
    required this.onSurface,
    required this.child,
  });
  final String label;
  final Color onSurface;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChoiceChipFilter extends StatelessWidget {
  const _ChoiceChipFilter({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent : accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent : accent.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: selected ? Colors.white : accent,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Dialog to add an optional message when sending priority interest.
class _PriorityInterestDialog extends StatefulWidget {
  const _PriorityInterestDialog({required this.profileName});
  final String profileName;

  @override
  State<_PriorityInterestDialog> createState() => _PriorityInterestDialogState();
}

class _PriorityInterestDialogState extends State<_PriorityInterestDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.saffron;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.star_rounded, color: accent, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Priority interest',
              style: AppTypography.titleLarge.copyWith(color: onSurface, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a message to stand out (optional)',
            style: AppTypography.bodyMedium.copyWith(color: onSurface.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. Hi! I loved your profile...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Skip', style: TextStyle(color: onSurface.withValues(alpha: 0.7))),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            Navigator.of(context).pop(text.isEmpty ? null : text);
          },
          style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
          child: const Text('Send priority interest'),
        ),
      ],
    );
  }
}
