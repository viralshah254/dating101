import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_typography.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final threads = _mockThreads;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chats',
          style: AppTypography.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: threads.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final t = threads[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                style: AppTypography.labelLarge,
              ),
            ),
            title: Text(
              t.name,
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              t.lastMessage,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (t.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${t.unreadCount}',
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                else
                  Text(
                    t.timeAgo,
                    style: AppTypography.caption,
                  ),
              ],
            ),
            onTap: () => context.push('/chat/${t.id}'),
          );
        },
      ),
    );
  }
}

class _ChatThreadPreview {
  _ChatThreadPreview({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.timeAgo,
    this.unreadCount = 0,
  });
  final String id;
  final String name;
  final String lastMessage;
  final String timeAgo;
  final int unreadCount;
}

final List<_ChatThreadPreview> _mockThreads = [
  _ChatThreadPreview(
    id: '1',
    name: 'Priya',
    lastMessage: 'That sounds great! How about Saturday?',
    timeAgo: '2m',
    unreadCount: 1,
  ),
  _ChatThreadPreview(
    id: '2',
    name: 'Ananya',
    lastMessage: 'Sure, let\'s do the coffee spot you mentioned.',
    timeAgo: '1h',
  ),
];
