import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ads/ad_loading_dialog.dart';
import '../../../core/shell/root_shell.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/design/design.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/entitlements/entitlements.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../chat/providers/chat_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/safety/safety_reason_picker.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/matrimony_extensions.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../domain/models/shortlist_entry.dart';
import '../../../domain/models/who_shortlisted_me_entry.dart';
import '../../../l10n/app_localizations.dart';
import '../../matches/providers/matches_providers.dart';
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
            labelColor: Theme.of(context).colorScheme.secondary,
            unselectedLabelColor: onSurface.withValues(alpha: 0.6),
            indicatorColor: Theme.of(context).colorScheme.secondary,
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
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), p.id}},
          );
      // Tier 1: immediate — badges and sent-list update.
      ref.invalidate(sentInteractionsProvider(mode));
      if (result.mutualMatch && result.chatThreadId != null) {
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != p.id).toList(),
            );
        showSuccessToast(context, l.toastMatchWith(p.name));
        context.push(
          '/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(p.id)}',
        );
      } else {
        showSuccessToast(context, l.toastInterestSentTo(p.name));
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
        ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
              (m) => {...m, mode: {...(m[mode] ?? {}), p.id}},
            );
        showSuccessToast(context, AppLocalizations.of(context)!.toastInterestSentTo(p.name));
        return;
      }
      showErrorToast(context, e.message);
    }
  }

  Future<void> _onSuperLike(ProfileSummary p) async {
    final ent = ref.read(entitlementsProvider);
    String? adToken;
    if (ent.dailyPriorityInterestLimit == 0) {
      bool? watchAd = await _showWatchAdOrPremiumChoice(context);
      while (watchAd == false) {
        if (!mounted) return;
        await context.push('/paywall');
        if (!mounted) return;
        watchAd = await _showWatchAdOrPremiumChoice(context);
      }
      if (!mounted) return;
      if (watchAd != true) return;
      final shown = await loadAndShowInterstitialWithLoading(context, ref, AdRewardReason.priorityInterest);
      if (!mounted) return;
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
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ref.read(optimisticSentInterestProfileIdsProvider.notifier).update(
            (m) => {...m, mode: {...(m[mode] ?? {}), p.id}},
          );
      // Tier 1: immediate — badges and sent-list update.
      ref.invalidate(sentInteractionsProvider(mode));
      if (result.mutualMatch && result.chatThreadId != null) {
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != p.id).toList(),
            );
        showSuccessToast(context, l.toastMatchWith(p.name));
        context.push(
          '/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(p.id)}',
        );
      } else {
        showSuccessToast(context, l.toastInterestSentTo(p.name));
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
      showErrorToast(context, e.message);
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
        source: 'shortlist',
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
    }
    await _openChat(p, initialAdToken: adToken);
  }

  Future<void> _openChat(ProfileSummary p, {String? initialAdToken}) async {
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
                ? 'Send or accept an interest first'
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
          .block(p.id, reason, source: 'shortlist');
      if (!mounted) return;
      ref.invalidate(shortlistProvider);
      ref.invalidate(shortlistedIdsProvider);
      ref.invalidate(mutualMatchesProvider);
      ref.invalidate(matchedUserIdsProvider);
      showSuccessToast(context, l.toastBlocked(p.name));
    } catch (_) {
      if (!mounted) return;
      showErrorToast(context, l.toastErrorGeneric);
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
      showErrorToast(context, e.message);
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
            source: 'shortlist',
          );
      if (!mounted) return;
      showSuccessToast(context, l.toastReportSubmitted);
    } catch (_) {
      if (!mounted) return;
      showErrorToast(context, l.toastErrorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
    final async = ref.watch(shortlistProvider);
    final matchedIds =
        ref.watch(matchedUserIdsProvider).valueOrNull ?? <String>{};
    final sentInterestIds =
        ref.watch(sentInterestProfileIdsProvider(mode)).valueOrNull ?? <String>{};
    final optimisticInterestIds =
        ref.watch(optimisticSentInterestProfileIdsProvider)[mode] ?? <String>{};
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final p = entry.profile;
              final isMutualMatch = matchedIds.contains(p.id);
              final isInterested = sentInterestIds.contains(p.id) ||
                  optimisticInterestIds.contains(p.id);
              final isPriorityInterested = sentPriorityIds.contains(p.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ShortlistProfileTile(
                  entry: entry,
                  isMutualMatch: isMutualMatch,
                  isInterested: isInterested,
                  isPriorityInterested: isPriorityInterested,
                  onTap: () => context.push('/profile/${p.id}'),
                  onLike: () => _onLike(p),
                  onSuperLike: () => _onSuperLike(p),
                  onMessage: () => _onMessage(p),
                  onRemoveShortlist: () async {
                    await ref
                        .read(shortlistRepositoryProvider)
                        .removeFromShortlist(p.id);
                    ref.invalidate(shortlistProvider);
                    ref.invalidate(shortlistedIdsProvider);
                  },
                  onEditNote: entry.shortlistId != null
                      ? () => _showEditNoteDialog(context, ref, entry)
                      : null,
                  onBlock: () => _onBlock(p),
                  onReport: () => _onReport(p),
                ),
              ).staggeredItem(index);
            },
          ),
        );
      },
      loading: () => loadingSpinner(context),
      error: (e, _) => ErrorState(
        error: e,
        onRetry: () => ref.invalidate(shortlistProvider),
        retryLabel: l.retry,
      ),
    );
  }
}

