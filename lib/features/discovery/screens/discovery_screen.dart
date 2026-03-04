import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/referral_promo/referral_promo_provider.dart';
import '../../../core/safety/safety_reason_picker.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../matches/providers/matches_providers.dart';
import '../../referral/widgets/referral_promo_banner.dart';
import '../../requests/providers/requests_providers.dart';
import '../../shortlist/providers/shortlist_providers.dart';
import '../providers/discovery_providers.dart';
import '../widgets/discovery_filters_sheet.dart';
import '../widgets/discovery_swipe_card.dart';
import '../widgets/discovery_swipeable_card.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _hasTriggeredReferralAt20 = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final accent = Theme.of(context).colorScheme.primary;
    final travelCity = ref.watch(discoveryTravelCityProvider);
    final asyncProfiles = ref.watch(discoveryFeedProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l.discoverTitle,
          style: AppTypography.titleLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(context),
          ),
          IconButton(
            icon: Icon(
              travelCity != null ? Icons.flight_takeoff : Icons.location_city,
            ),
            onPressed: () => _showCityPicker(context, ref),
          ),
        ],
      ),
      body: asyncProfiles.when(
        data: (profiles) {
          // Backend is expected to return only self-managed profiles for dating when that's enforced.
          // No client-side filter so the feed isn't empty when API returns test/mixed data.
          void onReached20thProfile() {
            if (mounted) _maybeShowReferralPopup(context, ref);
          }
          return _buildBody(
            context,
            ref,
            mode,
            accent,
            l,
            profiles,
            travelCity,
            onReached20thProfile: profiles.length >= 20 ? onReached20thProfile : null,
          );
        },
        loading: () => loadingSpinner(context),
        error: (_, __) => ErrorState(
          message: l.errorGeneric,
          onRetry: () => ref.invalidate(discoveryFeedProvider),
          retryLabel: l.retry,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppMode mode,
    Color accent,
    AppLocalizations l,
    List<ProfileSummary> profiles,
    String? travelCity, {
    VoidCallback? onReached20thProfile,
  }) {
    if (profiles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _profileCount != profiles.length) {
          setState(() => _profileCount = profiles.length);
        }
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compact header: curated set + city
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                l.dailyCuratedSet,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _CityChip(
                city: travelCity,
                onTap: () => _showCityPicker(context, ref),
                exploreLabel: l.exploreCity(travelCity ?? ''),
                changeCityLabel: l.changeCity,
              ),
              if (travelCity != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: accent.withValues(alpha: 0.9)),
                      const SizedBox(width: 6),
                      Text(
                        l.travelModeHint,
                        style: AppTypography.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (profiles.isEmpty)
          Expanded(
            child: EmptyState(
              icon: Icons.explore_outlined,
              title: l.emptyStateGeneric,
              body: l.dailyCuratedSet,
            ),
          )
        else
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: profiles.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                if (index == 19 &&
                    onReached20thProfile != null &&
                    !_hasTriggeredReferralAt20) {
                  _hasTriggeredReferralAt20 = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) onReached20thProfile();
                  });
                }
              },
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return DiscoverySwipeableCard(
                  onPass: () => _onPass(profile),
                  onLike: () => _onLike(profile),
                  onSuperLike: () => _onSuperLike(profile),
                  child: DiscoverySwipeCard(
                    profile: profile,
                    onTap: () => context.push('/profile/${profile.id}'),
                    onPass: () => _onPass(profile),
                    onLike: () => _onLike(profile),
                    onSuperLike: () => _onSuperLike(profile),
                    onBlock: () => _onBlock(profile),
                    onReport: () => _onReport(profile),
                    showManagedByChip: mode != AppMode.dating,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DiscoveryFiltersSheet(
        initialParams: ref.read(discoveryFilterParamsProvider),
        onApply: (params) {
          ref.read(discoveryFilterParamsProvider.notifier).state = params;
          ref.invalidate(discoveryFeedProvider);
        },
      ),
    );
  }

  void _showCityPicker(BuildContext context, WidgetRef ref) {
    final optsAsync = ref.read(filterOptionsProvider);
    final cities =
        optsAsync.valueOrNull?.cities.options ??
        const ['London', 'Dubai', 'Mumbai', 'New York', 'Singapore'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                AppLocalizations.of(context)!.changeCity,
                style: AppTypography.headlineSmall,
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.yourArea),
              subtitle: Text(AppLocalizations.of(context)!.showProfilesNearYou),
              leading: const Icon(Icons.my_location),
              onTap: () {
                ref.read(discoveryTravelCityProvider.notifier).state = null;
                if (context.mounted) Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: cities.length,
                itemBuilder: (_, i) {
                  final city = cities[i];
                  return ListTile(
                    title: Text(city),
                    leading: const Icon(Icons.location_city_outlined),
                    onTap: () {
                      ref.read(discoveryTravelCityProvider.notifier).state =
                          city;
                      if (context.mounted) Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _maybeShowReferralPopup(BuildContext context, WidgetRef ref) {
    final storage = ref.read(referralPromoStorageProvider);
    if (!storage.shouldShowPopup()) return;
    final l = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: ReferralPromoBanner(
                      aspectRatio: 1.0,
                      borderRadius: 12,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (context.mounted) context.push('/referral');
                    },
                    child: Text(l.referNow),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      ref.read(referralPromoStorageProvider).markShown();
    });
  }

  int _profileCount = 0;

  void _advanceToNext() {
    if (_currentPage < _profileCount - 1 && _pageController.hasClients) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _onPass(ProfileSummary profile) async {
    try {
      await ref.read(discoveryRepositoryProvider).sendFeedback(
            candidateId: profile.id,
            action: 'pass',
            source: 'discovery',
          );
    } catch (_) {}
    if (!mounted) return;
    _advanceToNext();
  }

  Future<void> _onLike(ProfileSummary profile) async {
    try {
      final result = await ref
          .read(interactionsRepositoryProvider)
          .expressInterest(profile.id, source: 'discovery');
      if (!mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (s) => {...s, profile.id},
          );
      ref.invalidate(sentInteractionsProvider);
      ref.invalidate(recommendedPaginatedProvider);
      if (result.mutualMatch && result.chatThreadId != null) {
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != profile.id).toList(),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.toastMatchWith(profile.name),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.push(
          '/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(profile.id)}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.toastInterestSentTo(profile.name),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      ref.invalidate(discoveryFeedProvider);
      _advanceToNext();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _onSuperLike(ProfileSummary profile) async {
    try {
      final result = await ref
          .read(interactionsRepositoryProvider)
          .expressPriorityInterest(profile.id, source: 'discovery');
      if (!mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (s) => {...s, profile.id},
          );
      ref.invalidate(sentInteractionsProvider);
      ref.invalidate(recommendedPaginatedProvider);
      if (result.mutualMatch && result.chatThreadId != null) {
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != profile.id).toList(),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.toastMatchWith(profile.name),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.push(
          '/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(profile.id)}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.toastInterestSentTo(profile.name),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      ref.invalidate(discoveryFeedProvider);
      _advanceToNext();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _onBlock(ProfileSummary profile) async {
    final reason = await showBlockReasonPicker(context);
    if (reason == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l.blockUserConfirm),
          content: Text(l.blockUserMessage(profile.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l.block),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(safetyRepositoryProvider)
          .block(profile.id, reason, source: 'recommended');
      if (!mounted) return;
      ref.invalidate(discoveryFeedProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.toastBlocked(profile.name),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {}
  }

  Future<void> _onReport(ProfileSummary profile) async {
    final result = await showReportReasonPicker(context);
    if (result == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.reportUserConfirm),
        content: Text(
          AppLocalizations.of(context)!.reportUserMessage(profile.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.report),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(safetyRepositoryProvider)
          .report(
            profile.id,
            result.reason,
            details: result.details,
            source: 'recommended',
          );
      if (!mounted) return;
      ref.invalidate(discoveryFeedProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.reportSubmittedThankYou),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {}
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({
    required this.city,
    required this.onTap,
    required this.exploreLabel,
    required this.changeCityLabel,
  });
  final String? city;
  final VoidCallback onTap;
  final String exploreLabel;
  final String changeCityLabel;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 20, color: accent),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    changeCityLabel,
                    style: AppTypography.labelLarge.copyWith(color: accent),
                  ),
                  if (city != null && city!.isNotEmpty)
                    Text(
                      exploreLabel,
                      style: AppTypography.caption.copyWith(
                        color: accent.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

