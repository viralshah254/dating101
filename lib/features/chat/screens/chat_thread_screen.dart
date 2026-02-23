import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../discovery/models/discovery_profile.dart';

class ChatThreadScreen extends StatelessWidget {
  const ChatThreadScreen({super.key, required this.threadId});

  final String threadId;

  @override
  Widget build(BuildContext context) {
    final messages = _mockMessages;
    final profile = getDiscoveryProfileById(threadId);
    final displayName = profile?.name ?? 'Chat';
    final subtitle = profile != null
        ? '${profile.city} · Active now'
        : 'Active now';

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            if (profile != null) context.push('/profile/${profile.id}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(displayName),
                Text(
                  subtitle,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                final align = m.isMe ? Alignment.centerRight : Alignment.centerLeft;
                return Align(
                  alignment: align,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: m.isMe
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(m.isMe ? 16 : 4),
                        bottomRight: Radius.circular(m.isMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (m.isVoiceNote)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text('0:12', style: AppTypography.caption),
                            ],
                          )
                        else
                          Text(m.text, style: AppTypography.bodyMedium),
                        const SizedBox(height: 2),
                        Text(
                          m.time,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (30 * i).ms).slideY(begin: 0.05, end: 0),
                );
              },
            ),
          ),
          _TypingBar(
            onSend: (text) {},
            onVoice: () {},
          ),
        ],
      ),
    );
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.mic),
              onPressed: widget.onVoice,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    widget.onSend(v);
                    _controller.clear();
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                final t = _controller.text.trim();
                if (t.isNotEmpty) {
                  widget.onSend(t);
                  _controller.clear();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  _Message({
    required this.text,
    required this.time,
    required this.isMe,
    this.isVoiceNote = false,
  });
  final String text;
  final String time;
  final bool isMe;
  final bool isVoiceNote;
}

final List<_Message> _mockMessages = [
  _Message(text: 'Hey! Loved your prompt about Sundays.', time: '10:02', isMe: true, isVoiceNote: false),
  _Message(text: 'Thanks! What are you up to this weekend?', time: '10:05', isMe: false, isVoiceNote: false),
  _Message(text: 'Thinking of a walk and brunch. You?', time: '10:06', isMe: true, isVoiceNote: false),
  _Message(text: 'That sounds great! How about Saturday?', time: '10:08', isMe: false, isVoiceNote: false),
];
