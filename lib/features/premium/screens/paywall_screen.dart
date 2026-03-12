import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/entitlements/entitlements.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/iap_products_provider.dart';
import '../services/iap_purchase_service.dart';

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

  Future<void> _onSubscribe(BuildContext context, WidgetRef ref) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final products = await ref.read(iapProductsProvider.future);
    final productId = _selectedPlan.productId;
    try {
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
      ref.invalidate(entitlementsProvider);
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
    } catch (e) {
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
      ref.invalidate(entitlementsProvider);
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.saffron.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 48,
                color: AppColors.saffron,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock more with Shubhmilan',
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
                  color: AppColors.indiaGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.indiaGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: AppColors.indiaGreen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You already have free access to messaging, seeing likes, and contact requests.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.indiaGreen,
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
              onTap: () => setState(() => _selectedPlan = PremiumPlan.monthly),
            ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.03, end: 0),
            const SizedBox(height: 8),
            _SubscriptionPlanTile(
              title: 'Quarterly',
              price: quarterlyPrice,
              period: '/3 months',
              savings: 'Save 29%',
              isSelected: _selectedPlan == PremiumPlan.quarterly,
              accent: accent,
              onTap: () => setState(() => _selectedPlan = PremiumPlan.quarterly),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.03, end: 0),
            const SizedBox(height: 8),
            _SubscriptionPlanTile(
              title: 'Annual',
              price: annualPrice,
              period: '/year',
              savings: 'Best value',
              isSelected: _selectedPlan == PremiumPlan.annual,
              accent: accent,
              onTap: () => setState(() => _selectedPlan = PremiumPlan.annual),
            ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.03, end: 0),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All plans include:',
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...features.take(5).map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 18, color: accent),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f, style: AppTypography.bodySmall)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 210.ms),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _onSubscribe(context, ref),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l.subscribe),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _onRestore(context, ref),
              child: Text(l.restorePurchases),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile boost available separately',
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? accent.withValues(alpha: 0.06) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  color: isSelected ? accent : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
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
    );
  }
}
