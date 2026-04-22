/**
 * Photo gate overlays for monetisation.
 *
 * - _AdRevealOverlay: shown on photos 2 and 3 for free male users.
 *   Tapping plays a rewarded AdMob ad; on completion the photo is unlocked locally.
 *
 * - PremiumRevealOverlay: shown on photo 4+ (or after ad limit).
 *   Hard gate — user must upgrade or have their interest accepted.
 *
 * Usage: wrap any photo widget with GatedPhoto, passing photosVisibleCount
 * (from entitlements) + isAccepted (from ProfileSummaryDto).
 */

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// ── Test ad unit IDs (replace with real IDs before release) ──────────────────

const _kRewardedAdUnitIdAndroid = 'ca-app-pub-3940256099942544/5354046379';
const _kRewardedAdUnitIdIos = 'ca-app-pub-3940256099942544/1712485313';

// ── GatedPhoto widget ─────────────────────────────────────────────────────────

/// Wraps a photo widget with the appropriate gate overlay.
///
/// [photoIndex]       0-based index of this photo in the carousel.
/// [photosVisibleCount] baseline count from server entitlements (1 for free male, 999 for paid/female).
/// [adUnlockedCount]  locally tracked count of photos unlocked via ads this session.
/// [isAccepted]       true if the viewer's interest was accepted — bypasses gate on 4th+ photo.
/// [onAdUnlock]       called when ad completes; parent should increment adUnlockedCount.
/// [onUpgradeNeeded]  called when hard paywall should show.
/// [child]            the actual photo widget (blurred underneath overlay).
class GatedPhoto extends StatefulWidget {
  const GatedPhoto({
    super.key,
    required this.photoIndex,
    required this.photosVisibleCount,
    required this.adUnlockedCount,
    required this.isAccepted,
    required this.onAdUnlock,
    required this.onUpgradeNeeded,
    required this.child,
  });

  final int photoIndex;
  final int photosVisibleCount;
  final int adUnlockedCount;
  final bool isAccepted;
  final VoidCallback onAdUnlock;
  final VoidCallback onUpgradeNeeded;
  final Widget child;

  @override
  State<GatedPhoto> createState() => _GatedPhotoState();
}

class _GatedPhotoState extends State<GatedPhoto> {
  bool _isLoadingAd = false;

  // Effective visible count = server baseline + locally ad-unlocked
  int get _effectiveVisible => widget.photosVisibleCount + widget.adUnlockedCount;

  bool get _isVisible => widget.photoIndex < _effectiveVisible;

  // Photos 2 and 3 (index 1, 2) can be unlocked via ads
  bool get _isAdUnlockable =>
      widget.photoIndex >= 1 &&
      widget.photoIndex <= 2 &&
      widget.photosVisibleCount == 1; // only for free male baseline

  // Photos 4+ require premium or acceptance
  bool get _isHardGated =>
      widget.photoIndex >= 3 &&
      widget.photosVisibleCount == 1 &&
      !widget.isAccepted;

  void _loadAndShowAd() async {
    if (_isLoadingAd) return;
    setState(() => _isLoadingAd = true);

    // Use the ad unit appropriate for the platform. Since we can't safely call
    // Theme.of() here without context, derive from defaultTargetPlatform.
    final adUnitId = _platformAdUnitId;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() => _isLoadingAd = false);
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) => a.dispose(),
            onAdFailedToShowFullScreenContent: (a, err) {
              a.dispose();
              _showAdError();
            },
          );
          ad.show(
            onUserEarnedReward: (_, __) {
              widget.onAdUnlock();
            },
          );
        },
        onAdFailedToLoad: (err) {
          setState(() => _isLoadingAd = false);
          _showAdError();
        },
      ),
    );
  }

  String get _platformAdUnitId {
    // Can't use Theme.of(context) here; use defaultTargetPlatform.
    try {
      // ignore: deprecated_member_use
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        return _kRewardedAdUnitIdIos;
      }
    } catch (_) {}
    return _kRewardedAdUnitIdAndroid;
  }

  void _showAdError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not load ad. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isVisible) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred photo underneath
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: widget.child,
        ),
        // Overlay
        if (_isHardGated)
          _PremiumRevealOverlay(onUpgrade: widget.onUpgradeNeeded)
        else if (_isAdUnlockable)
          _AdRevealOverlay(
            photoNumber: widget.photoIndex + 1,
            isLoading: _isLoadingAd,
            onWatchAd: _loadAndShowAd,
          ),
      ],
    );
  }
}

// ── Ad reveal overlay ─────────────────────────────────────────────────────────

class _AdRevealOverlay extends StatelessWidget {
  const _AdRevealOverlay({
    required this.photoNumber,
    required this.isLoading,
    required this.onWatchAd,
  });

  final int photoNumber;
  final bool isLoading;
  final VoidCallback onWatchAd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.3), Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 14),
            Text(
              'Photo $photoNumber of ${photoNumber + 1}',
              style: AppTypography.labelSmall.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Watch a short ad to reveal',
              style: AppTypography.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.ondemand_video_rounded, size: 18),
                    label: const Text('Watch Ad — Free'),
                    onPressed: onWatchAd,
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Premium reveal overlay ────────────────────────────────────────────────────

class PremiumRevealOverlay extends StatelessWidget {
  const PremiumRevealOverlay({super.key, required this.onUpgrade});
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) => _PremiumRevealOverlay(onUpgrade: onUpgrade);
}

class _PremiumRevealOverlay extends StatelessWidget {
  const _PremiumRevealOverlay({required this.onUpgrade});
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gold.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
              ),
              child: const Icon(Icons.lock_rounded, color: AppColors.gold, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'More photos locked',
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Upgrade to Gold to see all photos — or wait for them to accept your interest.',
                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
              label: const Text('Upgrade to Gold'),
              onPressed: onUpgrade,
            ),
          ],
        ),
      ),
    );
  }
}
