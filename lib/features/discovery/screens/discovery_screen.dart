import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_copy.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/discovery_providers.dart';
import '../widgets/profile_card.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  String _selectedCity = 'London';
  bool _travelMode = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final accent = Theme.of(context).colorScheme.primary;
    final asyncProfiles = ref.watch(recommendedProfilesProvider);

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
            icon: Icon(_travelMode ? Icons.flight_takeoff : Icons.location_city),
            onPressed: () => setState(() => _travelMode = !_travelMode),
          ),
        ],
      ),
      body: asyncProfiles.when(
        data: (profiles) => _buildBody(context, ref, mode, accent, l, profiles),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.errorGeneric,
                  style: AppTypography.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(recommendedProfilesProvider),
                  child: Text(l.retry),
                ),
              ],
            ),
          ),
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
                  city: _selectedCity,
                  onTap: () => _showCityPicker(context),
                  cta: l.exploreCity(_selectedCity),
                ),
                if (_travelMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          l.travelModeHint,
                          style: AppTypography.caption,
                        ),
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.emptyStateGeneric,
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.dailyCuratedSet,
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final profile = profiles[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ProfileCard(
                    profile: profile,
                    sendPrimaryLabel: AppCopy.ctaSendPrimary(context, mode),
                    onTap: () => context.push('/profile/${profile.id}'),
                    onSendIntro: () => _onSendIntro(profile),
                    onBlock: () => _onBlock(profile),
                    onReport: () => _onReport(profile),
                  ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.03, end: 0),
                );
              },
              childCount: profiles.length,
            ),
          ),
      ],
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.of(ctx)!.filters, style: AppTypography.headlineSmall),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(ctx)!.filtersPlaceholder),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(ctx)!.apply),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: ['London', 'Dubai', 'Mumbai', 'New York', 'Singapore']
              .map((city) => ListTile(
                    title: Text(city),
                    onTap: () {
                      setState(() => _selectedCity = city);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _onSendIntro(ProfileSummary profile) async {
    try {
      final result = await ref.read(interactionsRepositoryProvider).expressInterest(profile.id, source: 'recommended');
      if (!mounted) return;
      if (result.mutualMatch && result.chatThreadId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('It\'s a match with ${profile.name}!'), behavior: SnackBarBehavior.floating),
        );
        context.push('/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(profile.id)}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Interest sent to ${profile.name}'), behavior: SnackBarBehavior.floating),
        );
      }
      ref.invalidate(recommendedProfilesProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _onBlock(ProfileSummary profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block user?'),
        content: Text('${profile.name} won\'t be able to see your profile or contact you.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      await ref.read(discoveryRepositoryProvider).sendFeedback(candidateId: profile.id, action: 'block', source: 'recommended');
      if (!mounted) return;
      ref.invalidate(recommendedProfilesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${profile.name} blocked'), behavior: SnackBarBehavior.floating),
      );
    } catch (_) {}
  }

  Future<void> _onReport(ProfileSummary profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report user?'),
        content: Text('Report ${profile.name} for inappropriate behaviour?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      await ref.read(discoveryRepositoryProvider).sendFeedback(candidateId: profile.id, action: 'report', source: 'recommended');
      if (!mounted) return;
      ref.invalidate(recommendedProfilesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you.'), behavior: SnackBarBehavior.floating),
      );
    } catch (_) {}
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({required this.city, required this.onTap, required this.cta});
  final String city;
  final VoidCallback onTap;
  final String cta;

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
              Text(cta, style: AppTypography.labelLarge.copyWith(color: accent)),
            ],
          ),
        ),
      ),
    );
  }
}
