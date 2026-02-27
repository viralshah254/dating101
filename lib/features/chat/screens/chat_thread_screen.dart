import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/safety/safety_reason_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../providers/chat_providers.dart';

/// Single chat thread. Uses [threadId] and optional [otherUserId] for profile and "me" detection.
class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.threadId, this.otherUserId});

  final String threadId;
  final String? otherUserId;

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
  /// Optimistic messages we just sent; shown until server list includes them.
  final List<ChatMessage> _pendingSent = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(chatRepositoryProvider).markThreadRead(widget.threadId);
        if (mounted) ref.invalidate(chatThreadsProvider);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _sendMessageText(
    BuildContext context,
    WidgetRef ref,
    String text,
  ) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final me = ref.read(authRepositoryProvider).currentUserId;
    setState(() {
      _pendingSent.add(
        ChatMessage(
          id: 'pending-${DateTime.now().millisecondsSinceEpoch}',
          senderId: me ?? 'me',
          text: text,
          sentAt: DateTime.now(),
        ),
      );
    });
    try {
      await chatRepo.sendMessage(widget.threadId, text);
    } on ApiException catch (e) {
      if (context.mounted) {
        setState(() => _pendingSent.removeWhere((m) => m.text == text));
        final showUpgrade =
            e.code == 'PREMIUM_REQUIRED' || e.code == 'INTRO_LIMIT';
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
        setState(() => _pendingSent.removeWhere((m) => m.text == text));
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
    ref.invalidate(_threadMessagesProvider(widget.threadId));
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
                color: Colors.grey.withValues(alpha: 0.3),
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
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text(
                AppLocalizations.of(ctx)!.blockUser,
                style: const TextStyle(color: Colors.red),
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
                            backgroundColor: Colors.red,
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
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
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
                            backgroundColor: Colors.orange,
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

  /// Merge server messages with pending sent, deduping so we don't show the same message twice.
  List<ChatMessage> _mergeMessages(
    List<ChatMessage> server,
    String? currentUserId,
  ) {
    final merged = List<ChatMessage>.from(server);
    for (final p in _pendingSent) {
      final match = merged.any(
        (m) =>
            m.senderId == p.senderId &&
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
    final suggestionsAsync = ref.watch(chatSuggestionsProvider);
    final icebreakerList =
        suggestionsAsync.valueOrNull ?? _icebreakerSuggestions;
    final otherUserId = widget.otherUserId;
    final profileAsync = otherUserId != null
        ? ref.watch(profileSummaryProvider(otherUserId))
        : null;

    ref.listen(_threadMessagesProvider(widget.threadId), (prev, next) {
      if (!next.hasValue || _pendingSent.isEmpty) return;
      if (!context.mounted) return;
      final list = next.value!;
      setState(() {
        _pendingSent.removeWhere(
          (p) => list.any(
            (m) =>
                m.senderId == p.senderId &&
                m.text == p.text &&
                (m.sentAt.difference(p.sentAt).inSeconds.abs() < 120),
          ),
        );
      });
    });

    final profile = profileAsync?.valueOrNull;
    final displayName = profile?.name ?? 'Chat';
    final compatibilityScore = profile?.compatibilityScore;
    final scoreLabel = compatibilityScore != null
        ? '${(compatibilityScore * 100).round()}% match'
        : null;
    final subtitle =
        scoreLabel ??
        (profile?.city != null
            ? '${profile!.city!} · Active now'
            : 'Active now');

    final avatarUrl = profile?.imageUrl;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.saffron.withValues(alpha: 0.2),
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          initial,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.saffron,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
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
                                color: AppColors.saffron.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.waving_hand_rounded,
                                size: 48,
                                color: AppColors.saffron.withValues(alpha: 0.8),
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
                              children: icebreakerList.map((s) {
                                return ActionChip(
                                  label: Text(s),
                                  onPressed: () =>
                                      _sendMessageText(context, ref, s),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final reversed = messages.reversed.toList();
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    reverse: true,
                    itemCount: reversed.length,
                    itemBuilder: (context, i) {
                      final m = reversed[i];
                      final isMe =
                          currentUserId != null && m.senderId == currentUserId;
                      final showDateSeparator =
                          i == 0 ||
                          !_isSameDay(m.sentAt, reversed[i - 1].sentAt);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateSeparator)
                            _DateSeparator(sentAt: m.sentAt),
                          _MessageBubble(
                                text: m.text,
                                sentAt: m.sentAt,
                                isMe: isMe,
                                isVoiceNote: m.isVoiceNote,
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
          _TypingBar(onSend: (text) => _sendMessageText(context, ref, text)),
        ],
      ),
    );
  }
}

final _threadMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, threadId) {
      return ref.watch(chatRepositoryProvider).watchMessages(threadId);
    });

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.sentAt});
  final DateTime sentAt;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(sentAt.year, sentAt.month, sentAt.day);
    String label;
    if (messageDay == today) {
      label = 'Today';
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      label = DateFormat.MMMd().format(sentAt);
    }
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
    required this.text,
    required this.sentAt,
    required this.isMe,
    this.isVoiceNote = false,
  });
  final String text;
  final DateTime sentAt;
  final bool isMe;
  final bool isVoiceNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final timeStr = _formatTime(sentAt);
    final bubbleBg = isMe
        ? AppColors.saffron.withValues(alpha: 0.2)
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe ? const Color(0xFF5C3400) : onSurface;
    final timeColor = isMe
        ? const Color(0xFF8B5A00).withValues(alpha: 0.85)
        : onSurface.withValues(alpha: 0.55);

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
              ? Border.all(color: AppColors.saffron.withValues(alpha: 0.35))
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
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '0:12',
                    style: AppTypography.caption.copyWith(color: textColor),
                  ),
                ],
              )
            else
              Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: AppTypography.caption.copyWith(
                color: timeColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      return DateFormat.jm().format(d);
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.day == yesterday.day &&
        d.month == yesterday.month &&
        d.year == yesterday.year) {
      return 'Yesterday ${DateFormat.jm().format(d)}';
    }
    if (diff.inDays < 7) return DateFormat.E().add_jm().format(d);
    return DateFormat.MMMd().add_jm().format(d);
  }
}

class _TypingBar extends StatefulWidget {
  const _TypingBar({required this.onSend});
  final ValueChanged<String> onSend;

  @override
  State<_TypingBar> createState() => _TypingBarState();
}

class _TypingBarState extends State<_TypingBar> {
  final _controller = TextEditingController();

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
                    indicatorColor: AppColors.saffron,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SafeArea(
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
              tooltip: 'Emoji',
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Message...',
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
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    widget.onSend(v.trim());
                    _controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              icon: const Icon(Icons.send_rounded, size: 22),
              onPressed: () {
                final t = _controller.text.trim();
                if (t.isNotEmpty) {
                  widget.onSend(t);
                  _controller.clear();
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.saffron,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
