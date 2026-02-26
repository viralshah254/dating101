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
        title: Text(
          l.discoverTitle,
          style: AppTypography.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
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
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  l.dailyCuratedSet,
                  style: AppTypography.labelLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _CityChip(
                  city: travelCity,
                  onTap: () => _showCityPicker(context, ref),
                  exploreLabel: l.exploreCity(travelCity ?? ''),
                  changeCityLabel: 'Change city',
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
                const SizedBox(height: 16),
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
            delegate: SliverChildBuilderDelegate((context, index) {
              final profile = profiles[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child:
                    ProfileCard(
                          profile: profile,
                          sendPrimaryLabel: AppCopy.ctaSendPrimary(
                            context,
                            mode,
                          ),
                          onTap: () => context.push('/profile/${profile.id}'),
                          onSendIntro: () => _onSendIntro(profile),
                          onBlock: () => _onBlock(profile),
                          onReport: () => _onReport(profile),
                        )
                        .animate()
                        .fadeIn(delay: (50 * index).ms)
                        .slideY(begin: 0.03, end: 0),
              );
            }, childCount: profiles.length),
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
              child: Text('Change city', style: AppTypography.headlineSmall),
            ),
            ListTile(
              title: const Text('Your area'),
              subtitle: const Text('Show profiles near you'),
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
            content: Text('It\'s a match with ${profile.name}!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.push(
          '/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(profile.id)}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Interest sent to ${profile.name}'),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Block user?'),
        content: Text(
          '${profile.name} won\'t be able to see your profile or contact you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
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
          content: Text('${profile.name} blocked'),
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
        title: const Text('Report user?'),
        content: Text('Report ${profile.name} for inappropriate behaviour?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Report'),
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
        const SnackBar(
          content: Text('Report submitted. Thank you.'),
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
