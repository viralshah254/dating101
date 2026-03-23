import 'dart:ui';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ads/ad_loading_dialog.dart';
import '../../../core/datetime/app_time_format.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/entitlements/entitlements.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/safety/safety_reason_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../../matches/providers/matches_providers.dart';
import '../providers/chat_providers.dart';

/// Single chat thread. Uses [threadId] and optional [otherUserId] for profile and "me" detection.
/// When [initialAdToken] is set (e.g. after watch-ad on profile), the first message send uses it
/// instead of prompting for another ad.
class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.threadId,
    this.otherUserId,
    this.initialAdToken,
    this.initialText,
  });

  final String threadId;
  final String? otherUserId;
  final String? initialAdToken;
  final String? initialText;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

const _icebreakerSuggestions = [
  'Hi!',
  'How are you?',
  'What brings you here?',
  'Tell me about yourself',
];

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  /// True after first send when we used [ChatThreadScreen.initialAdToken].
  bool _consumedInitialAdToken = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = ref.read(chatRepositoryProvider);
      final ws = ref.read(chatWebSocketClientProvider);
      try {
        await repo.markThreadRead(widget.threadId);
        ws?.sendMarkRead(widget.threadId);
        if (mounted) ref.invalidate(chatThreadsProvider);
      } catch (_) {}
      try {
        final peer = await repo.getPeerLastReadAt(widget.threadId);
        if (mounted) {
          ref.read(threadPeerReadAtProvider(widget.threadId).notifier).state = peer;
        }
      } catch (_) {}
    });
  }

  Future<void> _sendMessageText(
    BuildContext context,
    WidgetRef ref,
    String text,
  ) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final me = ref.read(authRepositoryProvider).currentUserId;
    if (me == null || me.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSendTryAgain),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final ent = ref.read(entitlementsProvider);

    // Free user: require ad unless chatting with a match (matches can message without ad).
    final isMatch = widget.otherUserId != null &&
        (await ref.read(matchedUserIdsProvider.future)).contains(widget.otherUserId!);
    if (!context.mounted) return;
    final requireAd = !ent.canSendMessageDirect && !isMatch;

    String? adToken;
    if (requireAd) {
      if (widget.initialAdToken != null && !_consumedInitialAdToken) {
        adToken = widget.initialAdToken;
        setState(() => _consumedInitialAdToken = true);
      } else {
        final shown = await loadAndShowInterstitialWithLoading(
          context,
          ref,
          AdRewardReason.sendMessage,
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
        adToken = const Uuid().v4();
      }
    }

    final pendingMsg = ChatMessage(
      id: 'pending-${DateTime.now().millisecondsSinceEpoch}',
      senderId: me,
      text: text,
      sentAt: DateTime.now(),
    );
    ref.read(pendingSentMessagesProvider(widget.threadId).notifier).update(
          (list) => [...list, pendingMsg],
        );
    try {
      await chatRepo.sendMessage(widget.threadId, text, adCompletionToken: adToken);
    } on ApiException catch (e) {
      if (context.mounted) {
        ref.read(pendingSentMessagesProvider(widget.threadId).notifier).update(
              (list) => list.where((m) => m.text != text).toList(),
            );
        final showUpgrade = e.code == 'PREMIUM_REQUIRED' ||
            e.code == 'INTRO_LIMIT' ||
            e.code == 'AD_REQUIRED' ||
            e.code == 'PREMIUM_OR_AD_REQUIRED';
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'INTRO_LIMIT' ? l.matchToContinueOrUpgrade : e.message,
            ),
            behavior: SnackBarBehavior.floating,
            action: showUpgrade
                ? SnackBarAction(
                    label: l.upgrade,
                    onPressed: () => context.push('/paywall'),
                  )
                : null,
          ),
        );
      }
      return;
    } catch (_) {
      if (context.mounted) {
        ref.read(pendingSentMessagesProvider(widget.threadId).notifier).update(
              (list) => list.where((m) => m.text != text).toList(),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSendTryAgain),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    // Don't invalidate thread messages here: it would put the provider in loading and hide the optimistic message.
    // The stream polls every 5s and will pick up the new message when the backend returns it.
    ref.invalidate(chatThreadsProvider);
  }

  void _showMoreOptions(
    BuildContext context,
    WidgetRef ref,
    String? otherUserId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (otherUserId != null)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(AppLocalizations.of(ctx)!.viewProfile),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/profile/$otherUserId');
                },
              ),
            ListTile(
              leading: Icon(Icons.block, color: Theme.of(ctx).colorScheme.error),
              title: Text(
                AppLocalizations.of(ctx)!.blockUser,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                if (otherUserId == null) return;
                final reason = await showBlockReasonPicker(context);
                if (reason == null || !context.mounted) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (d) {
                    final l = AppLocalizations.of(d)!;
                    return AlertDialog(
                      title: Text(l.blockUserConfirm),
                      content: Text(l.blockUserMessageChat),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d, false),
                          child: Text(l.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(d, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(d).colorScheme.error,
                          ),
                          child: Text(l.block),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed != true || !context.mounted) return;
                try {
                  await ref
                      .read(safetyRepositoryProvider)
                      .block(otherUserId, reason, source: 'chat');
                  if (context.mounted) {
                    context.pop();
                  }
                } catch (_) {}
              },
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: Theme.of(ctx).colorScheme.tertiary),
              title: Text(AppLocalizations.of(ctx)!.reportUser),
              onTap: () async {
                Navigator.pop(ctx);
                if (otherUserId == null) return;
                final result = await showReportReasonPicker(context);
                if (result == null || !context.mounted) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (d) {
                    final l = AppLocalizations.of(d)!;
                    return AlertDialog(
                      title: Text(l.reportUserConfirm),
                      content: Text(l.reportUserMessageChat),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d, false),
                          child: Text(l.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(d, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(d).colorScheme.tertiary,
                          ),
                          child: Text(l.report),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed != true || !context.mounted) return;
                try {
                  await ref
                      .read(safetyRepositoryProvider)
                      .report(
                        otherUserId,
                        result.reason,
                        details: result.details,
                        source: 'chat',
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.reportSubmittedThankYou,
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (_) {}
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Merge server messages with pending sent (from provider), deduping so we don't show the same message twice.
  List<ChatMessage> _mergeMessages(
    List<ChatMessage> server,
    String? currentUserId,
    List<ChatMessage> pendingSent,
  ) {
    bool sameSender(ChatMessage m, ChatMessage p) {
      if (m.senderId == p.senderId) return true;
      if (currentUserId != null &&
          m.senderId == currentUserId &&
          (p.senderId == 'me' || p.senderId == currentUserId)) {
        return true;
      }
      return false;
    }

    final merged = List<ChatMessage>.from(server);
    for (final p in pendingSent) {
      final match = merged.any(
        (m) =>
            sameSender(m, p) &&
            m.text == p.text &&
            (m.sentAt.difference(p.sentAt).inSeconds.abs() < 120),
      );
      if (!match) merged.add(p);
    }
    merged.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authRepositoryProvider).currentUserId;
    final messagesAsync = ref.watch(_threadMessagesProvider(widget.threadId));
    final pendingSent = ref.watch(pendingSentMessagesProvider(widget.threadId));
    final peerReadAt = ref.watch(threadPeerReadAtProvider(widget.threadId));
    final suggestionsAsync = ref.watch(chatSuggestionsProvider);
    final icebreakerList =
        suggestionsAsync.valueOrNull ?? _icebreakerSuggestions;
    final otherUserId = widget.otherUserId;
    final profileAsync = otherUserId != null
        ? ref.watch(profileSummaryProvider(otherUserId))
        : null;

    ref.listen(_threadMessagesProvider(widget.threadId), (prev, next) {
      if (!next.hasValue || pendingSent.isEmpty) return;
      if (!context.mounted) return;
      final serverList = next.value!;
      ref.read(pendingSentMessagesProvider(widget.threadId).notifier).update(
            (currentPending) => currentPending
                .where(
                  (p) => !serverList.any(
                    (m) =>
                        m.senderId == p.senderId &&
                        m.text == p.text &&
                        (m.sentAt.difference(p.sentAt).inSeconds.abs() < 120),
                  ),
                )
                .toList(),
          );
    });

    final profile = profileAsync?.valueOrNull;
    final displayName = profile?.name ?? 'Chat';
    ChatThreadSummary? threadRow;
    for (final t in ref.watch(chatThreadsProvider).valueOrNull ?? const <ChatThreadSummary>[]) {
      if (t.id == widget.threadId) {
        threadRow = t;
        break;
      }
    }
    final online = threadRow?.otherUserOnline ?? false;
    final lastActive =
        threadRow?.otherLastActiveAt ?? profile?.lastActiveAt;
    final headerPresence = _chatHeaderPresence(online: online, lastActive: lastActive);
    final presenceLabel =
        formatProfileLastSeenSubtitle(online: online, lastActive: lastActive);
    final compatibilityScore = profile?.compatibilityScore;
    final scoreLabel = compatibilityScore != null
        ? '${(compatibilityScore * 100).round()}% match'
        : null;
    final subtitle = [
      if (scoreLabel != null) scoreLabel,
      if (presenceLabel != null) presenceLabel,
    ].join(' · ');
    final subtitleFinal = subtitle.isNotEmpty
        ? subtitle
        : (profile?.city != null ? profile!.city! : '');

    final avatarUrl = profile?.imageUrl;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AppBar(
              backgroundColor: cs.surface.withValues(alpha: isDark ? 0.75 : 0.85),
              titleSpacing: 0,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              title: InkWell(
                onTap: () {
                  if (otherUserId != null) context.push('/profile/$otherUserId');
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: cs.primary.withValues(alpha: 0.2),
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(
                                    initial,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: headerPresence == _ChatHeaderPresence.reachable
                                    ? const Color(0xFF2196F3)
                                    : cs.onSurface.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.surface,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            subtitleFinal,
                            style: AppTypography.caption.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (otherUserId != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () => _showMoreOptions(context, ref, otherUserId),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
              child: messagesAsync.when(
                data: (serverMessages) {
                  final messages = _mergeMessages(
                    serverMessages,
                    currentUserId,
                    pendingSent,
                  );
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.waving_hand_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Start the conversation!',
                              style: AppTypography.titleMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Say hi, send an emoji — break the ice.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.55),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: icebreakerList.indexed.map((entry) {
                                final (idx, s) = entry;
                                return ActionChip(
                                  label: Text(s),
                                  onPressed: () =>
                                      _sendMessageText(context, ref, s),
                                )
                                    .animate(
                                      delay: AppMotion.stagger(idx, stepMs: 50),
                                    )
                                    .fadeIn(duration: AppMotion.medium)
                                    .slideX(begin: 0.15, curve: AppMotion.spring);
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final reversed = messages.reversed.toList();
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, kToolbarHeight + MediaQuery.of(context).padding.top + 8, 16, 16),
                    reverse: true,
                    itemCount: reversed.length,
                    itemBuilder: (context, i) {
                      final m = reversed[i];
                      final isMe =
                          currentUserId != null && m.senderId == currentUserId;
                      final showDateSeparator =
                          i == 0 ||
                          !isSameLocalDay(m.sentAt, reversed[i - 1].sentAt);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateSeparator)
                            _DateSeparator(sentAt: m.sentAt),
                          _MessageBubble(
                                messageId: m.id,
                                text: m.text,
                                sentAt: m.sentAt,
                                isMe: isMe,
                                isVoiceNote: m.isVoiceNote,
                                peerReadAt: peerReadAt,
                                otherUserOnline: online,
                                otherLastActiveAt: lastActive,
                              )
                              .animate()
                              .fadeIn(delay: (20 * i).ms)
                              .slideY(begin: 0.03, end: 0),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref.invalidate(
                            _threadMessagesProvider(widget.threadId),
                          ),
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _TypingBar(
            initialText: widget.initialText,
            onSend: (text) => _sendMessageText(context, ref, text),
          ),
        ],
      ),
    );
  }
}

final _threadMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, threadId) {
      final viewerId = ref.watch(authRepositoryProvider).currentUserId;
      return ref.watch(chatRepositoryProvider).watchMessages(threadId, viewerUserId: viewerId);
    });

/// Bottom-right dot on chat header avatar: blue if online or active within [recentWithin], else pale.
enum _ChatHeaderPresence { offline, reachable }

_ChatHeaderPresence _chatHeaderPresence({
  required bool online,
  DateTime? lastActive,
  Duration recentWithin = const Duration(minutes: 10),
}) {
  if (online) return _ChatHeaderPresence.reachable;
  if (lastActive != null && DateTime.now().difference(lastActive) <= recentWithin) {
    return _ChatHeaderPresence.reachable;
  }
  return _ChatHeaderPresence.offline;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.sentAt});
  final DateTime sentAt;

  @override
  Widget build(BuildContext context) {
    final label = formatChatDateSeparator(sentAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.messageId,
    required this.text,
    required this.sentAt,
    required this.isMe,
    this.isVoiceNote = false,
    this.peerReadAt,
    this.otherUserOnline = false,
    this.otherLastActiveAt,
  });
  final String messageId;
  final String text;
  final DateTime sentAt;
  final bool isMe;
  final bool isVoiceNote;
  /// Other participant's read time (for ✓ on your messages).
  final DateTime? peerReadAt;
  /// From thread summary / presence — for double-grey "reachable" ticks.
  final bool otherUserOnline;
  final DateTime? otherLastActiveAt;

  static const Duration _recentlyActiveWindow = Duration(minutes: 10);

  /// True while message is only on the client (sending / not yet persisted).
  static bool _isClientOptimisticPending(String id) {
    if (id.startsWith('temp_')) return true;
    if (id.startsWith('pending-') && !id.startsWith('pending-req:')) return true;
    return false;
  }

  /// Persisted on server (including pending message-request rows).
  static bool _isDeliveredToServer(String id) => !_isClientOptimisticPending(id);

  static bool _readByPeer(DateTime sentAt, DateTime? peerReadAt) {
    if (peerReadAt == null) return false;
    return !peerReadAt.isBefore(sentAt.subtract(const Duration(seconds: 1)));
  }

  static bool _peerRecentlyReachable(bool online, DateTime? lastActive) {
    if (online) return true;
    if (lastActive == null) return false;
    return DateTime.now().difference(lastActive) <= _recentlyActiveWindow;
  }

  /// WhatsApp-style: single = sent (they're offline / not recently active), double grey = online or active ~10m, double green = read.
  Widget? _outgoingReceiptRow(Color outgoingFg) {
    if (!isMe) return null;
    final optimistic = _isClientOptimisticPending(messageId);
    if (optimistic) {
      return Icon(
        Icons.done_rounded,
        size: 15,
        color: outgoingFg.withValues(alpha: 0.42),
      );
    }
    if (!_isDeliveredToServer(messageId)) return null;

    final read = _readByPeer(sentAt, peerReadAt);
    if (read) {
      return Icon(
        Icons.done_all_rounded,
        size: 15,
        color: const Color(0xFF8FE1A0),
      );
    }
    if (_peerRecentlyReachable(otherUserOnline, otherLastActiveAt)) {
      return Icon(
        Icons.done_all_rounded,
        size: 15,
        color: outgoingFg.withValues(alpha: 0.52),
      );
    }
    return Icon(
      Icons.done_rounded,
      size: 15,
      color: outgoingFg.withValues(alpha: 0.88),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final onSurface = cs.onSurface;
    final timeStr = formatChatBubbleTime(sentAt);
    // Outgoing: use saturated brand oranges — ColorScheme.primary can resolve to a light
    // tint on some devices/themes (peach + white text = unreadable).
    final bool light = theme.brightness == Brightness.light;
    final bubbleBg = isMe
        ? (light ? AppColors.saffronDark : AppColors.darkAccentDim)
        : cs.surfaceContainerHighest;
    const outgoingFg = Colors.white;
    final textColor = isMe ? outgoingFg : onSurface;
    final timeColor = isMe
        ? outgoingFg.withValues(alpha: 0.88)
        : onSurface.withValues(alpha: 0.55);
    final receipt = _outgoingReceiptRow(outgoingFg);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 18),
          ),
          border: isMe
              ? Border.all(
                  color: outgoingFg.withValues(alpha: 0.2),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isVoiceNote)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mic_rounded,
                    size: 18,
                    color: isMe ? outgoingFg : cs.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '0:12',
                    style: AppTypography.caption.copyWith(color: textColor),
                  ),
                ],
              )
            else
              SelectableText(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    timeStr,
                    style: AppTypography.caption.copyWith(
                      color: timeColor,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (receipt != null) receipt,
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _TypingBar extends StatefulWidget {
  const _TypingBar({required this.onSend, this.initialText});
  final ValueChanged<String> onSend;
  final String? initialText;

  @override
  State<_TypingBar> createState() => _TypingBarState();
}

class _TypingBarState extends State<_TypingBar>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final AnimationController _sendAnim;

  @override
  void initState() {
    super.initState();
    _sendAnim = AnimationController(
      vsync: this,
      duration: AppMotion.micro,
      lowerBound: 0.88,
      upperBound: 1.0,
    );
    final initial = widget.initialText;
    if (initial != null && initial.trim().isNotEmpty) {
      _controller.text = initial.trim();
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: EmojiPicker(
                textEditingController: _controller,
                config: Config(
                  height: 256,
                  emojiViewConfig: EmojiViewConfig(
                    emojiSizeMax: 28,
                    backgroundColor: Theme.of(ctx).colorScheme.surface,
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    backgroundColor: Theme.of(ctx)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    indicatorColor: Theme.of(ctx).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerSend() async {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    await _sendAnim.reverse();
    await _sendAnim.forward();
    widget.onSend(t);
    _controller.clear();
  }

  @override
  void dispose() {
    _sendAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: isDark ? 0.80 : 0.88),
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          child: SafeArea(
            top: false,
        child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                Icons.emoji_emotions_outlined,
                color: onSurface.withValues(alpha: 0.6),
              ),
              onPressed: _showEmojiPicker,
              tooltip: l.chatEmojiTooltip,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: l.chatMessageHint,
                  filled: true,
                  fillColor: onSurface.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _triggerSend(),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedBuilder(
              animation: _sendAnim,
              builder: (_, child) => Transform.scale(
                scale: _sendAnim.value,
                child: child,
              ),
              child: IconButton.filled(
                icon: const Icon(Icons.send_rounded, size: 22),
                onPressed: _triggerSend,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        ),
          ),
        ),
      ),
    );
  }
}
