import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:uuid/uuid.dart';

import '../../../core/ads/ad_action_types.dart';
import '../../../core/ads/ad_loading_dialog.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/design/design.dart';
import '../../../core/entitlements/entitlements.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/daily_matches/daily_matches_provider.dart';
import '../../../core/referral_promo/referral_promo_provider.dart';
import '../../../core/safety/safety_reason_picker.dart';
import '../../../core/monetization/gate_decision_sheet.dart';
import '../../../core/monetization/premium_gate_dialog.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../discovery/widgets/unified_filter_sheet.dart';
import '../../referral/widgets/referral_promo_banner.dart';
import '../../requests/providers/requests_providers.dart';
import '../../shortlist/providers/shortlist_providers.dart';
import '../../../domain/models/discovery_filter_params.dart';
import '../providers/matches_providers.dart';
import '../widgets/daily_matches_popup.dart';
import '../widgets/match_profile_card.dart';
import '../../chat/providers/chat_providers.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _hasTriggeredDailyMatches = false;

  MatchesSearchFilters _filters = const MatchesSearchFilters();
  int _activeFilterCount = 0;

  // ── New-match in-app toast ───────────────────────────────────────────────
  String? _newMatchName;
  bool _showMatchToast = false;

  // ignore: unused_element
  void _showNewMatchToast(String name) {
    setState(() {
      _newMatchName = name;
      _showMatchToast = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showMatchToast = false);
    });
  }

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
    if (_filters.heightMinCm != null || _filters.heightMaxCm != null) c++;
    if (_filters.diet != null && _filters.diet!.isNotEmpty) c++;
    if (_filters.maritalStatus != null && _filters.maritalStatus!.isNotEmpty) c++;
    if (_filters.motherTongue != null && _filters.motherTongue!.isNotEmpty) c++;
    setState(() => _activeFilterCount = c);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;

    if (!_hasTriggeredDailyMatches) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _hasTriggeredDailyMatches) return;
        _hasTriggeredDailyMatches = true;
        _showDailyMatchesPopup(context, ref);
      });
    }

    return Stack(
      children: [
        Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
            title: Text(
              l.navDiscover,
              style: AppTypography.headlineSmall.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
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
              preferredSize: const Size.fromHeight(54),
              child: _TabBarSection(controller: _tabController, accent: accent),
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
              onReached20thProfile: () {
                if (mounted) _showReferralPopup(context, ref);
              },
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
              onReached20thProfile: () {
                if (mounted) _showReferralPopup(context, ref);
              },
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
        ),
        // In-app match toast — slides in from top
        if (_showMatchToast && _newMatchName != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _MatchToast(name: _newMatchName!)
                .animate()
                .slideY(begin: -1, end: 0, duration: AppMotion.medium, curve: AppMotion.reveal)
                .fadeIn(duration: AppMotion.fast),
          ),
      ],
    );
  }

  void _openProfile(ProfileSummary p) => context.push('/profile/${p.id}');

  void _showReferralPopup(BuildContext context, WidgetRef ref) {
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

  Future<void> _showDailyMatchesPopup(BuildContext context, WidgetRef ref) async {
    final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
    if (!mode.isMatrimony) return;
    final storage = ref.read(dailyMatchesStorageProvider);
    if (!storage.shouldShowPopup()) return;
    List<ProfileSummary> profiles;
    try {
      profiles = await ref.read(dailyMatchesProvider.future);
    } catch (_) {
      return; // API error or network failure; skip popup
    }
    if (!mounted) return;
    if (profiles.isEmpty) return;
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DailyMatchesPopup(
        profiles: profiles,
        onDismiss: () {},
        onSent: () {},
      ),
    ).then((_) async {
      await ref.read(dailyMatchesStorageProvider).markShown();
    });
  }

  void _onLike(ProfileSummary p) async {
    final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
    try {
      final repo = ref.read(interactionsRepositoryProvider);
      final result = await repo.expressInterest(p.id, source: 'recommended', mode: mode);
      if (!mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), p.id}},
          );
      // Tier 1: immediate — badges and sent-list update.
      ref.invalidate(sentInteractionsProvider(mode));
      if (result.mutualMatch) {
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != p.id).toList(),
            );
        if (!mounted) return;
        _showMutualMatchCelebration(context, p, result.chatThreadId);
      }
      // Tier 2: deferred background — heavy discovery pipeline.
      final mutualMatch = result.mutualMatch;
      Future.delayed(const Duration(milliseconds: 400), () {
        ref.invalidate(recommendedPaginatedProvider);
        if (mutualMatch) {
          ref.invalidate(mutualMatchesProvider);
          ref.invalidate(matchedUserIdsProvider);
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'ALREADY_SENT') {
        ref.invalidate(sentInteractionsProvider(mode));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.toastInterestSent),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
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
    final l = AppLocalizations.of(context)!;
    final message = await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _PriorityInterestDialog(profileName: p.name),
    );
    if (!mounted) return;
    final ent = ref.read(entitlementsProvider);
    String? adToken;
    if (ent.dailyPriorityInterestLimit == 0) {
      // Free user: must choose Watch ad or Upgrade to Premium. If they go to paywall and back, show choice again.
      bool? watchAd = await _showWatchAdOrPremiumChoice(context);
      while (watchAd != null && watchAd == false) {
        if (!mounted) return;
        await context.push('/paywall');
        if (!mounted) return;
        watchAd = await _showWatchAdOrPremiumChoice(context);
      }
      if (!mounted) return;
      if (watchAd != true) return; // Dismissed
      // User chose Watch ad: show loading dialog, then ad, then on success send priority interest + message.
      final shown = await loadAndShowInterstitialWithLoading(context, ref, AdRewardReason.priorityInterest);
      if (!mounted) return;
      if (!shown) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.adCouldntBeLoaded),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      adToken = const Uuid().v4();
    }
    final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
    try {
      final repo = ref.read(interactionsRepositoryProvider);
      final result = await repo.expressPriorityInterest(
        p.id,
        message: message,
        source: 'recommended',
        adCompletionToken: adToken,
        mode: mode,
      );
      if (!mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), p.id}},
          );
      // Tier 1: immediate — badges and sent-list update.
      ref.invalidate(sentInteractionsProvider(mode));
      if (result.mutualMatch) {
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != p.id).toList(),
            );
        if (!mounted) return;
        _showMutualMatchCelebration(context, p, result.chatThreadId);
      }
      // Tier 2: deferred background — heavy discovery pipeline.
      final mutualMatch = result.mutualMatch;
      Future.delayed(const Duration(milliseconds: 400), () {
        ref.invalidate(recommendedPaginatedProvider);
        if (mutualMatch) {
          ref.invalidate(mutualMatchesProvider);
          ref.invalidate(matchedUserIdsProvider);
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'ALREADY_SENT') {
        ref.invalidate(sentInteractionsProvider(mode));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.toastInterestSent),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Celebration dialog when both users have shown interest. Options: Send message or View profile.
  void _showMutualMatchCelebration(
    BuildContext context,
    ProfileSummary p,
    String? chatThreadId,
  ) {
    final l = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(l.toastMatchWith(p.name)),
        content: Text(
          l.mutualMatchCelebrationMessage,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/profile/${p.id}');
            },
            child: Text(l.viewProfile),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (chatThreadId != null) {
                context.push(
                  '/chat/$chatThreadId?otherUserId=${Uri.encodeComponent(p.id)}',
                );
              } else {
                context.push('/profile/${p.id}');
              }
            },
            child: Text(l.ctaSendMessage),
          ),
        ],
      ),
    );
  }

  /// Shows the branded Premium gate dialog for priority interest.
  /// Returns true = watch ad, false = upgrade, null = dismissed.
  Future<bool?> _showWatchAdOrPremiumChoice(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final decision = await showPremiumGateDialog(
      context,
      title: l.priorityInterest,
      message: l.priorityInterestAdMessage,
      canWatchAd: true,
      watchAdLabel: l.watchAd,
    );
    if (decision == GateDecision.watchAd) return true;
    if (decision == GateDecision.upgrade) return false;
    return null;
  }

  void _onShortlist(ProfileSummary p) async {
    try {
      await ref.read(shortlistRepositoryProvider).addToShortlist(p.id);
      if (!mounted) return;
      ref.invalidate(shortlistProvider);
      ref.invalidate(shortlistedIdsProvider);
      ref.invalidate(recommendedPaginatedProvider);
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
    final ent = ref.read(entitlementsProvider);
    if (ent.canSendMessageDirect) {
      await _openChat(p);
      return;
    }
    // Free user: matches can message without ad; non-matches must watch ad or subscribe.
    final matchedIds = await ref.read(matchedUserIdsProvider.future);
    if (matchedIds.contains(p.id)) {
      await _openChat(p);
      return;
    }
    await _onMessageAsFreeUser(p);
  }

  /// Free user: message only after watch ad or subscribe. After ad, auto-send interest (if needed) then open chat.
  Future<void> _onMessageAsFreeUser(ProfileSummary p) async {
    final l = AppLocalizations.of(context)!;
    final watchAd = await _showWatchAdOrPremiumChoiceForMessage(context);
    if (!mounted) return;
    if (watchAd == null) return;
    if (watchAd == false) {
      context.push('/paywall');
      return;
    }
    final shown = await loadAndShowInterstitialWithLoading(context, ref, AdRewardReason.sendMessage);
    if (!mounted) return;
    if (!shown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.failedToSendTryAgain),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
    final adToken = const Uuid().v4();
    // Auto-send interest so backend allows creating the thread; then open message screen.
    try {
      await ref.read(interactionsRepositoryProvider).expressInterest(
        p.id,
        source: 'recommended',
        mode: mode,
      );
      if (!mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), p.id}},
          );
      ref.invalidate(sentInteractionsProvider(mode));
      // Deferred: heavy discovery pipeline runs in background.
      Future.delayed(const Duration(milliseconds: 400), () {
        ref.invalidate(recommendedPaginatedProvider);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'ALREADY_SENT') {
        ref.invalidate(sentInteractionsProvider(mode));
      }
      // Continue to open chat either way (connection may already exist).
    }
    await _openChat(p, initialAdToken: adToken);
  }

  Future<void> _openChat(ProfileSummary p, {String? initialAdToken}) async {
    final l = AppLocalizations.of(context)!;
    // Enforce Silver active-chat limit (25 threads).
    final ent = ref.read(entitlementsProvider);
    if (ent.maxActiveChats > 0) {
      final activeCount = ref.read(activeChatThreadCountProvider);
      if (activeCount >= ent.maxActiveChats) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("You've reached your 25-chat limit. Upgrade to Gold for unlimited chats."),
            action: SnackBarAction(label: 'Upgrade', onPressed: () => context.push('/premium')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    try {
      final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
      final modeStr = mode.isMatrimony ? 'matrimony' : 'dating';
      final threadId = await ref
          .read(chatRepositoryProvider)
          .createThread(p.id, mode: modeStr);
      if (!mounted) return;
      final query = 'otherUserId=${Uri.encodeComponent(p.id)}';
      final tokenParam = initialAdToken != null
          ? '&initialAdToken=${Uri.encodeComponent(initialAdToken)}'
          : '';
      context.push('/chat/$threadId?$query$tokenParam');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'CONNECTION_REQUIRED'
                ? l.sendOrAcceptInterestFirst
                : e.message,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push('/chats');
    } catch (_) {
      if (!mounted) return;
      context.push('/chats');
    }
  }

  Future<bool?> _showWatchAdOrPremiumChoiceForMessage(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final decision = await showPremiumGateDialog(
      context,
      title: l.premium,
      message: l.watchAdToMessageMessage,
      canWatchAd: true,
      watchAdLabel: l.watchAd,
      adActionType: AdActionType.messageSend,
    );
    if (decision == GateDecision.watchAd) return true;
    if (decision == GateDecision.upgrade) return false;
    return null;
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.block),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(safetyRepositoryProvider)
          .block(p.id, reason, source: 'discover');
      if (!mounted) return;
      ref.invalidate(recommendedPaginatedProvider);
      ref.invalidate(explorePaginatedProvider);
      ref.invalidate(mutualMatchesProvider);
      ref.invalidate(matchedUserIdsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.toastBlocked(p.name)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.toastErrorGeneric),
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.report),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(safetyRepositoryProvider)
          .report(
            p.id,
            result.reason,
            details: result.details,
            source: 'discover',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.reportSubmittedThankYou),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.toastErrorGeneric),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UnifiedFilterSheet(
        mode: mode,
        initialParams: DiscoveryFilterParams(
          ageMin: _filters.ageMin,
          ageMax: _filters.ageMax,
          city: _filters.city,
          religion: _filters.religion,
          education: _filters.education,
          diet: _filters.diet,
          maritalStatus: _filters.maritalStatus,
          motherTongue: _filters.motherTongue,
          heightMinCm: _filters.heightMinCm,
          heightMaxCm: _filters.heightMaxCm,
          verifiedOnly: _filters.verifiedOnly,
        ),
        initialSort: ref.read(sortByProvider),
        onApply: (params, sort) {
          setState(() {
            _filters = MatchesSearchFilters(
              ageMin: params.ageMin,
              ageMax: params.ageMax,
              city: params.city,
              religion: params.religion,
              education: params.education,
              diet: params.diet,
              maritalStatus: params.maritalStatus,
              motherTongue: params.motherTongue,
              heightMinCm: params.heightMinCm,
              heightMaxCm: params.heightMaxCm,
              verifiedOnly: params.verifiedOnly,
            );
            _updateFilterCount();
          });
          ref.read(sortByProvider.notifier).state = sort;
          if (_activeFilterCount > 0) {
            _tabController.animateTo(2); // Switch to Explore tab
          }
        },
      ),
    );
  }
}

