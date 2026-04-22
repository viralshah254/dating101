import 'dart:io';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/entitlements/entitlements.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
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
/// Selected billing period for purchase.
enum PremiumPlan { monthly, quarterly, annual }

/// Selected tier for purchase.
enum PaywallTier { silver, gold, platinum }

extension PaywallTierX on PaywallTier {
  String get label {
    switch (this) {
      case PaywallTier.silver:
        return 'Silver';
      case PaywallTier.gold:
        return 'Gold';
      case PaywallTier.platinum:
        return 'Platinum';
    }
  }

  String get prefix {
    switch (this) {
      case PaywallTier.silver:
        return 'silver';
      case PaywallTier.gold:
        return 'gold';
      case PaywallTier.platinum:
        return 'platinum';
    }
  }
}

extension PremiumPlanX on PremiumPlan {
  /// Returns the gender-prefixed product ID (male_* or female_*).
  /// Falls back to gender-neutral if [isFemale] is not yet known.
  String productIdForTier(PaywallTier tier, {bool isFemale = false}) {
    final genderPrefix = isFemale ? 'female' : 'male';
    final tierPrefix = tier.prefix;
    switch (this) {
      case PremiumPlan.monthly:
        return '${genderPrefix}_${tierPrefix}_monthly';
      case PremiumPlan.quarterly:
        return '${genderPrefix}_${tierPrefix}_quarterly';
      case PremiumPlan.annual:
        return '${genderPrefix}_${tierPrefix}_annual';
    }
  }

  /// Gender-neutral SKU (`gold_monthly`, etc.) — use when only neutral IDs exist in the store.
  String neutralProductId(PaywallTier tier) {
    final suffix = switch (this) {
      PremiumPlan.monthly => 'monthly',
      PremiumPlan.quarterly => 'quarterly',
      PremiumPlan.annual => 'annual',
    };
    return '${tier.prefix}_$suffix';
  }

