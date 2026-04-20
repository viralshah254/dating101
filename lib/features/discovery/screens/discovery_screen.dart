import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/referral_promo/referral_promo_provider.dart';
import '../../../core/safety/safety_reason_picker.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/discovery_filter_params.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../matches/providers/matches_providers.dart';
import '../../premium/services/paywall_trigger_service.dart';
import '../../referral/widgets/referral_promo_banner.dart';
import '../../requests/providers/requests_providers.dart';
import '../../shortlist/providers/shortlist_providers.dart';
import '../providers/discovery_providers.dart';
import '../../chat/providers/chat_providers.dart';
import '../../likes/providers/likes_screen_data_provider.dart';
import '../../chat/widgets/focus_mode_banner.dart';
import '../widgets/city_picker_sheet.dart';
import '../widgets/discover_feed_loading_surface.dart';
import '../widgets/discovery_card_stack.dart';
import '../widgets/like_note_sheet.dart';
import '../widgets/unified_filter_sheet.dart';

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
    final loadingCue = ref.watch(discoveryLoadingCueProvider);

    ref.listen<AsyncValue<List<ProfileSummary>>>(discoveryFeedProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(discoveryLoadingCueProvider.notifier).state = DiscoveryLoadingCue.none;
        },
        error: (_, __) {
          ref.read(discoveryLoadingCueProvider.notifier).state = DiscoveryLoadingCue.none;
        },
      );
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            // Subtle rose ambient glow at the top of the discover screen
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      AppColors.roseDeep.withValues(alpha: 0.18),
                      Theme.of(context).colorScheme.surface,
                    ]
                  : [
                      AppColors.rosePrimary.withValues(alpha: 0.06),
                      Theme.of(context).colorScheme.surface,
                    ],
            ),
          ),
          child: AppBar(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.discoverTitle,
                  style: AppTypography.titleLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                if (hasCityFilter)
                  Text(
                    _effectiveCity(filterParams, travelCity) ?? '',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.rosePrimary.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
              ],
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
                  color: hasCityFilter
                      ? AppColors.rosePrimary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                onPressed: () => showCityPickerSheet(context, ref),
              ),
            ],
          ),
        ),
      ),
      body: asyncProfiles.when(
        skipLoadingOnReload: true,
        data: (profiles) {
          if (loadingCue != DiscoveryLoadingCue.none) {
            final effectiveCity = _effectiveCity(filterParams, travelCity);
            return _buildLoadingShell(
              context,
              ref,
              mode,
              accent,
              l,
              effectiveCity,
              loadingCue,
            );
          }
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
        loading: () => _buildLoadingShell(
              context,
              ref,
              mode,
              accent,
              l,
              _effectiveCity(filterParams, travelCity),
              DiscoveryLoadingCue.initial,
            ),
        error: (e, _) => ErrorState(
          error: e,
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

  /// Discover chrome + themed loading (filters, city change, or first paint).
  Widget _buildLoadingShell(
    BuildContext context,
    WidgetRef ref,
    AppMode mode,
    Color accent,
    AppLocalizations l,
    String? effectiveCity,
    DiscoveryLoadingCue cue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_focusModeBannerDismissed)
          _FocusModeBannerContainer(
            onDismiss: () => setState(() => _focusModeBannerDismissed = true),
          ),
        Expanded(
          child: DiscoverFeedLoadingSurface(cue: cue),
        ),
      ],
    );
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
        if (!_focusModeBannerDismissed)
          _FocusModeBannerContainer(
            onDismiss: () => setState(() => _focusModeBannerDismissed = true),
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
                      ref.read(discoveryLoadingCueProvider.notifier).state =
                          DiscoveryLoadingCue.location;
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
    final mode = ref.read(appModeProvider) ?? AppMode.dating;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UnifiedFilterSheet(
        mode: mode,
        initialParams: ref.read(discoveryFilterParamsProvider) ??
            (ref.read(discoveryTravelCityProvider) != null
                ? DiscoveryFilterParams(city: ref.read(discoveryTravelCityProvider))
                : null),
        initialSort: ref.read(sortByProvider),
        onApply: (params, sort) {
          ref.read(discoveryLoadingCueProvider.notifier).state = DiscoveryLoadingCue.filters;
          ref.read(discoveryFilterParamsProvider.notifier).state = params;
          ref.read(sortByProvider.notifier).state = sort;
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
  bool _focusModeBannerDismissed = false;

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
    // Count profile view; may trigger swipe-limit paywall
    if (mounted) await PaywallTriggerService.recordSwipe(context, ref);
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
    // Show "Like With a Note" sheet before sending — card has already animated out.
    final noteResult = await showLikeNoteSheet(context, profile);
    // If user dismissed the sheet entirely (back button), still send silently.
    final message = noteResult?.message;
    try {
      final result = await ref
          .read(interactionsRepositoryProvider)
          .expressInterest(profile.id, source: 'discovery', mode: mode, message: message);
      if (!mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), profile.id}},
          );
      ref.invalidate(sentInteractionsProvider(mode));
      invalidateLikesScreenData(ref);
      ref.invalidate(recommendedPaginatedProvider);
      if (result.mutualMatch && result.chatThreadId != null) {
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != profile.id).toList(),
            );
        // Prompt free users to upgrade when they get a mutual match
        if (mounted) {
          await PaywallTriggerService.maybeShow(context, ref, PaywallReason.matchAccepted);
        }
        if (!mounted) return;
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
      invalidateLikesScreenData(ref);
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
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
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
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
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

/// Watches [focusModeProvider] and renders [FocusModeBanner] for the first active
/// Focus Mode entry. Silently hides itself if there are no active focus modes
/// or the fetch fails.
class _FocusModeBannerContainer extends ConsumerWidget {
  const _FocusModeBannerContainer({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncModes = ref.watch(focusModeProvider);

    return asyncModes.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (modes) {
        if (modes.isEmpty) return const SizedBox.shrink();
        final mode = modes.first;
        return FocusModeBanner(
          otherPersonName: mode.otherPersonName,
          daysConnected: mode.daysConnected,
          messageCount: mode.messageCount,
          threadId: mode.threadId,
          showMeetNudge: mode.showMeetNudge,
          onDismiss: onDismiss,
          onFocusModeAccept: () {
            // Navigate to the chat thread so user can keep the conversation going
            context.push('/chat/${mode.threadId}');
            onDismiss();
          },
          onOpenChat: () => context.push('/chat/${mode.threadId}'),
          onMarkMet: () async {
            try {
              final api = ref.read(apiClientProvider);
              await api.post('/focus-mode/threads/${mode.threadId}/met');
            } catch (_) {
              // Ignore — optimistic dismiss
            }
            ref.invalidate(focusModeProvider);
            onDismiss();
          },
        );
      },
    );
  }
}
