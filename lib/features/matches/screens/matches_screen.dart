import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/safety/safety_reason_picker.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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
    final accent = AppColors.lightAccent;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: true,
            title: Text(
              l.navDiscover,
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
              onBlock: _onBlock,
              onReport: _onReport,
            ),
            _VisitorsTab(
              onTapProfile: _openProfile,
              onLike: _onLike,
              onSuperLike: _onSuperLike,
              onShortlist: _onShortlist,
              onMessage: _onMessage,
              onUpgrade: _onUpgrade,
              onBlock: _onBlock,
              onReport: _onReport,
            ),
            _ExploreTab(
              filters: _filters,
              onTapProfile: _openProfile,
              onLike: _onLike,
              onSuperLike: _onSuperLike,
              onShortlist: _onShortlist,
              onMessage: _onMessage,
              onUpgrade: _onUpgrade,
              onBlock: _onBlock,
              onReport: _onReport,
            ),
            _MatchesTab(
              onTapProfile: _openProfile,
              onMessage: _onMessage,
              onBlock: _onBlock,
              onReport: _onReport,
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
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.code == 'CONNECTION_REQUIRED' ? 'Send or accept an interest first' : e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push('/chats');
    } catch (_) {
      if (!mounted) return;
      context.push('/chats');
    }
  }

  void _onUpgrade() => context.push('/paywall');

  Future<void> _onBlock(ProfileSummary p) async {
    final l = AppLocalizations.of(context)!;
    final reason = await showBlockReasonPicker(context);
    if (reason == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.block),
        content: Text(
          '${l.block} ${p.name}? They won\'t be able to see your profile or contact you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l.block),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(safetyRepositoryProvider).block(
            p.id,
            reason,
            source: 'discover',
          );
      if (!mounted) return;
      ref.invalidate(matchesRecommendedProvider);
      ref.invalidate(matchesExploreProvider);
      ref.invalidate(mutualMatchesProvider);
      ref.invalidate(matchedUserIdsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.name} ${l.block.toLowerCase()}ed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Something went wrong. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _onReport(ProfileSummary p) async {
    final l = AppLocalizations.of(context)!;
    final result = await showReportReasonPicker(context);
    if (result == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.report),
        content: Text(
          '${l.report} ${p.name}? We take safety seriously and will review this profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l.report),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(safetyRepositoryProvider).report(
            p.id,
            result.reason,
            details: result.details,
            source: 'discover',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report submitted. Thank you.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Something went wrong. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.lightAccent;
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
                          Consumer(
                            builder: (ctx, ref, _) {
                              final savedAsync = ref.watch(savedSearchesProvider);
                              return savedAsync.when(
                                data: (list) {
                                  if (list.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _FilterSection(
                                      label: 'Saved searches',
                                      onSurface: onSurface,
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: list.map((ss) {
                                          return ActionChip(
                                            avatar: ss.newMatchCount > 0
                                                ? CircleAvatar(
                                                    backgroundColor: accent,
                                                    child: Text(
                                                      '${ss.newMatchCount}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                            label: Text(ss.displayName),
                                            onPressed: () {
                                              setState(() {
                                                _filters = MatchesSearchFilters.fromMap(ss.filters);
                                                _updateFilterCount();
                                              });
                                              ref.read(discoveryRepositoryProvider).markSavedSearchViewed(ss.id);
                                              ref.invalidate(savedSearchesProvider);
                                              _tabController.animateTo(2);
                                              Navigator.pop(ctx);
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
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
                      child: Row(
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              final filters = <String, dynamic>{
                                'ageMin': ageRange.start.round(),
                                'ageMax': ageRange.end.round(),
                              };
                              if (city != null && city!.isNotEmpty) filters['city'] = city!;
                              if (religion != null && religion!.isNotEmpty) filters['religion'] = religion!;
                              if (education != null && education!.isNotEmpty) filters['education'] = education!;
                              try {
                                await ref.read(discoveryRepositoryProvider).createSavedSearch(filters);
                                if (!ctx.mounted) return;
                                ref.invalidate(savedSearchesProvider);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Search saved')),
                                );
                              } catch (_) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('Could not save search')),
                                  );
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accent,
                              side: BorderSide(color: accent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Save search'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
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
                                    _tabController.animateTo(2); // Switch to Explore tab
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
                        ],
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
          Tab(text: 'Recommended', height: 38),
          Tab(text: 'Visitors', height: 38),
          Tab(text: 'Search', height: 38),
          Tab(text: 'Matches', height: 38),
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
    required this.onBlock,
    required this.onReport,
  });
  final void Function(ProfileSummary) onTapProfile;
  final void Function(ProfileSummary) onLike;
  final void Function(ProfileSummary) onSuperLike;
  final void Function(ProfileSummary) onShortlist;
  final void Function(ProfileSummary) onMessage;
  final VoidCallback onUpgrade;
  final void Function(ProfileSummary) onBlock;
  final void Function(ProfileSummary) onReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final shortlistedIds = ref.watch(shortlistedIdsProvider).valueOrNull ?? <String>{};
    final sentInterestIds = ref.watch(sentInterestProfileIdsProvider).valueOrNull ?? <String>{};
    final sentPriorityIds = ref.watch(sentPriorityInterestProfileIdsProvider).valueOrNull ?? <String>{};
    final matchedIds = ref.watch(matchedUserIdsProvider).valueOrNull ?? <String>{};
    final async = ref.watch(matchesRecommendedProvider);
    return async.when(
      data: (profiles) {
        final filtered = profiles.where((p) => !matchedIds.contains(p.id)).toList();
        return _ProfileList(
        profiles: filtered,
        shortlistedIds: shortlistedIds,
        sentInterestIds: sentInterestIds,
        sentPriorityInterestIds: sentPriorityIds,
        onTap: onTapProfile,
        onLike: onLike,
        onSuperLike: onSuperLike,
        onShortlist: onShortlist,
        onMessage: onMessage,
        onUpgrade: onUpgrade,
        onBlock: onBlock,
        onReport: onReport,
        emptyIcon: Icons.diversity_3_rounded,
        emptyTitle: 'No recommendations yet',
        emptyBody: 'Complete your profile and preferences to get AI-powered matches.',
        );
      },
      loading: () => const SkeletonCardList(),
      error: (_, __) => ErrorState(
        message: l.errorGeneric,
        onRetry: () => ref.invalidate(matchesRecommendedProvider),
        retryLabel: l.retry,
      ),
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
    required this.onBlock,
    required this.onReport,
  });
  final void Function(ProfileSummary) onTapProfile;
  final void Function(ProfileSummary) onLike;
  final void Function(ProfileSummary) onSuperLike;
  final void Function(ProfileSummary) onShortlist;
  final void Function(ProfileSummary) onMessage;
  final VoidCallback onUpgrade;
  final void Function(ProfileSummary) onBlock;
  final void Function(ProfileSummary) onReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final shortlistedIds = ref.watch(shortlistedIdsProvider).valueOrNull ?? <String>{};
    final sentInterestIds = ref.watch(sentInterestProfileIdsProvider).valueOrNull ?? <String>{};
    final sentPriorityIds = ref.watch(sentPriorityInterestProfileIdsProvider).valueOrNull ?? <String>{};
    final matchedIds = ref.watch(matchedUserIdsProvider).valueOrNull ?? <String>{};
    final async = ref.watch(visitorsProvider);
    return async.when(
      data: (profiles) {
        final filtered = profiles.where((p) => !matchedIds.contains(p.id)).toList();
        return _ProfileList(
        profiles: filtered,
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
        onBlock: onBlock,
        onReport: onReport,
        );
      },
      loading: () => const SkeletonCardList(),
      error: (_, __) => ErrorState(
        message: l.errorGeneric,
        onRetry: () => ref.invalidate(visitorsProvider),
        retryLabel: l.retry,
      ),
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
    required this.onBlock,
    required this.onReport,
  });
  final MatchesSearchFilters filters;
  final void Function(ProfileSummary) onTapProfile;
  final void Function(ProfileSummary) onLike;
  final void Function(ProfileSummary) onSuperLike;
  final void Function(ProfileSummary) onShortlist;
  final void Function(ProfileSummary) onMessage;
  final VoidCallback onUpgrade;
  final void Function(ProfileSummary) onBlock;
  final void Function(ProfileSummary) onReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
    final exploreArgs = (mode: mode, filters: filters);

    final shortlistedIds = ref.watch(shortlistedIdsProvider).valueOrNull ?? <String>{};
    final sentInterestIds = ref.watch(sentInterestProfileIdsProvider).valueOrNull ?? <String>{};
    final sentPriorityIds = ref.watch(sentPriorityInterestProfileIdsProvider).valueOrNull ?? <String>{};

    final hasFilters = filters.ageMin != null ||
        filters.ageMax != null ||
        (filters.city != null && filters.city!.isNotEmpty) ||
        (filters.religion != null && filters.religion!.isNotEmpty) ||
        (filters.education != null && filters.education!.isNotEmpty);

    final matchedIds = ref.watch(matchedUserIdsProvider).valueOrNull ?? <String>{};
    final async = ref.watch(matchesExploreProvider(exploreArgs));
    return async.when(
      data: (profiles) {
        final filtered = profiles.where((p) => !matchedIds.contains(p.id)).toList();
        return _ProfileList(
        profiles: filtered,
        shortlistedIds: shortlistedIds,
        sentInterestIds: sentInterestIds,
        sentPriorityInterestIds: sentPriorityIds,
        onTap: onTapProfile,
        onLike: onLike,
        onSuperLike: onSuperLike,
        onShortlist: onShortlist,
        onMessage: onMessage,
        onUpgrade: onUpgrade,
        emptyIcon: hasFilters ? Icons.search_off : Icons.explore_outlined,
        emptyTitle: hasFilters ? 'No matches found' : 'Explore profiles',
        emptyBody: hasFilters
            ? 'Try adjusting your filters for more results.'
            : 'Use the filter icon above to search by age, city, religion, education and more.',
        onBlock: onBlock,
        onReport: onReport,
        );
      },
      loading: () => const SkeletonCardList(),
      error: (_, __) => ErrorState(
        message: l.errorGeneric,
        onRetry: () => ref.invalidate(matchesExploreProvider(exploreArgs)),
        retryLabel: l.retry,
      ),
    );
  }
}

// ─── Matches tab (mutual matches from GET /matches) ───────────────────────

class _MatchesTab extends ConsumerWidget {
  const _MatchesTab({
    required this.onTapProfile,
    required this.onMessage,
    required this.onBlock,
    required this.onReport,
  });
  final void Function(ProfileSummary) onTapProfile;
  final void Function(ProfileSummary) onMessage;
  final void Function(ProfileSummary) onBlock;
  final void Function(ProfileSummary) onReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mutualMatchesProvider);
    final l = AppLocalizations.of(context)!;
    return async.when(
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No matches yet',
            body: 'When you and someone else both express interest, you\'ll match and appear here.',
          );
        }
        final onSurface = Theme.of(context).colorScheme.onSurface;
        final accent = AppColors.lightAccent;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final entry = entries[i];
            final p = entry.profile;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onTapProfile(p),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: onSurface.withValues(alpha: 0.1),
                          backgroundImage: p.imageUrl != null && p.imageUrl!.isNotEmpty
                              ? NetworkImage(p.imageUrl!)
                              : null,
                          child: p.imageUrl == null || p.imageUrl!.isEmpty
                              ? Text(
                                  (p.name.isNotEmpty ? p.name[0] : '?').toUpperCase(),
                                  style: AppTypography.titleMedium.copyWith(color: onSurface.withValues(alpha: 0.6)),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.name,
                                style: AppTypography.titleMedium.copyWith(
                                  color: onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (p.age != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${p.age} yrs',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                              if (entry.lastMessage != null && entry.lastMessage!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  entry.lastMessage!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: onSurface.withValues(alpha: 0.5),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => onMessage(p),
                          icon: Icon(Icons.chat_bubble_outline_rounded, color: accent),
                          tooltip: 'Message',
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: onSurface.withValues(alpha: 0.6)),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (v) {
                            if (v == 'block') onBlock(p);
                            if (v == 'report') onReport(p);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'block',
                              child: Row(
                                children: [
                                  Icon(Icons.block, size: 20, color: Theme.of(context).colorScheme.error),
                                  const SizedBox(width: 12),
                                  Text(l.block),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  Icon(Icons.flag_outlined, size: 20, color: Theme.of(context).colorScheme.error),
                                  const SizedBox(width: 12),
                                  Text(l.report),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const SkeletonCardList(),
      error: (_, __) => ErrorState(
        message: l.errorGeneric,
        onRetry: () => ref.invalidate(mutualMatchesProvider),
        retryLabel: l.retry,
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
    required this.onBlock,
    required this.onReport,
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
  final void Function(ProfileSummary) onBlock;
  final void Function(ProfileSummary) onReport;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyBody;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return EmptyState(icon: emptyIcon, title: emptyTitle, body: emptyBody);
    }
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final cardHeight = (viewportHeight * 0.78).clamp(380.0, 520.0);
    const horizontalPadding = 12.0;
    const peekGap = 12.0;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 24),
      itemCount: profiles.length,
      itemBuilder: (context, i) {
        final p = profiles[i];
        final isShortlisted = shortlistedIds?.contains(p.id) ?? false;
        final isInterested = sentInterestIds?.contains(p.id) ?? false;
        final isPriorityInterested = sentPriorityInterestIds?.contains(p.id) ?? false;
        return Padding(
          padding: const EdgeInsets.only(bottom: peekGap),
          child: SizedBox(
            height: cardHeight,
            child: MatchProfileCard(
              profile: p,
              isShortlisted: isShortlisted,
              isInterested: isInterested,
              isPriorityInterested: isPriorityInterested,
              messageUnlockedByMatch: true,
              onTap: () => onTap(p),
              onLike: () => onLike(p),
              onSuperLike: () => onSuperLike(p),
              onShortlist: () => onShortlist(p),
              onMessage: () => onMessage(p),
              onUpgrade: onUpgrade,
              onBlock: () => onBlock(p),
              onReport: () => onReport(p),
            ).animate().fadeIn(delay: (40 * i).ms).slideY(begin: 0.04, end: 0),
          ),
        );
      },
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: 'Refine by age, city, religion, education and more',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: activeCount > 0
                  ? accent.withValues(alpha: 0.12)
                  : onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: activeCount > 0 ? accent : onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Refine',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: activeCount > 0 ? accent : onSurface.withValues(alpha: 0.85),
                  ),
                ),
                if (activeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
    final surface = Theme.of(context).colorScheme.surface;
    final accent = AppColors.saffron;
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = (width * 0.9).clamp(320.0, 420.0);
    final warmBg = Color.lerp(surface, accent, 0.03) ?? surface;
    final warmFill = Color.lerp(surface, accent, 0.06) ?? surface;

    final name = widget.profileName.split(' ').first;
    final greeting = name.isNotEmpty ? 'Say hi to $name' : 'Send a personal note';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: (width - dialogWidth) / 2),
      child: Material(
        borderRadius: BorderRadius.circular(28),
        color: warmBg,
        elevation: 12,
        shadowColor: accent.withValues(alpha: 0.15),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dialogWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.2),
                            accent.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.auto_awesome, color: accent, size: 28),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        'Priority interest',
                        style: AppTypography.titleLarge.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  greeting,
                  style: AppTypography.bodyLarge.copyWith(
                    color: onSurface.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A short note goes a long way — optional, but they\'ll love it.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: onSurface.withValues(alpha: 0.6),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'e.g. Hi! Something in your profile caught my eye...',
                    hintStyle: TextStyle(
                      color: onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: onSurface.withValues(alpha: 0.12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: accent, width: 2),
                    ),
                    filled: true,
                    fillColor: warmFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                ),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: () {
                    final text = _controller.text.trim();
                    Navigator.of(context).pop(text.isEmpty ? null : text);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Send your note'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: TextButton.styleFrom(
                    foregroundColor: onSurface.withValues(alpha: 0.55),
                  ),
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
