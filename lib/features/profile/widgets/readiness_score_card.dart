import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// ── Provider ──────────────────────────────────────────────────────────────

final readinessScoreProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/profile/me/readiness-score');
  return response;
});

// ── Widget ────────────────────────────────────────────────────────────────

/// A card showing the user's Marriage Readiness Score with breakdown and improvements.
class ReadinessScoreCard extends ConsumerWidget {
  const ReadinessScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(readinessScoreProvider);
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return scoreAsync.when(
      loading: () => _shimmerCard(context),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final score = (data['score'] as num?)?.toInt() ?? 0;
        final improvements = (data['improvements'] as List?)?.cast<String>() ?? [];
        final breakdown = data['breakdown'] as Map<String, dynamic>? ?? {};

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6A1B9A).withValues(alpha: 0.08),
                const Color(0xFFE91E63).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.15),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 18,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marriage Readiness Score',
                            style: AppTypography.titleSmall.copyWith(
                              color: onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Share to show matches you\'re serious',
                            style: AppTypography.bodySmall.copyWith(
                              color: onSurface.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Score donut + number
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomPaint(
                          painter: _ScoreDonutPainter(score: score),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: AppTypography.displaySmall.copyWith(
                              color: _scoreColor(score),
                              fontWeight: FontWeight.w800,
                              fontSize: 36,
                            ),
                          ),
                          Text(
                            _scoreTier(score),
                            style: AppTypography.labelSmall.copyWith(
                              color: _scoreColor(score).withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Breakdown bars
                if (breakdown.isNotEmpty) ...[
                  Text(
                    'Score Breakdown',
                    style: AppTypography.labelMedium.copyWith(
                      color: onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BreakdownBar(
                    label: 'Profile',
                    icon: Icons.person_rounded,
                    score: (breakdown['profileCompleteness']?['score'] as num?)?.toInt() ?? 0,
                    max: 30,
                    color: AppColors.gold,
                  ),
                  _BreakdownBar(
                    label: 'Verification',
                    icon: Icons.verified_rounded,
                    score: (breakdown['verification']?['score'] as num?)?.toInt() ?? 0,
                    max: 25,
                    color: const Color(0xFF1565C0),
                  ),
                  _BreakdownBar(
                    label: 'Marriage Intent',
                    icon: Icons.favorite_rounded,
                    score: (breakdown['marriageIntent']?['score'] as num?)?.toInt() ?? 0,
                    max: 15,
                    color: AppColors.rosePrimary,
                  ),
                  _BreakdownBar(
                    label: 'Preferences',
                    icon: Icons.tune_rounded,
                    score: (breakdown['partnerPreferences']?['score'] as num?)?.toInt() ?? 0,
                    max: 15,
                    color: const Color(0xFF00897B),
                  ),
                  _BreakdownBar(
                    label: 'Activity',
                    icon: Icons.bolt_rounded,
                    score: (breakdown['activity']?['score'] as num?)?.toInt() ?? 0,
                    max: 15,
                    color: const Color(0xFFE65100),
                  ),
                  const SizedBox(height: 16),
                ],

                // Improvements
                if (improvements.isNotEmpty) ...[
                  Text(
                    'How to improve',
                    style: AppTypography.labelMedium.copyWith(
                      color: onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...improvements.take(2).map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFFF57C00)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: AppTypography.bodySmall.copyWith(
                              color: onSurface.withValues(alpha: 0.75),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                ],

                // Share button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareScore(context, score),
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Share My Score'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6A1B9A),
                      side: const BorderSide(color: Color(0xFF6A1B9A), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Color _scoreColor(int score) {
    if (score >= 75) return const Color(0xFF00C853);
    if (score >= 50) return const Color(0xFF1565C0);
    if (score >= 25) return const Color(0xFFF57C00);
    return const Color(0xFFE53935);
  }

  static String _scoreTier(int score) {
    if (score >= 80) return 'HIGHLY READY';
    if (score >= 60) return 'READY';
    if (score >= 40) return 'BUILDING UP';
    return 'GETTING STARTED';
  }

  static void _shareScore(BuildContext context, int score) {
    final text = 'My Marriage Readiness Score on Shubhmilan is $score/100! '
        'Download the app to find your match 💍 https://shubhmilan.app';
    // Use platform share sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share your score: $score/100'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // Could use Clipboard.setData here
          },
        ),
      ),
    );
  }

  static Widget _shimmerCard(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({
    required this.label,
    required this.icon,
    required this.score,
    required this.max,
    required this.color,
  });

  final String label;
  final IconData icon;
  final int score;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final pct = score / max;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$score/$max',
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreDonutPainter extends CustomPainter {
  const _ScoreDonutPainter({required this.score});
  final int score;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 12.0;
    const startAngle = -math.pi / 2;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
    final sweepAngle = 2 * math.pi * (score / 100);
    final Color color;
    if (score >= 75) color = const Color(0xFF00C853);
    else if (score >= 50) color = const Color(0xFF1565C0);
    else if (score >= 25) color = const Color(0xFFF57C00);
    else color = const Color(0xFFE53935);

    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreDonutPainter old) => old.score != score;
}