// ─── Tabs ───────────────────────────────────────────────────────────────

class _TabBarSection extends StatefulWidget {
  const _TabBarSection({required this.controller, required this.accent});
  final TabController controller;
  final Color accent;

  @override
  State<_TabBarSection> createState() => _TabBarSectionState();
}

class _TabBarSectionState extends State<_TabBarSection> {
  // ignore: unused_field
  double _indicatorPos = 0;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.controller.index;
    widget.controller.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (widget.controller.index != _currentIndex) {
      setState(() {
        _currentIndex = widget.controller.index;
        _indicatorPos = _currentIndex.toDouble();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final accent = widget.accent;
    final tabLabels = [
      l.matchesRecommended,
      l.navVisitors,
      l.matchesSearch,
      l.navMatches,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTokens.radius14),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: widget.controller,
        indicator: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(AppTokens.radius12),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        // Scrollable tabs avoid label truncation on narrow screens / long locales.
        // TabAlignment.fill is only allowed when isScrollable is false.
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        labelColor: cs.onPrimary,
        unselectedLabelColor: onSurface.withValues(alpha: 0.65),
        labelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: AppTypography.labelLarge.copyWith(fontSize: 12),
        tabs: tabLabels
            .asMap()
            .entries
            .map((e) => TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 1.0,
                    end: widget.controller.index == e.key ? 1.03 : 1.0,
                  ),
                  duration: AppMotion.medium,
                  curve: AppMotion.reveal,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Tab(text: e.value, height: 42),
                ))
            .toList(),
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
    this.onReached20thProfile,
  });
  final void Function(ProfileSummary) onTapProfile;
  final void Function(ProfileSummary) onLike;
  final void Function(ProfileSummary) onSuperLike;
  final void Function(ProfileSummary) onShortlist;
  final void Function(ProfileSummary) onMessage;
  final VoidCallback onUpgrade;
  final void Function(ProfileSummary) onBlock;
  final void Function(ProfileSummary) onReport;
  final VoidCallback? onReached20thProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
    final shortlistedIds =
        ref.watch(shortlistedIdsProvider).valueOrNull ?? <String>{};
    final sentInterestIds =
        ref.watch(sentInterestProfileIdsProvider(mode)).valueOrNull ?? <String>{};
    final sentPriorityIds =
        ref.watch(sentPriorityInterestProfileIdsProvider(mode)).valueOrNull ??
        <String>{};
    final excludedFromRecommended =
        ref.watch(effectiveExcludedFromRecommendedIdsProvider);
    final matchedIds =
        ref.watch(matchedUserIdsProvider).valueOrNull ?? <String>{};
    final sort = ref.watch(sortByProvider);
    final async = ref.watch(recommendedPaginatedProvider);
    final notifier = ref.read(recommendedPaginatedProvider.notifier);
    return async.when(
      skipLoadingOnReload: true,
      data: (state) {
        // Exclude matches and profiles we already sent interest/priority to (API + optimistic so full-profile tap is reflected).
        final strict = state.profiles
            .where((p) =>
                !matchedIds.contains(p.id) &&
                !excludedFromRecommended.contains(p.id))
            .toList();
        var filtered = applySortOption(strict, sort);
        var usedRelaxedRecommended = false;
        // API returned people but strict list is empty (e.g. already sent interest to everyone).
        // Never show an empty Recommended tab — widen to lower-fit / broader pool.
        if (filtered.isEmpty && state.profiles.isNotEmpty) {
          final withoutMatches = state.profiles
              .where((p) => !matchedIds.contains(p.id))
              .toList();
          filtered = withoutMatches.isEmpty
              ? applySortOption(state.profiles, sort)
              : applySortOption(withoutMatches, sort);
          usedRelaxedRecommended = true;
        }
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
          emptyTitle: l.noRecommendationsYet,
          emptyBody: l.noRecommendationsYetBody,
          onReached20thProfile: filtered.length >= 20 ? onReached20thProfile : null,
          showReferralCards: filtered.length >= 10,
          widenedSearchBanner:
              (state.isWidenedSearch || usedRelaxedRecommended) && filtered.isNotEmpty
              ? _WidenedSearchBanner(
                  title: l.searchWidenedTitle,
                  body: l.searchWidenedBody,
                )
              : null,
          onLoadMore: state.hasMore ? notifier.loadMore : null,
          hasMore: state.hasMore,
          loadingMore: state.loadingMore,
        );
      },
      loading: () => const SkeletonCardList(),
      error: (e, _) => ErrorState(
        error: e,
        onRetry: () => ref.invalidate(recommendedPaginatedProvider),
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
    final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
    final shortlistedIds =
        ref.watch(shortlistedIdsProvider).valueOrNull ?? <String>{};
    final sentInterestIds =
        ref.watch(sentInterestProfileIdsProvider(mode)).valueOrNull ?? <String>{};
    final sentPriorityIds =
        ref.watch(sentPriorityInterestProfileIdsProvider(mode)).valueOrNull ??
        <String>{};
    final sort = ref.watch(sortByProvider);
    final matchedIds =
        ref.watch(matchedUserIdsProvider).valueOrNull ?? <String>{};
    final async = ref.watch(visitorsProvider);
    return async.when(
      skipLoadingOnReload: true,
      data: (profiles) {
        final unfiltered = profiles
            .where((p) => !matchedIds.contains(p.id))
            .toList();
        final filtered = applySortOption(unfiltered, sort);
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
          emptyTitle: l.noVisitorsYet,
          emptyBody: l.noVisitorsYetBody,
          onBlock: onBlock,
          onReport: onReport,
        );
      },
      loading: () => const SkeletonCardList(),
      error: (e, _) => ErrorState(
        error: e,
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
    this.onReached20thProfile,
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
  final VoidCallback? onReached20thProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
    final exploreArgs = (mode: mode, filters: filters);

    final shortlistedIds =
        ref.watch(shortlistedIdsProvider).valueOrNull ?? <String>{};
    final sentInterestIds =
        ref.watch(sentInterestProfileIdsProvider(mode)).valueOrNull ?? <String>{};
    final sentPriorityIds =
        ref.watch(sentPriorityInterestProfileIdsProvider(mode)).valueOrNull ??
        <String>{};

    final hasFilters =
        filters.ageMin != null ||
        filters.ageMax != null ||
        (filters.city != null && filters.city!.isNotEmpty) ||
        (filters.religion != null && filters.religion!.isNotEmpty) ||
        (filters.education != null && filters.education!.isNotEmpty) ||
        (filters.diet != null && filters.diet!.isNotEmpty) ||
        filters.heightMinCm != null ||
        (filters.maritalStatus != null && filters.maritalStatus!.isNotEmpty) ||
        (filters.motherTongue != null && filters.motherTongue!.isNotEmpty);

    final sort = ref.watch(sortByProvider);
    final matchedIds =
        ref.watch(matchedUserIdsProvider).valueOrNull ?? <String>{};
    final async = ref.watch(explorePaginatedProvider(exploreArgs));
    final notifier = ref.read(explorePaginatedProvider(exploreArgs).notifier);
    return async.when(
      skipLoadingOnReload: true,
      data: (state) {
        final unfiltered = state.profiles
            .where((p) => !matchedIds.contains(p.id))
            .toList();
        final filtered = applySortOption(unfiltered, sort);
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
          emptyTitle: hasFilters ? l.noMatchesFound : l.exploreProfiles,
          emptyBody: hasFilters ? l.tryAdjustingFilters : l.exploreProfilesBody,
          onBlock: onBlock,
          onReport: onReport,
          onReached20thProfile: filtered.length >= 20 ? onReached20thProfile : null,
          showReferralCards: filtered.length >= 10,
          widenedSearchBanner: state.isWidenedSearch && filtered.isNotEmpty
              ? _WidenedSearchBanner(
                  title: l.searchWidenedTitle,
                  body: l.searchWidenedBody,
                )
              : null,
          onLoadMore: state.hasMore ? () => notifier.loadMore(exploreArgs) : null,
          hasMore: state.hasMore,
          loadingMore: state.loadingMore,
        );
      },
      loading: () => const SkeletonCardList(),
      error: (e, _) => ErrorState(
        error: e,
        onRetry: () => ref.invalidate(explorePaginatedProvider(exploreArgs)),
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
      skipLoadingOnReload: true,
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyState(
            icon: Icons.favorite_border_rounded,
            title: l.noMatchesYet,
            body: l.noMatchesYetBody,
          );
        }
        final onSurface = Theme.of(context).colorScheme.onSurface;
        final accent = Theme.of(context).colorScheme.primary;
        // Disable scrolling when list fits on screen (no overflow).
        const approximateItemHeight = 88.0;
        const verticalPadding = 36.0;
        final viewportHeight = MediaQuery.sizeOf(context).height;
        final maxVisibleItems = ((viewportHeight * 0.6 - verticalPadding) / approximateItemHeight).floor();
        final shouldScroll = entries.length > maxVisibleItems.clamp(1, 999);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          physics: shouldScroll ? null : const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final entry = entries[i];
            final p = entry.profile;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                elevation: 0,
                shadowColor: Colors.transparent,
                child: InkWell(
                  onTap: () => onTapProfile(p),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: onSurface.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: onSurface.withValues(alpha: 0.1),
                          backgroundImage:
                              p.imageUrl != null && p.imageUrl!.isNotEmpty
                              ? NetworkImage(p.imageUrl!)
                              : null,
                          child: p.imageUrl == null || p.imageUrl!.isEmpty
                              ? Text(
                                  (p.name.isNotEmpty ? p.name[0] : '?')
                                      .toUpperCase(),
                                  style: AppTypography.titleMedium.copyWith(
                                    color: onSurface.withValues(alpha: 0.6),
                                  ),
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
                              if (entry.lastMessage != null &&
                                  entry.lastMessage!.isNotEmpty) ...[
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
                          icon: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: accent,
                          ),
                          tooltip: l.messageTooltip,
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (v) {
                            if (v == 'block') onBlock(p);
                            if (v == 'report') onReport(p);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'block',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.block,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(l.block),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag_outlined,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
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
      error: (e, _) => ErrorState(
        error: e,
        onRetry: () => ref.invalidate(mutualMatchesProvider),
        retryLabel: l.retry,
      ),
    );
  }
}

// ─── Shared widgets ─────────────────────────────────────────────────────

class _WidenedSearchBanner extends StatelessWidget {
  const _WidenedSearchBanner({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: accent.withValues(alpha: 0.12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 22, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.85,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileList extends StatefulWidget {
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
    this.onReached20thProfile,
    this.widenedSearchBanner,
    this.showReferralCards = false,
    this.onLoadMore,
    this.hasMore = false,
    this.loadingMore = false,
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
  final VoidCallback? onReached20thProfile;
  final Widget? widenedSearchBanner;
  final bool showReferralCards;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool loadingMore;

  static const int _profilesPerReferralCard = 10;
  static const double _referralCardHeight = 160.0;
  static const double _loadMoreTriggerPixels = 400;
  static const Duration _debounce = Duration(milliseconds: 250);

  @override
  State<_ProfileList> createState() => _ProfileListState();
}

class _ProfileListState extends State<_ProfileList> {
  Timer? _debounceTimer;
  bool _shortViewportPrefetchFired = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ProfileList old) {
    super.didUpdateWidget(old);
    // Reset the short-viewport guard whenever the profile list or hasMore changes
    // so a new page of results can trigger the check again if needed.
    if (old.profiles.length != widget.profiles.length || old.hasMore != widget.hasMore) {
      _shortViewportPrefetchFired = false;
    }
  }

  void _maybeLoadMore() {
    if (widget.onLoadMore == null || !widget.hasMore || widget.loadingMore) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_ProfileList._debounce, widget.onLoadMore!);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profiles.isEmpty && !widget.loadingMore) {
      return EmptyState(icon: widget.emptyIcon, title: widget.emptyTitle, body: widget.emptyBody);
    }
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final cardHeight = (viewportHeight * 0.78).clamp(380.0, 520.0);
    const horizontalPadding = 12.0;
    const peekGap = 12.0;

    final useReferral = widget.showReferralCards;
    final adCount = useReferral ? (widget.profiles.length / _ProfileList._profilesPerReferralCard).floor() : 0;
    var itemCount = useReferral ? widget.profiles.length + adCount : widget.profiles.length;
    if (widget.onLoadMore != null && (widget.hasMore || widget.loadingMore)) itemCount += 1;

    final list = NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (widget.onLoadMore == null || !widget.hasMore || widget.loadingMore) return false;
        if (notification is ScrollEndNotification || notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - _ProfileList._loadMoreTriggerPixels) {
            _maybeLoadMore();
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          horizontalPadding,
          12,
          horizontalPadding,
          24,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= (useReferral ? widget.profiles.length + adCount : widget.profiles.length)) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: widget.loadingMore
                    ? const SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
        if (useReferral) {
          final isAdSlot = (index + 1) % (_ProfileList._profilesPerReferralCard + 1) == 0 &&
              (index + 1) ~/ (_ProfileList._profilesPerReferralCard + 1) <= adCount;
          if (isAdSlot) {
            return Padding(
              padding: const EdgeInsets.only(bottom: peekGap),
              child: SizedBox(
                height: _ProfileList._referralCardHeight,
                child: ReferralPromoBanner(
                  aspectRatio: 1.15,
                  borderRadius: 12,
                ).animate().fadeIn(delay: AppMotion.stagger(index), duration: AppMotion.medium).slideY(begin: 0.08, end: 0, curve: AppMotion.spring),
              ),
            );
          }
        }

        final profileIndex = useReferral
            ? index - (index + 1) ~/ (_ProfileList._profilesPerReferralCard + 1)
            : index;
        final p = widget.profiles[profileIndex];
        final isShortlisted = widget.shortlistedIds?.contains(p.id) ?? false;
        final isInterested = widget.sentInterestIds?.contains(p.id) ?? false;
        final isPriorityInterested =
            widget.sentPriorityInterestIds?.contains(p.id) ?? false;
        final is20thProfile = widget.onReached20thProfile != null && profileIndex == 19;
        final card = Padding(
          padding: const EdgeInsets.only(bottom: peekGap),
          child: SizedBox(
            height: cardHeight,
            child: MatchProfileCard(
              profile: p,
              isShortlisted: isShortlisted,
              isInterested: isInterested,
              isPriorityInterested: isPriorityInterested,
              messageUnlockedByMatch: true,
              onTap: () => widget.onTap(p),
              onLike: () => widget.onLike(p),
              onSuperLike: () => widget.onSuperLike(p),
              onShortlist: () => widget.onShortlist(p),
              onMessage: () => widget.onMessage(p),
              onUpgrade: widget.onUpgrade,
              onBlock: () => widget.onBlock(p),
              onReport: () => widget.onReport(p),
            ).animate(key: ValueKey(p.id)).fadeIn(delay: AppMotion.stagger(index), duration: AppMotion.medium).slideY(begin: 0.08, end: 0, curve: AppMotion.spring),
          ),
        );
        if (is20thProfile) {
          final trigger = widget.onReached20thProfile!;
          return _ReferralPopupTrigger(
            onTrigger: trigger,
            child: card,
          );
        }
        return card;
        },
      ),
    );

    // Short-viewport prefetch: when all cards fit on screen there is no scroll
    // event to trigger loadMore, but more profiles are available. Fire once per
    // page so the user always sees a full feed without having to scroll.
    if (widget.hasMore && widget.onLoadMore != null && !widget.loadingMore && !_shortViewportPrefetchFired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Heuristic: if total estimated content height is less than 1.5 viewport
        // heights the user may not be able to scroll far enough to hit the
        // 400px trigger, so prefetch eagerly.
        final estimatedContentHeight = widget.profiles.length * (MediaQuery.sizeOf(context).height * 0.82);
        if (estimatedContentHeight <= MediaQuery.sizeOf(context).height * 1.5) {
          _shortViewportPrefetchFired = true;
          widget.onLoadMore!();
        }
      });
    }

    if (widget.widenedSearchBanner != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.widenedSearchBanner!,
          Expanded(child: list),
        ],
      );
    }
    return list;
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
        message: AppLocalizations.of(context)!.refineTooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: activeCount > 0
                  ? accent.withValues(alpha: 0.12)
                  : onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppTokens.radius12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: activeCount > 0
                      ? accent
                      : onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.refine,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: activeCount > 0
                        ? accent
                        : onSurface.withValues(alpha: 0.85),
                  ),
                ),
                if (activeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$activeCount',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
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

/// Dialog to add an optional message when sending priority interest.
class _PriorityInterestDialog extends StatefulWidget {
  const _PriorityInterestDialog({required this.profileName});
  final String profileName;

  @override
  State<_PriorityInterestDialog> createState() =>
      _PriorityInterestDialogState();
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
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;
    final accent = Theme.of(context).colorScheme.primary;
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = (width * 0.9).clamp(320.0, 420.0);
    final warmBg = Color.lerp(surface, accent, 0.03) ?? surface;
    final warmFill = Color.lerp(surface, accent, 0.06) ?? surface;

    final name = widget.profileName.split(' ').first;
    final greeting = name.isNotEmpty
        ? l.sayHiToName(name)
        : l.sendPersonalNote;

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
                        l.priorityInterest,
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
                    hintText:
                        'e.g. Hi! Something in your profile caught my eye...',
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
                      borderSide: BorderSide(
                        color: onSurface.withValues(alpha: 0.12),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: accent, width: 2),
                    ),
                    filled: true,
                    fillColor: warmFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
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
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(l.sendYourNote),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: TextButton.styleFrom(
                    foregroundColor: onSurface.withValues(alpha: 0.55),
                  ),
                  child: Text(l.skipForNow),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fires [onTrigger] once after the first frame when this widget is built.
class _ReferralPopupTrigger extends StatefulWidget {
  const _ReferralPopupTrigger({
    required this.onTrigger,
    required this.child,
  });

  final VoidCallback onTrigger;
  final Widget child;

  @override
  State<_ReferralPopupTrigger> createState() => _ReferralPopupTriggerState();
}

class _ReferralPopupTriggerState extends State<_ReferralPopupTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onTrigger());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Branded top-of-screen toast shown when a new mutual match is created.
class _MatchToast extends StatelessWidget {
  const _MatchToast({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heartGradient,
        borderRadius: BorderRadius.circular(AppTokens.radius16),
        boxShadow: [
          BoxShadow(
            color: AppColors.rosePrimary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radius16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 22)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.25, 1.25), duration: AppMotion.loop, curve: Curves.easeInOut),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                    children: [
                      const TextSpan(text: "It's a match! "),
                      TextSpan(
                        text: name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' liked you back.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
