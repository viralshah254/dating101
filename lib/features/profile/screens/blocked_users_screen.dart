import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/blocked_user_entry.dart';

final _blockedListProvider = FutureProvider<List<BlockedUserEntry>>((
  ref,
) async {
  final repo = ref.watch(safetyRepositoryProvider);
  return repo.getBlockedUsers(limit: 50);
});

/// Privacy & safety: list of blocked users with option to unblock.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_blockedListProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blocked users',
          style: AppTypography.headlineSmall.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You haven\'t blocked anyone',
                    style: AppTypography.bodyLarge.copyWith(
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_blockedListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final entry = list[index];
                return _BlockedUserTile(
                  entry: entry,
                  onUnblock: () async {
                    try {
                      await ref
                          .read(safetyRepositoryProvider)
                          .unblock(entry.blockedUserId);
                      if (context.mounted) ref.invalidate(_blockedListProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${entry.profile.name} unblocked'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Could not unblock. Please try again.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Something went wrong', style: AppTypography.bodyLarge),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.invalidate(_blockedListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({required this.entry, required this.onUnblock});

  final BlockedUserEntry entry;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final p = entry.profile;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: p.imageUrl != null && p.imageUrl!.isNotEmpty
            ? NetworkImage(p.imageUrl!)
            : null,
        child: p.imageUrl == null || p.imageUrl!.isEmpty
            ? Text((p.name.isNotEmpty ? p.name[0] : '?').toUpperCase())
            : null,
      ),
      title: Text(
        p.name,
        style: AppTypography.titleMedium.copyWith(color: onSurface),
      ),
      subtitle: p.city != null || p.age != null
          ? Text(
              [
                if (p.age != null) '${p.age}',
                p.city,
              ].whereType<String>().join(' • '),
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            )
          : null,
      trailing: TextButton(onPressed: onUnblock, child: const Text('Unblock')),
    );
  }
}
