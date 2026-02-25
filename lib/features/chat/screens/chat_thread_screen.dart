import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../discovery/providers/discovery_providers.dart';

/// Single chat thread. Uses [threadId] and optional [otherUserId] for profile and "me" detection.
class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.threadId, this.otherUserId});

  final String threadId;
  final String? otherUserId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markThreadRead(widget.threadId);
    });
  }

  void _showMoreOptions(BuildContext context, WidgetRef ref, String? otherUserId) {
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            if (otherUserId != null)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('View profile'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/profile/$otherUserId');
                },
              ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block user', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                if (otherUserId == null) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Block user?'),
                    content: const Text('They won\'t be able to contact you anymore.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () => Navigator.pop(d, true),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Block'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !mounted) return;
                try {
                  await ref.read(discoveryRepositoryProvider).sendFeedback(candidateId: otherUserId, action: 'block');
                  if (mounted) context.pop();
                } catch (_) {}
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text('Report user'),
              onTap: () async {
                Navigator.pop(ctx);
                if (otherUserId == null) return;
                try {
                  await ref.read(discoveryRepositoryProvider).sendFeedback(candidateId: otherUserId, action: 'report');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted. Thank you.'), behavior: SnackBarBehavior.floating),
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

  @override
  Widget build(BuildContext context) {
    final chatRepo = ref.watch(chatRepositoryProvider);
    final currentUserId = ref.watch(authRepositoryProvider).currentUserId;
    final messagesAsync = ref.watch(_threadMessagesProvider(widget.threadId));
    final otherUserId = widget.otherUserId;
    final profileAsync = otherUserId != null ? ref.watch(profileSummaryProvider(otherUserId)) : null;

    final displayName = profileAsync?.valueOrNull?.name ?? 'Chat';
    final subtitle = profileAsync?.valueOrNull?.city != null
        ? '${profileAsync!.valueOrNull!.city} · Active now'
        : 'Active now';

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            if (otherUserId != null) context.push('/profile/$otherUserId');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
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
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Say hi!',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[messages.length - 1 - i];
                    final isMe = currentUserId != null && m.senderId == currentUserId;
                    return _MessageBubble(
                      text: m.text,
                      sentAt: m.sentAt,
                      isMe: isMe,
                      isVoiceNote: m.isVoiceNote,
                    ).animate().fadeIn(delay: (20 * i).ms).slideY(begin: 0.03, end: 0);
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
                      Text(err.toString(), textAlign: TextAlign.center, style: AppTypography.bodySmall),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(_threadMessagesProvider(widget.threadId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _TypingBar(
            onSend: (text) async {
              await chatRepo.sendMessage(widget.threadId, text);
              ref.invalidate(_threadMessagesProvider(widget.threadId));
            },
            onVoice: () {},
          ),
        ],
      ),
    );
  }
}

final _threadMessagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, threadId) {
  return ref.watch(chatRepositoryProvider).watchMessages(threadId);
});

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
    final timeStr = _formatTime(sentAt);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.saffron.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? Border.all(color: AppColors.saffron.withValues(alpha: 0.3)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isVoiceNote)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('0:12', style: AppTypography.caption),
                ],
              )
            else
              Text(text, style: AppTypography.bodyMedium),
            const SizedBox(height: 2),
            Text(
              timeStr,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _TypingBar extends StatefulWidget {
  const _TypingBar({required this.onSend, required this.onVoice});
  final ValueChanged<String> onSend;
  final VoidCallback onVoice;

  @override
  State<_TypingBar> createState() => _TypingBarState();
}

class _TypingBarState extends State<_TypingBar> {
  final _controller = TextEditingController();

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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.mic_rounded, color: onSurface.withValues(alpha: 0.6)),
              onPressed: widget.onVoice,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                maxLines: null,
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
