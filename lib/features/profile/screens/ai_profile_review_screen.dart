import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/entitlements/entitlements.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _Improvement {
  const _Improvement({
    required this.field,
    required this.issue,
    required this.tip,
    required this.priority,
  });

  final String field;
  final String issue;
  final String tip;
  final String priority;

  factory _Improvement.fromJson(Map<String, dynamic> j) => _Improvement(
        field: j['field'] as String? ?? '',
        issue: j['issue'] as String? ?? '',
        tip: j['tip'] as String? ?? '',
        priority: j['priority'] as String? ?? 'medium',
      );
}

class _ReviewResult {
  const _ReviewResult({
    required this.overallScore,
    required this.overallLabel,
    required this.strengths,
    required this.improvements,
    required this.photoTips,
    required this.bioTips,
    this.comparedToSuccessful,
    required this.isAiPowered,
    this.cachedAt,
    this.retryAfter,
  });

  final int overallScore;
  final String overallLabel;
  final List<String> strengths;
  final List<_Improvement> improvements;
  final List<String> photoTips;
  final List<String> bioTips;
  final String? comparedToSuccessful;
  final bool isAiPowered;
  final DateTime? cachedAt;
  final int? retryAfter; // seconds until rate-limit resets

  factory _ReviewResult.fromJson(Map<String, dynamic> j) {
    List<String> toStringList(Object? raw) =>
        raw is List ? raw.map((e) => e.toString()).toList() : [];

    DateTime? parsedCachedAt;
    final cachedRaw = j['cachedAt'] as String?;
    if (cachedRaw != null) {
      parsedCachedAt = DateTime.tryParse(cachedRaw);
    }

    return _ReviewResult(
      overallScore: (j['overallScore'] as num?)?.toInt() ?? 0,
      overallLabel: j['overallLabel'] as String? ?? 'Profile Review',
      strengths: toStringList(j['strengths']),
      improvements: (j['improvements'] as List? ?? [])
          .map((e) => _Improvement.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      photoTips: toStringList(j['photoTips']),
      bioTips: toStringList(j['bioTips']),
      comparedToSuccessful: j['comparedToSuccessful'] as String?,
      isAiPowered: j['isAiPowered'] as bool? ?? false,
      cachedAt: parsedCachedAt,
      retryAfter: (j['retryAfter'] as num?)?.toInt(),
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _profileReviewProvider = FutureProvider.autoDispose<_ReviewResult>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.post('/profile/me/review', body: {});
  return _ReviewResult.fromJson(res);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AiProfileReviewScreen extends ConsumerWidget {
  const AiProfileReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final entitlements = ref.watch(entitlementsProvider);
    final hasAiReview = entitlements.hasAiReview;
    final review = ref.watch(_profileReviewProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Profile Review'),
            const SizedBox(width: 8),
            _AiBadge(isAiPowered: hasAiReview),
          ],
        ),
        backgroundColor: cs.surface,
        elevation: 0,
        actions: [
          if (hasAiReview)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh review',
              onPressed: () => ref.invalidate(_profileReviewProvider),
            ),
        ],
      ),
      body: Column(
        children: [
          // Upgrade banner for free/silver users
          if (!hasAiReview) const _UpgradeBanner(),
          Expanded(
            child: review.when(
              loading: () => _LoadingView(isAi: hasAiReview),
              error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(_profileReviewProvider)),
              data: (result) => _ReviewView(result: result, hasAiReview: hasAiReview),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upgrade banner ────────────────────────────────────────────────────────────

class _UpgradeBanner extends StatelessWidget {
  const _UpgradeBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold.withValues(alpha: 0.15), AppColors.saffron.withValues(alpha: 0.08)],
        ),
        border: Border(bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Basic Review — Upgrade to Gold for AI-powered coaching',
                  style: AppTypography.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'AI review analyses photos, bio & preferences with personalised tips',
                  style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
            ),
            onPressed: () => context.push('/premium'),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

// ── AI badge chip ─────────────────────────────────────────────────────────────

class _AiBadge extends StatelessWidget {
  const _AiBadge({required this.isAiPowered});
  final bool isAiPowered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isAiPowered
            ? AppColors.gold.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAiPowered ? AppColors.gold.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAiPowered ? Icons.auto_awesome_rounded : Icons.rule_rounded,
            size: 10,
            color: isAiPowered ? AppColors.gold : Colors.grey,
          ),
          const SizedBox(width: 3),
          Text(
            isAiPowered ? 'AI' : 'Basic',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isAiPowered ? AppColors.gold : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.isAi});
  final bool isAi;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: cs.primary),
          const SizedBox(height: 20),
          Text(
            isAi ? 'Our AI is analysing your profile…' : 'Checking your profile…',
            style: AppTypography.bodyMedium.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            isAi
                ? 'Reviewing photos, bio, and preferences'
                : 'Checking completeness and trust signals',
            style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text('Could not load review. Please try again.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Review content ────────────────────────────────────────────────────────────

class _ReviewView extends StatelessWidget {
  const _ReviewView({required this.result, required this.hasAiReview});
  final _ReviewResult result;
  final bool hasAiReview;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      children: [
        _ScoreCard(result: result),
        const SizedBox(height: 12),

        // Rate-limit notice
        if (result.retryAfter != null && result.retryAfter! > 0) ...[
          _InfoBanner(
            icon: Icons.schedule_rounded,
            color: AppColors.saffron,
            message: 'Daily AI refresh limit reached. Showing cached review. '
                'Refresh available in ${_formatDuration(result.retryAfter!)}.',
          ),
          const SizedBox(height: 12),
        ],

        // Cache info for AI users
        if (result.isAiPowered && result.cachedAt != null) ...[
          _InfoBanner(
            icon: Icons.cached_rounded,
            color: cs.primary,
            message: 'AI review from ${_formatDate(result.cachedAt!)}. '
                'Refreshes automatically when you update your profile.',
          ),
          const SizedBox(height: 12),
        ],

        // Compared to successful
        if (result.comparedToSuccessful != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.insights_rounded, color: cs.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.comparedToSuccessful!,
                    style: AppTypography.bodySmall.copyWith(color: cs.onSurface.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (result.strengths.isNotEmpty) ...[
          _SectionHeader(icon: Icons.thumb_up_rounded, label: "What's working", color: AppColors.indiaGreen),
          const SizedBox(height: 10),
          ...result.strengths.map((s) => _BulletItem(text: s, color: AppColors.indiaGreen, icon: Icons.check_circle_rounded)),
          const SizedBox(height: 20),
        ],

        if (result.improvements.isNotEmpty) ...[
          _SectionHeader(icon: Icons.build_rounded, label: 'Improvements', color: cs.primary),
          const SizedBox(height: 10),
          ...result.improvements.map((imp) => _ImprovementCard(imp: imp)),
          const SizedBox(height: 20),
        ],

        if (result.photoTips.isNotEmpty) ...[
          _SectionHeader(icon: Icons.photo_camera_rounded, label: 'Photo Tips', color: const Color(0xFF7B1FA2)),
          const SizedBox(height: 10),
          ...result.photoTips.map((t) => _BulletItem(text: t, color: const Color(0xFF7B1FA2), icon: Icons.camera_alt_outlined)),
          const SizedBox(height: 20),
        ],

        if (result.bioTips.isNotEmpty) ...[
          _SectionHeader(icon: Icons.edit_note_rounded, label: 'Bio Tips', color: const Color(0xFFE65100)),
          const SizedBox(height: 10),
          ...result.bioTips.map((t) => _BulletItem(text: t, color: const Color(0xFFE65100), icon: Icons.lightbulb_outline_rounded)),
          const SizedBox(height: 20),
        ],

        // Upsell for non-AI users
        if (!result.isAiPowered && !hasAiReview) ...[
          _UpgradeCard(),
        ],
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 3600) return '${seconds ~/ 60} minutes';
    return '${seconds ~/ 3600} hours';
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.color, required this.message});
  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(color: color.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  _UpgradeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold.withValues(alpha: 0.12), AppColors.saffron.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 28),
          const SizedBox(height: 10),
          Text(
            'Get AI-powered coaching',
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Upgrade to Gold to unlock personalised AI analysis of your photos, '
            'bio, and preferences — and see exactly why matches accept or ignore you.',
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.gold),
            icon: const Icon(Icons.workspace_premium_rounded, size: 16),
            label: const Text('Upgrade to Gold'),
            onPressed: () => context.push('/premium'),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});
  final _ReviewResult result;

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.indiaGreen;
    if (score >= 60) return AppColors.saffron;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _scoreColor(result.overallScore);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: result.overallScore / 100,
                  strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${result.overallScore}',
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontSize: 26,
                      ),
                    ),
                    Text(
                      'Score',
                      style: AppTypography.caption.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.overallLabel,
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  result.improvements.isEmpty
                      ? 'Great job! Keep it up.'
                      : '${result.improvements.where((i) => i.priority == "high").length} high-priority improvements',
                  style: AppTypography.bodySmall.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _AiBadge(isAiPowered: result.isAiPowered),
                    const SizedBox(width: 8),
                    Icon(Icons.star_rounded, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${result.strengths.length} strengths  •  ${result.improvements.length} improvements',
                      style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text, required this.color, required this.icon});
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTypography.bodySmall.copyWith(color: cs.onSurface.withValues(alpha: 0.85))),
          ),
        ],
      ),
    );
  }
}

class _ImprovementCard extends StatelessWidget {
  const _ImprovementCard({required this.imp});
  final _Improvement imp;

  Color _priorityColor() {
    switch (imp.priority) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return AppColors.saffron;
      default:
        return AppColors.indiaGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _priorityColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  imp.priority.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  imp.issue,
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 14, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  imp.tip,
                  style: AppTypography.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.75)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
