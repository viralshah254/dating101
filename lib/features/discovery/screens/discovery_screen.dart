import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/i18n/app_copy.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/safety/safety_reason_picker.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/discovery_providers.dart';
import '../widgets/discovery_filters_sheet.dart';
import '../widgets/profile_card.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
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
        data: (profiles) =>
            _buildBody(context, ref, mode, accent, l, profiles, travelCity),
        loading: () => SkeletonCardList(itemCount: 5, itemHeight: 200),
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
    String? travelCity,
  ) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      cacheExtent: 300,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  l.dailyCuratedSet,
                  style: AppTypography.titleSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _CityChip(
                  city: travelCity,
                  onTap: () => _showCityPicker(context, ref),
                  exploreLabel: l.exploreCity(travelCity ?? ''),
                  changeCityLabel: l.changeCity,
                ),
                if (travelCity != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: accent),
                        const SizedBox(width: 6),
                        Text(l.travelModeHint, style: AppTypography.caption),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        if (profiles.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              icon: Icons.explore_outlined,
              title: l.emptyStateGeneric,
              body: l.dailyCuratedSet,
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final profile = profiles[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: RepaintBoundary(
                    child:
                        ProfileCard(
                              profile: profile,
                              sendPrimaryLabel: AppCopy.ctaSendPrimary(
                                context,
                                mode,
                              ),
                              onTap: () =>
                                  context.push('/profile/${profile.id}'),
                              onSendIntro: () => _onSendIntro(profile),
                              onBlock: () => _onBlock(profile),
                              onReport: () => _onReport(profile),
                            )
                            .animate()
                            .fadeIn(delay: (50 * index).ms)
                            .slideY(begin: 0.03, end: 0),
                  ),
                );
              },
              childCount: profiles.length,
              addAutomaticKeepAlives: true,
              addRepaintBoundaries: true,
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

  Future<void> _onSendIntro(ProfileSummary profile) async {
    try {
      final result = await ref
          .read(interactionsRepositoryProvider)
          .expressInterest(profile.id, source: 'recommended');
      if (!mounted) return;
      if (result.mutualMatch && result.chatThreadId != null) {
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: accent.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
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
