import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

/// Week 9 — AI: Match reasoning shown on discovery cards.
class MatchReasonChip extends StatelessWidget {
  const MatchReasonChip({
    super.key,
    required this.reason,
    this.icon = Icons.auto_awesome,
  });

  final String reason;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              reason,
              style: AppTypography.labelSmall.copyWith(color: accent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
