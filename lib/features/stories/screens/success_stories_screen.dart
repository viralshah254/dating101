import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _SuccessStory {
  const _SuccessStory({
    required this.id,
    required this.title,
    required this.storyText,
    required this.timelineMonths,
    required this.photoUrl,
    required this.engagedAt,
    required this.createdAt,
  });

  final String id;
  final String? title;
  final String storyText;
  final int? timelineMonths;
  final String? photoUrl;
  final String? engagedAt;
  final String createdAt;

  factory _SuccessStory.fromJson(Map<String, dynamic> j) => _SuccessStory(
        id: j['id'] as String,
        title: j['title'] as String?,
        storyText: j['storyText'] as String? ?? '',
        timelineMonths: (j['timelineMonths'] as num?)?.toInt(),
        photoUrl: j['photoUrl'] as String?,
        engagedAt: j['engagedAt'] as String?,
        createdAt: j['createdAt'] as String? ?? '',
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _storiesProvider = FutureProvider.autoDispose<List<_SuccessStory>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/success-stories');
  final list = res['stories'] as List? ?? [];
  return list.map((e) => _SuccessStory.fromJson(Map<String, dynamic>.from(e as Map))).toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class SuccessStoriesScreen extends ConsumerWidget {
  const SuccessStoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final stories = ref.watch(_storiesProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Success Stories'),
        backgroundColor: cs.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_storiesProvider),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showSubmitStory(context, ref),
          ),
        ],
      ),
      body: stories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load stories: $e')),
        data: (list) {
          if (list.isEmpty) {
            return _EmptyView(onSubmit: () => _showSubmitStory(context, ref));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) => _StoryCard(story: list[i]),
          );
        },
      ),
    );
  }

  void _showSubmitStory(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SubmitStorySheet(onSubmitted: () {
        ref.invalidate(_storiesProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story submitted for review! Thank you 💍'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }),
    );
  }
}

// ── Story Card ────────────────────────────────────────────────────────────────

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});
  final _SuccessStory story;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.06),
            AppColors.gold.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo header
          if (story.photoUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                story.photoUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PlaceholderImage(),
              ),
            )
          else
            _PlaceholderImage(),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title / badges
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, size: 16, color: AppColors.rosePrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        story.title ?? 'A Beautiful Union',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (story.timelineMonths != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${story.timelineMonths} months',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Story text
                Text(
                  story.storyText,
                  style: AppTypography.bodySmall.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    if (story.engagedAt != null)
                      Row(
                        children: [
                          Icon(Icons.diamond_rounded, size: 12, color: AppColors.gold),
                          const SizedBox(width: 4),
                          Text(
                            'Engaged ${_formatDate(story.engagedAt!)}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.share_rounded, size: 18, color: cs.primary),
                      onPressed: () => _shareStory(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  void _shareStory(BuildContext context) {
    final text = '💍 ${story.title ?? "A Beautiful Shubhmilan Story"}\n\n${story.storyText.length > 200 ? "${story.storyText.substring(0, 200)}..." : story.storyText}\n\nFind your match on Shubhmilan 💫\nhttps://shubhmilan.com';
    Share.share(text);
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          colors: [AppColors.rosePrimary.withValues(alpha: 0.15), AppColors.gold.withValues(alpha: 0.1)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.favorite_rounded, size: 48, color: AppColors.rosePrimary),
      ),
    );
  }
}

// ── Empty View ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onSubmit});
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, size: 64, color: AppColors.rosePrimary),
            const SizedBox(height: 20),
            Text(
              'No stories yet',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your Shubhmilan success story!',
              style: AppTypography.bodyMedium.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Share Your Story'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Submit Story Sheet ────────────────────────────────────────────────────────

class _SubmitStorySheet extends ConsumerStatefulWidget {
  const _SubmitStorySheet({required this.onSubmitted});
  final VoidCallback onSubmitted;

  @override
  ConsumerState<_SubmitStorySheet> createState() => _SubmitStorySheetState();
}

class _SubmitStorySheetState extends ConsumerState<_SubmitStorySheet> {
  final _titleCtrl = TextEditingController();
  final _storyCtrl = TextEditingController();
  int? _timelineMonths;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _storyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_storyCtrl.text.trim().length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write at least 50 characters'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/success-stories', body: {
        'title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        'storyText': _storyCtrl.text.trim(),
        if (_timelineMonths != null) 'timelineMonths': _timelineMonths,
      });
      widget.onSubmitted();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share Your Success Story 💍',
                style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Stories are reviewed before publishing to inspire others.',
                style: AppTypography.bodySmall.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  hintText: 'e.g. "We found each other on Shubhmilan"',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _storyCtrl,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Your story *',
                  hintText: 'Tell us how you met, what made it special, and your journey to engagement...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _timelineMonths,
                decoration: const InputDecoration(
                  labelText: 'Time from match to engagement',
                  border: OutlineInputBorder(),
                ),
                items: [1, 2, 3, 4, 5, 6, 9, 12, 18, 24, 36]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m month${m == 1 ? '' : 's'}')))
                    .toList(),
                onChanged: (v) => setState(() => _timelineMonths = v),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Story'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
