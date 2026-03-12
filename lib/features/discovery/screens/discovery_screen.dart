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
import '../../../domain/models/discovery_filter_params.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../matches/providers/matches_providers.dart';
import '../../referral/widgets/referral_promo_banner.dart';
import '../../requests/providers/requests_providers.dart';
import '../../shortlist/providers/shortlist_providers.dart';
import '../providers/discovery_providers.dart';
import '../widgets/city_picker_sheet.dart';
import '../widgets/discovery_card_stack.dart';
import '../widgets/discovery_filters_sheet.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  int _currentPage = 0;
  bool _hasTriggeredReferralAt20 = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final accent = Theme.of(context).colorScheme.primary;
    final travelCity = ref.watch(discoveryTravelCityProvider);
    final filterParams = ref.watch(discoveryFilterParamsProvider);
    final hasCityFilter = _effectiveCity(filterParams, travelCity)
        ?.isNotEmpty == true;
    final asyncProfiles = ref.watch(discoveryFeedProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          l.discoverTitle,
          style: AppTypography.titleLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              size: 22,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            onPressed: () => _showFilters(context),
          ),
          IconButton(
            icon: Icon(
              hasCityFilter ? Icons.flight_takeoff_rounded : Icons.location_on_rounded,
              size: 22,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            onPressed: () => showCityPickerSheet(context, ref),
          ),
        ],
      ),
      body: asyncProfiles.when(
        data: (profiles) {
          // When returning from profile after liking (e.g. watch-ad message flow), advance past this card.
          final advanceId = ref.watch(discoveryAdvancePastProfileIdProvider);
          if (advanceId != null &&
              profiles.isNotEmpty &&
              _currentPage < profiles.length &&
              profiles[_currentPage].id == advanceId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _advanceToNext();
                ref.read(discoveryAdvancePastProfileIdProvider.notifier).state = null;
              }
            });
          }
          final filterParams = ref.watch(discoveryFilterParamsProvider);
          final effectiveCity = _effectiveCity(filterParams, travelCity);
          return _buildBody(
            context,
            ref,
            mode,
            accent,
            l,
            profiles,
            effectiveCity,
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

  String? _effectiveCity(DiscoveryFilterParams? fp, String? travelCity) {
    final c = fp?.city;
    if (c != null && c.isNotEmpty) return c;
    return travelCity;
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppMode mode,
    Color accent,
    AppLocalizations l,
    List<ProfileSummary> profiles,
    String? effectiveCity,
  ) {
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
        // Minimal header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.dailyCuratedSet,
                      style: AppTypography.caption.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _CityChip(
                      city: effectiveCity,
                      onTap: () => showCityPickerSheet(context, ref),
                      exploreLabel: l.exploreCity(effectiveCity ?? ''),
                      changeCityLabel: l.changeCity,
                    ),
                  ],
                ),
              ),
              if (effectiveCity != null && effectiveCity.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.flight_takeoff_rounded,
                    size: 18,
                    color: accent.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
        if (profiles.isEmpty)
          Expanded(
            child: EmptyState(
              icon: Icons.explore_outlined,
              title: effectiveCity != null && effectiveCity.isNotEmpty
                  ? l.discoverNoProfilesInCityTitle(effectiveCity)
                  : l.discoverNoMoreProfilesTitle,
              body: effectiveCity != null && effectiveCity.isNotEmpty
                  ? l.discoverNoProfilesInCityBody
                  : l.discoverNoMoreProfilesBody,
              ctaLabel: effectiveCity != null && effectiveCity.isNotEmpty
                  ? l.yourArea
                  : null,
              onCta: effectiveCity != null && effectiveCity.isNotEmpty
                  ? () {
                      ref.read(discoveryTravelCityProvider.notifier).state = null;
                      final fp = ref.read(discoveryFilterParamsProvider);
                      if (fp != null) {
                        ref.read(discoveryFilterParamsProvider.notifier).state =
                            fp.copyWith(city: '');
                      }
                      ref.invalidate(discoveryFeedProvider);
                    }
                  : null,
            ),
          )
        else
          Expanded(
            child: DiscoveryCardStack(
              profiles: profiles,
              currentIndex: _currentPage,
              onPass: _onPass,
              onLike: _onLike,
              onSuperLike: _onSuperLike,
              onTapProfile: (p) => context.push('/profile/${p.id}'),
              onBlock: _onBlock,
              onReport: _onReport,
              showManagedByChip: mode != AppMode.dating,
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
        initialParams: ref.read(discoveryFilterParamsProvider) ??
            (ref.read(discoveryTravelCityProvider) != null
                ? DiscoveryFilterParams(
                    city: ref.read(discoveryTravelCityProvider))
                : null),
        onApply: (params) {
          ref.read(discoveryFilterParamsProvider.notifier).state = params;
          ref.invalidate(discoveryFeedProvider);
        },
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
    if (_currentPage < _profileCount - 1) {
      setState(() => _currentPage++);
      if (_currentPage == 19 &&
          _profileCount >= 20 &&
          !_hasTriggeredReferralAt20 &&
          mounted) {
        _hasTriggeredReferralAt20 = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeShowReferralPopup(context, ref);
        });
      }
    }
  }

  Future<void> _onPass(ProfileSummary profile) async {
    final mode = ref.read(appModeProvider) ?? AppMode.dating;
    try {
      await ref.read(discoveryRepositoryProvider).sendFeedback(
            candidateId: profile.id,
            action: 'pass',
            source: 'discovery',
            mode: mode,
          );
    } catch (_) {}
    if (!mounted) return;
    ref.read(passedProfileIdsProvider.notifier).update((s) => {...s, profile.id});
    _advanceToNext();
  }

  Future<void> _onLike(ProfileSummary profile) async {
    final mode = ref.read(appModeProvider) ?? AppMode.dating;
    try {
      final result = await ref
          .read(interactionsRepositoryProvider)
          .expressInterest(profile.id, source: 'discovery', mode: mode);
      if (!mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), profile.id}},
          );
      ref.invalidate(sentInteractionsProvider(mode));
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
        final opener = await _pickOpenerSuggestion(profile);
        if (!mounted) return;
        final openerQuery = opener != null && opener.isNotEmpty
            ? '&initialText=${Uri.encodeComponent(opener)}'
            : '';
        context.push(
          '/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(profile.id)}$openerQuery',
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
    final mode = ref.read(appModeProvider) ?? AppMode.dating;
    try {
      final result = await ref
          .read(interactionsRepositoryProvider)
          .expressPriorityInterest(profile.id, source: 'discovery', mode: mode);
      if (!mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), profile.id}},
          );
      ref.invalidate(sentInteractionsProvider(mode));
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
        final opener = await _pickOpenerSuggestion(profile);
        if (!mounted) return;
        final openerQuery = opener != null && opener.isNotEmpty
            ? '&initialText=${Uri.encodeComponent(opener)}'
            : '';
        context.push(
          '/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(profile.id)}$openerQuery',
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

  Future<String?> _pickOpenerSuggestion(ProfileSummary profile) async {
    final mode = ref.read(appModeProvider) ?? AppMode.dating;
    List<String> suggestions = _smartOpeners(
      profile,
      AppLocalizations.of(context)!,
    );
    try {
      final apiSuggestions = await ref
          .read(interactionsRepositoryProvider)
          .getOpenerSuggestions(toUserId: profile.id, mode: mode);
      if (apiSuggestions.isNotEmpty) {
        suggestions = apiSuggestions.take(3).toList();
      }
    } on ApiException {
      // Backend can roll out later; local templates keep UX unblocked.
    } catch (_) {}
    if (!mounted) return null;
    final l = AppLocalizations.of(context)!;
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.suggestedOpenersTitle,
                style: AppTypography.titleMedium.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.suggestedOpenersSubtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 12),
              ...suggestions.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    title: Text(s),
                    onTap: () => Navigator.of(ctx).pop(s),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(l.skip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _smartOpeners(ProfileSummary profile, AppLocalizations l) {
    final firstName = profile.name.trim().split(' ').first;
    final shared = profile.sharedInterests.isNotEmpty ? profile.sharedInterests.first : null;
    final openers = <String>[
      l.openerHiName(firstName),
      if (shared != null && shared.isNotEmpty)
        l.openerSharedInterest(shared),
      l.openerWeekendQuestion,
      l.openerCityQuestion(profile.city ?? l.yourArea),
    ];
    return openers.toSet().toList().take(3).toList();
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    changeCityLabel,
                    style: AppTypography.labelMedium.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (city != null && city!.isNotEmpty)
                    Text(
                      exploreLabel,
                      style: AppTypography.caption.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
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

