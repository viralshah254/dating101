import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ads/ad_loading_dialog.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/design/design.dart';
import '../../../core/entitlements/entitlements.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/safety/safety_reason_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../domain/models/shortlist_entry.dart';
import '../../../domain/models/who_shortlisted_me_entry.dart';
import '../../../l10n/app_localizations.dart';
import '../../matches/providers/matches_providers.dart';
import '../../matches/widgets/match_profile_card.dart';
import '../../requests/providers/requests_providers.dart';
import '../providers/shortlist_providers.dart';

/// Matrimony: Shortlist with Received/Sent-style tabs — "Shortlisted" and "Shortlisted you".
class ShortlistScreen extends ConsumerWidget {
  const ShortlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.navShortlist,
            style: AppTypography.headlineSmall.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Sort',
              onSelected: (value) {
                ref.read(shortlistSortProvider.notifier).state = value;
                ref.invalidate(shortlistProvider);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'recent', child: Text(l.mostRecent)),
                PopupMenuItem(
                  value: 'most_interested',
                  child: Text(l.mostInterested),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.indiaGreen,
            unselectedLabelColor: onSurface.withValues(alpha: 0.6),
            indicatorColor: AppColors.indiaGreen,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.shortlistedTab),
              Tab(text: AppLocalizations.of(context)!.shortlistedYouTab),
            ],
          ),
        ),
        body: TabBarView(children: [_ShortlistedTab(), _ShortlistedYouTab()]),
      ),
    );
  }
}

/// Tab 1: Profiles I have shortlisted.
class _ShortlistedTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ShortlistedTab> createState() => _ShortlistedTabState();
}