// ── Compact shortlist profile tile ──────────────────────────────────────

class _ShortlistProfileTile extends StatelessWidget {
  const _ShortlistProfileTile({
    required this.entry,
    required this.isMutualMatch,
    required this.isInterested,
    required this.isPriorityInterested,
    required this.onTap,
    required this.onLike,
    required this.onSuperLike,
    required this.onMessage,
    required this.onRemoveShortlist,
    required this.onBlock,
    required this.onReport,
    this.onEditNote,
  });

  final ShortlistEntry entry;
  final bool isMutualMatch;
  final bool isInterested;
  final bool isPriorityInterested;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onSuperLike;
  final VoidCallback onMessage;
  final VoidCallback onRemoveShortlist;
  final VoidCallback onBlock;
  final VoidCallback onReport;
  final VoidCallback? onEditNote;

  @override
  Widget build(BuildContext context) {
    final p = entry.profile;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.secondary;
    final surface = Theme.of(context).colorScheme.surface;
    final hasNote = entry.note != null && entry.note!.isNotEmpty;

    // Determine primary action state
    final bool showMessage = isMutualMatch;
    final bool interestSent = isInterested || isPriorityInterested;

    // Verification badge color/label
    final verScore = p.verificationScore ?? (p.verified ? 0.5 : 0.0);
    Color? verColor;
    String? verLabel;
    if (verScore >= 0.8) {
      verColor = const Color(0xFF00C853);
      verLabel = 'Fully Verified';
    } else if (verScore >= 0.5) {
      verColor = const Color(0xFF1565C0);
      verLabel = 'Verified';
    } else if (p.verified) {
      verColor = const Color(0xFFF57C00);
      verLabel = '${(verScore * 100).round()}% verified';
    }

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: onSurface.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Photo thumbnail
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: p.imageUrl != null
                          ? Image.network(
                              p.imageUrl!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _TileAvatarPlaceholder(profile: p, accent: accent),
                            )
                          : _TileAvatarPlaceholder(profile: p, accent: accent),
                    ),
                    if (isMutualMatch)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: surface, width: 2),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Centre info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${p.name}${p.age != null ? ', ${p.age}' : ''}',
                              style: AppTypography.titleSmall.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMutualMatch) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Match',
                                style: AppTypography.caption.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (p.city != null && p.city!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: onSurface.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                p.city!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: onSurface.withValues(alpha: 0.55),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (verLabel != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: verColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              verLabel,
                              style: AppTypography.caption.copyWith(
                                color: verColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (p.roleManagingProfile != null &&
                          p.roleManagingProfile != ProfileRole.self) ...[
                        const SizedBox(height: 4),
                        _ShortlistManagedByChip(
                          role: p.roleManagingProfile!,
                          accent: accent,
                          onSurface: onSurface,
                        ),
                      ],
                      if (hasNote) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: onEditNote,
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                size: 12,
                                color: onSurface.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  entry.note!,
                                  style: AppTypography.caption.copyWith(
                                    color: onSurface.withValues(alpha: 0.55),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!hasNote && onEditNote != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: onEditNote,
                          child: Text(
                            'Add note...',
                            style: AppTypography.caption.copyWith(
                              color: onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Right action buttons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary action: Message (match) or Interest
                    _TileIconButton(
                      icon: showMessage
                          ? Icons.chat_bubble_outline_rounded
                          : interestSent
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                      color: showMessage
                          ? accent
                          : interestSent
                              ? accent
                              : onSurface.withValues(alpha: 0.5),
                      onTap: showMessage ? onMessage : (interestSent ? onSuperLike : onLike),
                      tooltip: showMessage ? 'Message' : (interestSent ? 'Add Priority' : 'Express Interest'),
                    ),
                    const SizedBox(height: 4),
                    // Star (remove from shortlist)
                    _TileIconButton(
                      icon: Icons.star_rounded,
                      color: accent,
                      onTap: onRemoveShortlist,
                      tooltip: 'Remove from shortlist',
                    ),
                  ],
                ),
                // 3-dot menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: onSurface.withValues(alpha: 0.4),
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) {
                    if (v == 'note') onEditNote?.call();
                    if (v == 'message') onMessage();
                    if (v == 'block') onBlock();
                    if (v == 'report') onReport();
                  },
                  itemBuilder: (_) => [
                    if (onEditNote != null)
                      const PopupMenuItem(
                        value: 'note',
                        child: Row(
                          children: [
                            Icon(Icons.edit_note_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Edit note'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'message',
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Message'),
                        ],
                      ),
                    ),
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
                          const Text('Block'),
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
                          const Text('Report'),
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
  }
}

class _TileAvatarPlaceholder extends StatelessWidget {
  const _TileAvatarPlaceholder({required this.profile, required this.accent});
  final ProfileSummary profile;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 36,
          color: accent.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _TileIconButton extends StatelessWidget {
  const _TileIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: child);
    return child;
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
          ref.invalidate(navBadgesProvider);
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
        ref.invalidate(navBadgesProvider);
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
        ref.invalidate(navBadgesProvider);
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
    final accent = Theme.of(context).colorScheme.secondary;
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
    final accent = Theme.of(context).colorScheme.secondary;
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
            () {
              final stillLocked = (lockedCount - unlocked.length).clamp(0, lockedCount);
              if (stillLocked == 0) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    stillLocked,
                    (_) => _ShortlistBlurredCard(
                      onUnlock: canUnlockMore ? onUnlockOne : null,
                      limitReached: !canUnlockMore,
                      resetsAt: resetsAt,
                    ),
                  ),
                ],
              );
            }(),
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
    final accent = Theme.of(context).colorScheme.secondary;

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

/// Compact managed-by indicator for shortlist tiles (mirrors the chip in match_profile_card.dart).
class _ShortlistManagedByChip extends StatelessWidget {
  const _ShortlistManagedByChip({
    required this.role,
    required this.accent,
    required this.onSurface,
  });

  final ProfileRole role;
  final Color accent;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final String label;
    switch (role) {
      case ProfileRole.parent:
        label = l.profileManagedByParent;
      case ProfileRole.guardian:
        label = l.profileManagedByGuardian;
      case ProfileRole.sibling:
        label = l.profileManagedBySibling;
      case ProfileRole.friend:
        label = l.profileManagedByFriend;
      case ProfileRole.self:
        return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.family_restroom, size: 11, color: accent.withValues(alpha: 0.8)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: accent.withValues(alpha: 0.9),
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