  // Legacy: defaults to gold tier (matches old "premium" behaviour)
  String get productId => productIdForTier(PaywallTier.gold);
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PremiumPlan _selectedPlan = PremiumPlan.annual;
  PaywallTier _selectedTier = PaywallTier.gold;
  bool _hasLoggedPaywallView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(iapProductsProvider);
    });
  }

  Future<void> _onSubscribe(BuildContext context, WidgetRef ref) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final products = await ref.read(iapProductsProvider.future);
    final ent = ref.read(entitlementsProvider);
    // Use gender-prefixed product IDs so stores serve the correct regional price.
    // Then try the other gender prefix, then gender-neutral SKUs (gold_monthly, …).
    String productId = _selectedPlan.productIdForTier(_selectedTier, isFemale: ent.isFemale);
    if (!products.containsKey(productId)) {
      final otherGender = _selectedPlan.productIdForTier(_selectedTier, isFemale: !ent.isFemale);
      if (products.containsKey(otherGender)) {
        productId = otherGender;
      }
    }
    if (!products.containsKey(productId)) {
      final neutralId = _selectedPlan.neutralProductId(_selectedTier);
      if (products.containsKey(neutralId)) productId = neutralId;
    }
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
    // Resolve prices: gendered SKU → other gender → gender-neutral (gold_monthly, …).
    String tierPrice(PaywallTier tier, PremiumPlan plan) {
      final genderedId = plan.productIdForTier(tier, isFemale: ent.isFemale);
      final otherGenderId = plan.productIdForTier(tier, isFemale: !ent.isFemale);
      final neutralId = plan.neutralProductId(tier);
      return products[genderedId]?.price ??
          products[otherGenderId]?.price ??
          products[neutralId]?.price ??
          '—';
    }

    final monthlyPrice = tierPrice(_selectedTier, PremiumPlan.monthly);
    final quarterlyPrice = tierPrice(_selectedTier, PremiumPlan.quarterly);
    final annualPrice = tierPrice(_selectedTier, PremiumPlan.annual);

    final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
    final isDating = mode == AppMode.dating;

    // ── Tier-keyed feature copy (max 5 bullets, mode-aware) ──────────────────
    const maleMatrimony = {
      PaywallTier.silver: [
        'Send messages directly — no requests',
        'All photos visible — no blur, no ads',
        'See who viewed your profile',
        'Read receipts · Compatibility score',
        '25 daily express interests',
      ],
      PaywallTier.gold: [
        'Everything in Silver',
        'See who liked & shortlisted your profile',
        'Request contact details directly',
        'Travel mode · Priority in discovery',
        'AI profile review · 10 priority interests/day',
      ],
    };

    const maleDating = {
      PaywallTier.silver: [
        'Send messages directly to your matches',
        'All photos visible instantly',
        'See who viewed your profile',
        'Read receipts · Compatibility insights',
        '25 daily likes',
      ],
      PaywallTier.gold: [
        'Everything in Silver',
        'See everyone who liked your profile',
        'Travel mode · Priority in the feed',
        'AI-powered match insights',
        '10 priority likes per day · Profile boost (add-on)',
      ],
    };

    const femaleMatrimony = {
      PaywallTier.silver: [
        'Unlimited messaging — no request needed',
        'All photos visible — no blur',
        'Read receipts · Compatibility score',
        '25 daily express interests',
        'No ads to view interest requests',
      ],
      PaywallTier.gold: [
        'Everything in Silver',
        'See who liked your profile',
        'Travel mode · Priority in discovery',
        'AI profile review',
        'Profile boost (add-on) · 10 priority interests/day',
      ],
    };

    const femaleDating = {
      PaywallTier.silver: [
        'Unlimited messaging — no request needed',
        'All photos visible — no blur',
        'Read receipts · Compatibility insights',
        '25 daily likes',
        'No ads to view match requests',
      ],
      PaywallTier.gold: [
        'Everything in Silver',
        'See who liked your profile',
        'Travel mode · Priority in the feed',
        'AI-powered match insights',
        'Profile boost (add-on) · 10 priority likes/day',
      ],
    };

    final tierFeatures = ent.isFemale
        ? (isDating ? femaleDating : femaleMatrimony)
        : (isDating ? maleDating : maleMatrimony);
    final features = tierFeatures[_selectedTier] ?? [];
    final hasActiveSubscription = ref.watch(subscriptionStateProvider).valueOrNull?.isActive ?? false;
    final showStoreHint = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android) &&
        productsAsync.hasValue &&
        products.isEmpty;
    final loadingPrices = productsAsync.isLoading;

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

            // Female discount badge
            if (ent.isFemale) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.rosePrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.female_rounded, size: 16, color: AppColors.rosePrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Women get up to 50% off — exclusive pricing',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.rosePrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (loadingPrices) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l.loading,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
            if (showStoreHint) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.paywallStorePricesHint,
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            // ── Tier Selector ───────────────────────────────────────────────
            _TierSelector(
              selected: _selectedTier,
              onSelect: (t) => setState(() => _selectedTier = t),
            ),
            const SizedBox(height: 12),
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
                    '${_selectedTier.label} includes:',
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...features.indexed.map(
                    (entry) {
                      final (idx, f) = entry;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(Icons.check_circle, size: 18, color: accent),
                            ),
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
    // Use ColorScheme, not AppTypography static colors — they track a global dark
    // flag and can mismatch Theme brightness (e.g. near-white text on light cards).
    final titleColor = isSelected ? cs.primary : cs.onSurface;
    final priceLineColor = cs.onSurface.withValues(alpha: 0.68);
    final trailingPriceColor = isSelected ? accent : cs.onSurface.withValues(alpha: 0.9);

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
                            color: titleColor,
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
                        color: priceLineColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: AppTypography.titleMedium.copyWith(
                  color: trailingPriceColor,
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

// ── Tier Selector Widget ──────────────────────────────────────────────────────

class _TierSelector extends StatelessWidget {
  const _TierSelector({required this.selected, required this.onSelect});
  final PaywallTier selected;
  final void Function(PaywallTier) onSelect;

  static const _tierColors = {
    PaywallTier.silver: Color(0xFF607D8B),
    PaywallTier.gold: Color(0xFFF9A825),
    PaywallTier.platinum: Color(0xFF6A1B9A),
  };

  static const _tierBenefits = {
    PaywallTier.silver: 'Messages · Photos · Visitors · Read receipts',
    PaywallTier.gold: 'Silver + Who liked you · Travel · Priority · AI Review',
  };

  static const _tierBadge = {
    PaywallTier.gold: 'Best Value',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your plan',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [PaywallTier.silver, PaywallTier.gold].map((tier) {
            final isSelected = tier == selected;
            final color = _tierColors[tier]!;
            final badge = _tierBadge[tier];
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(tier),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : color.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge strip (only for Gold / Platinum)
                      if (badge != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : color.withValues(alpha: 0.18),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          ),
                          child: Text(
                            badge,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Text(
                              tier.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : color,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 3),
                              Icon(Icons.check_circle_rounded, size: 14, color: Colors.white.withValues(alpha: 0.9)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_tierBenefits[selected] != null) ...[
          const SizedBox(height: 8),
          Text(
            _tierBenefits[selected]!,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.55),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
