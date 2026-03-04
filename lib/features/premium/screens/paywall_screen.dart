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

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  Future<void> _onSubscribe(BuildContext context, WidgetRef ref) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final products = await ref.read(iapProductsProvider.future);
    try {
      String receiptOrToken = 'placeholder_receipt';
      if (products.isNotEmpty && products.containsKey(IapProductIds.premiumMonthly)) {
        final result = await runIapPurchase(
          products: products,
          productId: IapProductIds.premiumMonthly,
        );
        if (result.isSuccess && result.verificationData != null) {
          receiptOrToken = result.verificationData!;
        } else if (result.error != null) {
          if (!context.mounted) return;
          final l = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.purchaseFailed(result.error!)),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
      await ref.read(subscriptionRepositoryProvider).purchaseSubscription(
        platform: platform,
        receiptOrToken: receiptOrToken,
        planId: IapProductIds.premiumMonthly,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
    final ent = ref.watch(entitlementsProvider);
    final productsAsync = ref.watch(iapProductsProvider);

    // Prices from store (Google Play / App Store); fallback when not loaded or not in console
    final premiumProduct = productsAsync.valueOrNull?[IapProductIds.premiumMonthly];
    final boostProduct = productsAsync.valueOrNull?[IapProductIds.boostOneTime];
    final premiumPrice = premiumProduct?.price ?? '£9.99';
    final boostPrice = boostProduct?.price ?? '£4.99';

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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
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
            _PlanCard(
              title: l.premium,
              price: premiumPrice,
              period: '/month',
              features: features,
              accent: accent,
              isPopular: true,
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.03, end: 0),
            const SizedBox(height: 12),
            _PlanCard(
              title: l.boostPack,
              price: boostPrice,
              period: ' one-time',
              features: const [
                '1 profile boost (24h)',
                'Stand out in discovery',
              ],
              accent: accent,
              isPopular: false,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.03, end: 0),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.accent,
    required this.isPopular,
  });
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final Color accent;
  final bool isPopular;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isPopular ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular ? BorderSide(color: accent, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Most popular',
                  style: AppTypography.labelSmall.copyWith(color: accent),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(title, style: AppTypography.titleLarge),
                const SizedBox(width: 12),
                Text(
                  price,
                  style: AppTypography.headlineSmall.copyWith(color: accent),
                ),
                Text(period, style: AppTypography.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: accent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: AppTypography.bodySmall)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
