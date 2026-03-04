import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Asset path for the referral promo banner image (popup and in-feed).
const String referralPromoBannerAsset = 'assets/images/shubhmilan_ad_1.png';

/// Tappable referral promo card: shows the banner image and navigates to invite screen on tap.
/// Use in-feed between profiles or inside a dialog.
class ReferralPromoBanner extends StatelessWidget {
  const ReferralPromoBanner({
    super.key,
    this.imagePath = referralPromoBannerAsset,
    this.aspectRatio = 1.2,
    this.borderRadius = 16,
    this.onTap,
  });

  final String imagePath;
  final double aspectRatio;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => context.push('/referral'),
        borderRadius: BorderRadius.circular(borderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      color: accent.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard_rounded, size: 48, color: accent),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.referNow,
            style: AppTypography.titleMedium.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
