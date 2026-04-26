import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../ads/ad_budget_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'gate_decision_sheet.dart';

/// Shows a beautifully branded Premium gate dialog.
///
/// Returns [GateDecision.upgrade], [GateDecision.watchAd], or [GateDecision.notNow].
/// Returns null if dismissed via barrier tap.
Future<GateDecision?> showPremiumGateDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool canWatchAd = true,
  String? watchAdLabel,
  String? adActionType,
  int? adsRemaining,
}) {
  return showDialog<GateDecision>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (ctx) => _PremiumGateDialogContent(
      title: title,
      message: message,
      canWatchAd: canWatchAd,
      watchAdLabel: watchAdLabel,
      adActionType: adActionType,
      adsRemainingOverride: adsRemaining,
    ),
  );
}

class _PremiumGateDialogContent extends ConsumerWidget {
  const _PremiumGateDialogContent({
    required this.title,
    required this.message,
    required this.canWatchAd,
    this.watchAdLabel,
    this.adActionType,
    this.adsRemainingOverride,
  });

  final String title;
  final String message;
  final bool canWatchAd;
  final String? watchAdLabel;
  final String? adActionType;
  final int? adsRemainingOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    final budgetAsync = ref.watch(adBudgetProvider);
    final map = budgetAsync.valueOrNull;
    final limit = map?.limitPerAction ?? 3;
    final remaining = adsRemainingOverride ??
        (adActionType != null ? map?.forType(adActionType!).remaining : null) ??
        limit;
    final budgetExhausted = remaining <= 0;
    final showAdOption = canWatchAd && !budgetExhausted;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gradient header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.goldLight, AppColors.gold, AppColors.saffron],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.72),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),

                  // Gold gradient upgrade button
                  _PremiumGradientButton(
                    label: l.ctaUpgradeToPremium,
                    icon: Icons.star_rounded,
                    onPressed: () =>
                        Navigator.of(context).pop(GateDecision.upgrade),
                  ),

                  if (showAdOption) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.rosePrimary,
                          width: 1.5,
                        ),
                        foregroundColor: AppColors.rosePrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.play_circle_outline_rounded,
                        size: 20,
                      ),
                      label: Text(watchAdLabel ?? l.watchAdToUnlock),
                      onPressed: () =>
                          Navigator.of(context).pop(GateDecision.watchAd),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$remaining of $limit free unlocks left today',
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (canWatchAd && budgetExhausted) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Daily ad limit reached. Upgrade or try again tomorrow.',
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(GateDecision.notNow),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: Text(l.notNow),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold-to-saffron gradient button used as the primary upgrade CTA.
class _PremiumGradientButton extends StatefulWidget {
  const _PremiumGradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_PremiumGradientButton> createState() => _PremiumGradientButtonState();
}

class _PremiumGradientButtonState extends State<_PremiumGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _ctrl.reverse();
    await _ctrl.forward();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.scale(scale: _ctrl.value, child: child),
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.goldLight, AppColors.gold, AppColors.saffron],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.42),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