class _ShortlistedTabState extends ConsumerState<_ShortlistedTab> {
  Future<void> _onLike(ProfileSummary p) async {
    final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
    try {
      final result = await ref
          .read(interactionsRepositoryProvider)
          .expressInterest(p.id, source: 'shortlist', mode: mode);
      if (!context.mounted) return;
      final ctx = context;
      final l = AppLocalizations.of(ctx)!;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), p.id}},
          );
      ref.invalidate(recommendedPaginatedProvider);
      ref.invalidate(sentInteractionsProvider(mode));
      if (result.mutualMatch && result.chatThreadId != null) {
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != p.id).toList(),
            );
        showSuccessToast(ctx, l.toastMatchWith(p.name));
        ctx.push(
          '/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(p.id)}',
        );
      } else {
        showSuccessToast(ctx, l.toastInterestSentTo(p.name));
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      final ctx = context;
      showErrorToast(ctx, e.message);
    }
  }

  Future<void> _onSuperLike(ProfileSummary p) async {
    final ent = ref.read(entitlementsProvider);
    String? adToken;
    if (ent.dailyPriorityInterestLimit == 0) {
      bool? watchAd = await _showWatchAdOrPremiumChoice(context);
      while (watchAd == false) {
        await context.push('/paywall');
        if (!context.mounted) return;
        watchAd = await _showWatchAdOrPremiumChoice(context);
      }
      if (!context.mounted) return;
      if (watchAd != true) return;
      final shown = await loadAndShowInterstitialWithLoading(context, ref, AdRewardReason.priorityInterest);
      if (!context.mounted) return;
      if (!shown) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.adCouldntBeLoaded),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      adToken = const Uuid().v4();
    }
    final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
    try {
      final result = await ref
          .read(interactionsRepositoryProvider)
          .expressPriorityInterest(p.id, source: 'shortlist', adCompletionToken: adToken, mode: mode);
      if (!context.mounted) return;
      final ctx = context;
      final l = AppLocalizations.of(ctx)!;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), p.id}},
          );
      ref.invalidate(sentInteractionsProvider(mode));
      ref.invalidate(recommendedPaginatedProvider);
      if (result.mutualMatch && result.chatThreadId != null) {
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != p.id).toList(),
            );
        showSuccessToast(ctx, l.toastMatchWith(p.name));
        ctx.push(
          '/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(p.id)}',
        );
      } else {
        showSuccessToast(ctx, l.toastInterestSentTo(p.name));
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      final ctx = context;
      showErrorToast(ctx, e.message);
    }
  }

  Future<bool?> _showWatchAdOrPremiumChoice(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(l.priorityInterest),
        content: const Text(
          'Watch an ad to send your priority interest, or upgrade to Premium to send without ads.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.ctaUpgradeToPremium),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context)!.watchAd),
          ),
        ],
      ),
    );
  }

  Future<void> _onMessage(ProfileSummary p) async {
    final ent = ref.read(entitlementsProvider);
    if (!ent.canSendMessageDirect) {
      await _onMessageAsFreeUser(p);
      return;
    }
    await _openChat(p);
  }

  Future<void> _onMessageAsFreeUser(ProfileSummary p) async {
    final l = AppLocalizations.of(context)!;
    final watchAd = await _showWatchAdOrPremiumChoiceForMessage(context);
    if (!context.mounted) return;
    if (watchAd == null) return;
    if (watchAd == false) {
      context.push('/paywall');
      return;
    }
    final shown = await loadAndShowInterstitialWithLoading(context, ref, AdRewardReason.sendMessage);
    if (!context.mounted) return;
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
        source: 'shortlist',
        mode: mode,
      );
      if (!context.mounted) return;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), p.id}},
          );
      ref.invalidate(sentInteractionsProvider(mode));
      ref.invalidate(recommendedPaginatedProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'ALREADY_SENT') {
        ref.invalidate(sentInteractionsProvider(mode));
      }
    }
    await _openChat(p, initialAdToken: adToken);
  }

  Future<void> _openChat(ProfileSummary p, {String? initialAdToken}) async {
    try {
      final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
      final modeStr = mode.isMatrimony ? 'matrimony' : 'dating';
      final threadId = await ref
          .read(chatRepositoryProvider)
          .createThread(p.id, mode: modeStr);
      if (!context.mounted) return;
      final ctx = context;
      final query = 'otherUserId=${Uri.encodeComponent(p.id)}';
      final tokenParam = initialAdToken != null
          ? '&initialAdToken=${Uri.encodeComponent(initialAdToken)}'
          : '';
      ctx.push('/chat/$threadId?$query$tokenParam');
    } on ApiException catch (e) {
      if (!context.mounted) return;
      final ctx = context;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'CONNECTION_REQUIRED'
                ? 'Send or accept an interest first'
                : e.message,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ctx.push('/chats');
    } catch (_) {
      if (!context.mounted) return;
      final ctx = context;
      ctx.push('/chats');
    }
  }

  Future<bool?> _showWatchAdOrPremiumChoiceForMessage(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(l.premium),
        content: const Text(
          'Watch an ad to send a message, or upgrade to Premium to message without ads.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.ctaUpgradeToPremium),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context)!.watchAd),
          ),
        ],
      ),
    );
  }

  Future<void> _onBlock(ProfileSummary p) async {
    final l = AppLocalizations.of(context)!;
    final reason = await showBlockReasonPicker(context);
    if (reason == null || !context.mounted) return;
    final ctx = context;
    final confirmed = await showDialog<bool>(
      context: ctx,
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
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(safetyRepositoryProvider)
          .block(p.id, reason, source: 'shortlist');
      if (!context.mounted) return;
      final ctx = context;
      ref.invalidate(shortlistProvider);
      ref.invalidate(shortlistedIdsProvider);
      ref.invalidate(mutualMatchesProvider);
      ref.invalidate(matchedUserIdsProvider);
      showSuccessToast(ctx, l.toastBlocked(p.name));
    } catch (_) {
      if (!context.mounted) return;
      final ctx = context;
      showErrorToast(ctx, l.toastErrorGeneric);
    }
  }

  Future<void> _showEditNoteDialog(
    BuildContext context,
    WidgetRef ref,
    ShortlistEntry entry,
  ) async {
    if (entry.shortlistId == null) return;
    final controller = TextEditingController(text: entry.note ?? '');
    final l = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.note),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Family liked, Call next week',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          maxLength: 500,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (result != true || !context.mounted) return;
    try {
      await ref
          .read(shortlistRepositoryProvider)
          .updateShortlistEntry(
            entry.shortlistId!,
            note: controller.text.trim().isEmpty
                ? null
                : controller.text.trim(),
          );
      if (!context.mounted) return;
      ref.invalidate(shortlistProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      final ctx = context;
      showErrorToast(ctx, e.message);
    }
  }

  Future<void> _onReport(ProfileSummary p) async {
    final l = AppLocalizations.of(context)!;
    final result = await showReportReasonPicker(context);
    if (result == null || !context.mounted) return;
    final ctx = context;
    final confirmed = await showDialog<bool>(
      context: ctx,
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
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(safetyRepositoryProvider)
          .report(
            p.id,
            result.reason,
            details: result.details,
            source: 'shortlist',
          );
      if (!context.mounted) return;
      final ctx = context;
      showSuccessToast(ctx, l.toastReportSubmitted);
    } catch (_) {
      if (!context.mounted) return;
      final ctx = context;
      showErrorToast(ctx, l.toastErrorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
    final async = ref.watch(shortlistProvider);
    final matchedIds =
        ref.watch(matchedUserIdsProvider).valueOrNull ?? <String>{};
    final sentPriorityIds =
        ref.watch(sentPriorityInterestProfileIdsProvider(mode)).valueOrNull ?? <String>{};

    return async.when(
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyState(
            icon: Icons.star_border_rounded,
            title: l.shortlistEmpty,
            body: l.shortlistEmptyHint,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(shortlistProvider);
            ref.invalidate(shortlistedIdsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final p = entry.profile;
              final cardHeight = (MediaQuery.sizeOf(context).height * 0.78)
                  .clamp(380.0, 520.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: entry.shortlistId != null
                                  ? () =>
                                        _showEditNoteDialog(context, ref, entry)
                                  : null,
                              child: Text(
                                entry.note != null && entry.note!.isNotEmpty
                                    ? entry.note!
                                    : 'Add note (e.g. Family liked, Call next week)',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(
                                        alpha:
                                            entry.note != null &&
                                                entry.note!.isNotEmpty
                                            ? 0.7
                                            : 0.5,
                                      ),
                                  fontStyle:
                                      entry.note != null &&
                                          entry.note!.isNotEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (entry.shortlistId != null)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () =>
                                  _showEditNoteDialog(context, ref, entry),
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(4),
                                minimumSize: const Size(36, 36),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: cardHeight,
                      child: MatchProfileCard(
                        profile: p,
                        isShortlisted: true,
                        isPriorityInterested: sentPriorityIds.contains(p.id),
                        messageUnlockedByMatch: matchedIds.contains(p.id),
                        onTap: () => context.push('/profile/${p.id}'),
                        onLike: () => _onLike(p),
                        onSuperLike: () => _onSuperLike(p),
                        onShortlist: () async {
                          await ref
                              .read(shortlistRepositoryProvider)
                              .removeFromShortlist(p.id);
                          ref.invalidate(shortlistProvider);
                          ref.invalidate(shortlistedIdsProvider);
                        },
                        onMessage: () => _onMessage(p),
                        onUpgrade: () => context.push('/paywall'),
                        onBlock: () => _onBlock(p),
                        onReport: () => _onReport(p),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => loadingSpinner(context),
      error: (_, __) => ErrorState(
        message: l.errorGeneric,
        onRetry: () => ref.invalidate(shortlistProvider),
        retryLabel: l.retry,
      ),
    );
  }
}

/// Tab 2: People who shortlisted me. Free users get 403 → premium gate with blurred cards + watch ad (5/week).
class _ShortlistedYouTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whoAsync = ref.watch(whoShortlistedMeProvider);

    // Backend returns 403 PREMIUM_REQUIRED for free users with count + quota (5/week)
    final err = whoAsync.error;
    if (whoAsync.hasError && err is ApiException && err.code == 'PREMIUM_REQUIRED') {
      final count = err.details?['count'] as int? ?? 0;
      final initialRemaining = err.details?['shortlistUnlocksRemainingThisWeek'] as int?;
      final initialResetsAtStr = err.details?['shortlistUnlocksResetAt'] as String?;
      return RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(whoShortlistedMeProvider);
          ref.invalidate(whoShortlistedMeCountProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: _ShortlistedYouPremiumGate(
            message: err.message,
            lockedCount: count,
            initialRemaining: initialRemaining,
            initialResetsAt: initialResetsAtStr != null ? DateTime.tryParse(initialResetsAtStr) : null,
            onUpgrade: () => context.push('/paywall'),
            onUnlockOne: () => _onUnlockOneShortlistedYou(context, ref),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(whoShortlistedMeProvider);
        ref.invalidate(whoShortlistedMeCountProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: _WhoShortlistedMeContent(
          whoAsync: whoAsync,
          onUpgrade: () => context.push('/paywall'),
        ),
      ),
    );
  }

  static Future<void> _onUnlockOneShortlistedYou(BuildContext context, WidgetRef ref) async {
    final shown = await loadAndShowInterstitialWithLoading(
      context,
      ref,
      AdRewardReason.viewAndRespondToRequest,
    );
    if (!context.mounted) return;
    if (!shown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToSendTryAgain),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final result = await ref.read(shortlistRepositoryProvider).unlockOneWhoShortlistedMe(
        adCompletionToken: const Uuid().v4(),
      );
      if (!context.mounted) return;
      if (result != null) {
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
          (list) => [...list, result.entry],
        );
        ref.read(shortlistUnlocksQuotaProvider.notifier).state = (
          remaining: result.unlocksRemainingThisWeek,
          resetsAt: result.resetsAt,
        );
        ref.invalidate(whoShortlistedMeCountProvider);
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'SHORTLIST_UNLOCKS_LIMIT_REACHED') {
        final resetsAt = e.details?['shortlistUnlocksResetAt'] as String?;
        ref.read(shortlistUnlocksQuotaProvider.notifier).state = (
          remaining: 0,
          resetsAt: resetsAt != null ? DateTime.tryParse(resetsAt) : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resetsAt != null
                  ? 'You\'ve used all 5 unlocks this week. Resets soon.'
                  : e.message,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class _WhoShortlistedMeContent extends StatelessWidget {
  const _WhoShortlistedMeContent({
    required this.whoAsync,
    required this.onUpgrade,
  });
  final AsyncValue<List<WhoShortlistedMeEntry>> whoAsync;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.indiaGreen;
    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                'People who shortlisted you',
                style: AppTypography.titleSmall.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          whoAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 40,
                          color: onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No one has shortlisted you yet.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: list
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BlurredPreviewCard(
                          firstName: e.firstName,
                          age: e.age,
                          locked: false,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const SizedBox(
              height: 72,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Premium gate for "Shortlisted you": message, Subscribe, blurred cards (when count > 0), Watch ad (when quota remaining).
class _ShortlistedYouPremiumGate extends ConsumerWidget {
  const _ShortlistedYouPremiumGate({
    required this.message,
    required this.lockedCount,
    this.initialRemaining,
    this.initialResetsAt,
    required this.onUpgrade,
    required this.onUnlockOne,
  });
  final String message;
  final int lockedCount;
  final int? initialRemaining;
  final DateTime? initialResetsAt;
  final VoidCallback onUpgrade;
  final VoidCallback onUnlockOne;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.indiaGreen;
    final unlocked = ref.watch(shortlistUnlockedEntriesProvider);
    final quota = ref.watch(shortlistUnlocksQuotaProvider);
    final remaining = quota?.remaining ?? initialRemaining ?? 5;
    final resetsAt = quota?.resetsAt ?? initialResetsAt;
    final canUnlockMore = remaining > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'People who shortlisted you',
                  style: AppTypography.titleSmall.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onUpgrade,
                  icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                  label: Text(l.ctaUpgradeToPremium),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          if (unlocked.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...unlocked.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => context.push('/profile/${e.profileId}'),
                  behavior: HitTestBehavior.opaque,
                  child: _BlurredPreviewCard(
                    firstName: e.firstName,
                    age: e.age,
                    locked: false,
                  ),
                ),
              ),
            ),
          ],
          if (lockedCount > 0) ...[
            const SizedBox(height: 12),
            if (canUnlockMore)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '$remaining unlock${remaining == 1 ? '' : 's'} left this week',
                  style: AppTypography.caption.copyWith(
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ...List.generate(
              lockedCount,
              (_) => _ShortlistBlurredCard(
                onUnlock: canUnlockMore ? onUnlockOne : null,
                limitReached: !canUnlockMore,
                resetsAt: resetsAt,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Blurred card with "Watch ad to unlock" or "Unlocks reset next week" when limit reached.
class _ShortlistBlurredCard extends StatelessWidget {
  const _ShortlistBlurredCard({
    required this.onUnlock,
    required this.limitReached,
    this.resetsAt,
  });
  final VoidCallback? onUnlock;
  final bool limitReached;
  final DateTime? resetsAt;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.indiaGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 14,
                            width: 100,
                            decoration: BoxDecoration(
                              color: onSurface.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: 60,
                            decoration: BoxDecoration(
                              color: onSurface.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Container(color: onSurface.withValues(alpha: 0.15)),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 24,
                      color: onSurface.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 10),
                    if (onUnlock != null)
                      Flexible(
                        child: FilledButton.icon(
                          onPressed: onUnlock,
                          icon: const Icon(Icons.play_circle_outline, size: 16),
                          label: Text(AppLocalizations.of(context)!.watchAdToUnlock),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: Text(
                          resetsAt != null
                              ? 'Unlocks reset next week'
                              : '5 unlocks per week — try again later',
                          style: AppTypography.caption.copyWith(
                            color: onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurredPreviewCard extends StatelessWidget {
  const _BlurredPreviewCard({
    required this.firstName,
    this.age,
    required this.locked,
  });
  final String firstName;
  final int? age;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
    // When locked, show first letter + "..." and age as teaser (e.g. "S...", "25 yrs")
    final displayName = locked ? '$initial...' : firstName;
    final displayAge = age != null ? '$age yrs' : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: locked ? onSurface.withValues(alpha: 0.04) : surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: locked
              ? onSurface.withValues(alpha: 0.08)
              : onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Avatar circle with initial
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: locked
                  ? onSurface.withValues(alpha: 0.08)
                  : onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                initial,
                style: AppTypography.titleMedium.copyWith(
                  color: onSurface.withValues(alpha: locked ? 0.45 : 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: AppTypography.titleSmall.copyWith(
                    color: onSurface.withValues(alpha: locked ? 0.5 : 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (displayAge != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    displayAge,
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (locked)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 16,
                color: onSurface.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }
}
