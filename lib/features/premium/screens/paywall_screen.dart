import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/entitlements/entitlements.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/iap_products_provider.dart';
import '../services/iap_purchase_service.dart';

// ── Hard-coded copy extracted as constants ─────────────────────────────────
const _kPaywallTitle = 'Unlock more with Shubhmilan';
const _kPaywallFemaleAccess =
    'You already have free access to messaging, seeing likes, and contact requests.';
const _kPaywallBoostNote = 'Profile boost available separately';
const _kManageSubscriptionLabel = 'Manage subscription';
const _kAllPlansInclude = 'All plans include:';

/// Selected subscription plan for purchase.
enum PremiumPlan { monthly, quarterly, annual }

extension PremiumPlanX on PremiumPlan {
  String get productId {
    switch (this) {
      case PremiumPlan.monthly:
        return IapProductIds.premiumMonthly;
      case PremiumPlan.quarterly:
        return IapProductIds.premiumQuarterly;
      case PremiumPlan.annual:
        return IapProductIds.premiumAnnual;
    }
  }
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PremiumPlan _selectedPlan = PremiumPlan.annual;
  bool _hasLoggedPaywallView = false;

  Future<void> _onSubscribe(BuildContext context, WidgetRef ref) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final products = await ref.read(iapProductsProvider.future);
    final productId = _selectedPlan.productId;
    try {
      AnalyticsService.instance.log(AnalyticsEvent.paywallSubscribeStarted, {
        'plan': productId,
      });
      if (products.isEmpty || !products.containsKey(productId)) {
        if (!context.mounted) return;
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.purchaseFailed('Store not available. Try again later.')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final result = await runIapPurchase(
        products: products,
        productId: productId,
      );
      if (!result.isSuccess || result.verificationData == null) {
        if (!context.mounted) return;
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.purchaseFailed(result.error ?? 'Purchase failed')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      await ref.read(subscriptionRepositoryProvider).purchaseSubscription(
        platform: platform,
        receiptOrToken: result.verificationData!,
        planId: productId,
      );
      ref.read(subscriptionAccessRefreshProvider)();
      AnalyticsService.instance.log(
        AnalyticsEvent.paywallSubscribeSucceeded,
        {'plan': productId},
      );
      if (context.mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.subscriptionActivated),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      AnalyticsService.instance.log(
        AnalyticsEvent.paywallSubscribeFailed,
        {'plan': productId, 'error_code': e.code},
      );
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.purchaseFailed(e.message)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      AnalyticsService.instance.log(
        AnalyticsEvent.paywallSubscribeFailed,
        {'plan': productId, 'error_code': 'UNKNOWN'},
      );
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.purchaseFailed(e is Exception ? e.toString() : 'Unknown error'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onRestore(BuildContext context, WidgetRef ref) async {
    try {
      final restoreResult = await runIapRestore();
      final restored = await ref.read(subscriptionRepositoryProvider).restorePurchases(
        platform: restoreResult.platform,
        receiptOrToken: restoreResult.receiptOrToken,
      );
      ref.read(subscriptionAccessRefreshProvider)();
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      if (restored) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.purchasesRestored),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restoreResult.error ?? l.noActivePurchases,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.couldNotRestorePurchases),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final ent = ref.watch(entitlementsProvider);
    final productsAsync = ref.watch(iapProductsProvider);

    final products = productsAsync.valueOrNull ?? {};
    final monthlyPrice = products[IapProductIds.premiumMonthly]?.price ?? '\$20.99';
    final quarterlyPrice = products[IapProductIds.premiumQuarterly]?.price ?? '\$44.97';
    final annualPrice = products[IapProductIds.premiumAnnual]?.price ?? '\$120';

    final maleFeatures = [
      'Send messages & intros',
      'See who likes you',
      'Request contact details',
      'Unlimited express interests',
      'Travel mode: explore other cities',
      'Priority in discovery',
      'Read receipts',
      'View compatibility breakdown',
    ];

    final femaleFeatures = [
      'Unlimited messaging',
      'Travel mode: explore other cities',
      'Profile boost',
      'Priority in discovery',
      'Read receipts',
    ];

    final features = ent.isFemale ? femaleFeatures : maleFeatures;
    final hasActiveSubscription = ref.watch(subscriptionStateProvider).valueOrNull?.isActive ?? false;
    if (!_hasLoggedPaywallView) {
      _hasLoggedPaywallView = true;
      AnalyticsService.instance.log(
        AnalyticsEvent.paywallViewed,
        {
          'is_female': ent.isFemale,
          'has_active_subscription': hasActiveSubscription,
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Radial glow hero
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1.0),
                duration: AppMotion.loop,
                curve: Curves.easeInOut,
                builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.45),
                        AppColors.saffron.withValues(alpha: 0.18),
                        AppColors.saffron.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gold, AppColors.saffron],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: AppTokens.shadowGlow(AppColors.gold, intensity: 0.4),
                      ),
                      child: const Icon(Icons.workspace_premium, size: 40, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: AppMotion.enter).scale(begin: const Offset(0.8, 0.8), curve: AppMotion.reveal),
            const SizedBox(height: 20),
            Text(
              _kPaywallTitle,
              style: AppTypography.displaySmall,
              textAlign: TextAlign.center,
            ).animate().fadeIn().slideY(begin: -0.05, end: 0),
            const SizedBox(height: 8),
            Text(
              ent.upgradeReason,
              style: AppTypography.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 80.ms),

            if (ent.isFemale) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _kPaywallFemaleAccess,
                        style: AppTypography.bodySmall.copyWith(
                          color: secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            _SubscriptionPlanTile(
              title: 'Monthly',
              price: monthlyPrice,
              period: '/month',
              savings: null,
              isSelected: _selectedPlan == PremiumPlan.monthly,
              accent: accent,
              onTap: () {
                setState(() => _selectedPlan = PremiumPlan.monthly);
                AnalyticsService.instance.log(
                  AnalyticsEvent.paywallPlanSelected,
                  {'plan': PremiumPlan.monthly.productId},
                );
              },
            ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.03, end: 0),
            const SizedBox(height: 8),
            _SubscriptionPlanTile(
              title: 'Quarterly',
              price: quarterlyPrice,
              period: '/3 months',
              savings: 'Save 29%',
              isSelected: _selectedPlan == PremiumPlan.quarterly,
              accent: accent,
              onTap: () {
                setState(() => _selectedPlan = PremiumPlan.quarterly);
                AnalyticsService.instance.log(
                  AnalyticsEvent.paywallPlanSelected,
                  {'plan': PremiumPlan.quarterly.productId},
                );
              },
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.03, end: 0),
            const SizedBox(height: 8),
            _SubscriptionPlanTile(
              title: 'Annual',
              price: annualPrice,
              period: '/year',
              savings: 'Best value',
              isSelected: _selectedPlan == PremiumPlan.annual,
              accent: accent,
              onTap: () {
                setState(() => _selectedPlan = PremiumPlan.annual);
                AnalyticsService.instance.log(
                  AnalyticsEvent.paywallPlanSelected,
                  {'plan': PremiumPlan.annual.productId},
                );
              },
            ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.03, end: 0),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _kAllPlansInclude,
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...features.take(5).indexed.map(
                    (entry) {
                      final (idx, f) = entry;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 18, color: accent),
                            const SizedBox(width: 8),
                            Expanded(child: Text(f, style: AppTypography.bodySmall)),
                          ],
                        ),
                      ).animate(delay: AppMotion.stagger(idx, stepMs: 60) + 210.ms).fadeIn(duration: AppMotion.medium).slideX(begin: 0.08, curve: AppMotion.spring);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Gradient CTA button with scale pulse on tap
            _GradientCtaButton(
              label: l.subscribe,
              onPressed: () => _onSubscribe(context, ref),
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.04, curve: AppMotion.spring),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _onRestore(context, ref),
              child: Text(l.restorePurchases),
            ),
            if (hasActiveSubscription && Platform.isAndroid) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _openManageSubscription(),
                child: const Text(_kManageSubscriptionLabel),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              _kPaywallBoostNote,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _openManageSubscription() async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions?package=com.dvtechventures.shubhmilan',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Full-width gradient CTA button with scale-pulse on tap.
class _GradientCtaButton extends StatefulWidget {
  const _GradientCtaButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  State<_GradientCtaButton> createState() => _GradientCtaButtonState();
}

class _GradientCtaButtonState extends State<_GradientCtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.micro, lowerBound: 0.95, upperBound: 1.0);
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.saffron, AppColors.gold, AppColors.saffronDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTokens.shadowGlow(AppColors.saffron, intensity: 0.35),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionPlanTile extends StatelessWidget {
  const _SubscriptionPlanTile({
    required this.title,
    required this.price,
    required this.period,
    required this.savings,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });
  final String title;
  final String price;
  final String period;
  final String? savings;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: isSelected ? 1.02 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.reveal,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accent : cs.onSurface.withValues(alpha: 0.12),
              width: isSelected ? 2 : 1,
            ),
            gradient: isSelected ? LinearGradient(
              colors: [accent.withValues(alpha: 0.12), AppColors.gold.withValues(alpha: 0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            boxShadow: isSelected ? AppTokens.shadowGlow(accent, intensity: 0.18) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? accent : cs.onSurface.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  gradient: isSelected ? LinearGradient(
                    colors: [accent, AppColors.gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ) : null,
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (savings != null && savings!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              savings!,
                              style: AppTypography.labelSmall.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$price$period',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: AppTypography.titleMedium.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
