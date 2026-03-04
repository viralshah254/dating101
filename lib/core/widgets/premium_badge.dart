import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Badge showing "Premium" or "Free" for profile/cards.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({
    super.key,
    required this.isPremium,
    this.compact = false,
  });

  final bool isPremium;
  /// If true, show icon-only or smaller chip.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = isPremium ? AppColors.saffron : Colors.grey;
    if (compact) {
      return Tooltip(
        message: isPremium ? 'Premium' : 'Free',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Icon(
            isPremium ? Icons.workspace_premium_rounded : Icons.person_outline_rounded,
            size: 14,
            color: color,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.workspace_premium_rounded : Icons.person_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isPremium ? 'Premium' : 'Free',
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
