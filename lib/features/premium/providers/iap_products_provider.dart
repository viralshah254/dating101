import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Product IDs must match exactly what you create in:
/// - **iOS:** App Store Connect → Your App → In-App Purchases
/// - **Android:** Google Play Console → Your App → Monetize → Products
///
/// Prices and currency are set in the store consoles (per territory).
/// The app fetches them at runtime and displays the store's localized price.
class IapProductIds {
  IapProductIds._();

  // ── Legacy / gender-neutral IDs (kept for backward compatibility) ──────────

  /// Premium subscription — monthly. Create as auto-renewable subscription.
  static const String premiumMonthly = 'premium_monthly';

  /// Premium subscription — quarterly (3 months). Create as auto-renewable subscription.
  static const String premiumQuarterly = 'premium_quarterly';

  /// Premium subscription — annual (12 months). Create as auto-renewable subscription.
  static const String premiumAnnual = 'premium_annual';

  // Silver tier — entry level paid
  static const String silverMonthly = 'silver_monthly';
  static const String silverQuarterly = 'silver_quarterly';
  static const String silverAnnual = 'silver_annual';

  // Gold tier — mid tier
  static const String goldMonthly = 'gold_monthly';
  static const String goldQuarterly = 'gold_quarterly';
  static const String goldAnnual = 'gold_annual';

  // Platinum tier — top tier
  static const String platinumMonthly = 'platinum_monthly';
  static const String platinumQuarterly = 'platinum_quarterly';
  static const String platinumAnnual = 'platinum_annual';

  // ── Gender-prefixed IDs — males pay full price, females ~40-50% discount ──
  // Prices are set per country in App Store Connect / Play Console.

  // Male — Silver
  static const String maleSilverMonthly = 'male_silver_monthly';
  static const String maleSilverQuarterly = 'male_silver_quarterly';
  static const String maleSilverAnnual = 'male_silver_annual';

  // Male — Gold
  static const String maleGoldMonthly = 'male_gold_monthly';
  static const String maleGoldQuarterly = 'male_gold_quarterly';
  static const String maleGoldAnnual = 'male_gold_annual';

  // Male — Platinum
  static const String malePlatinumMonthly = 'male_platinum_monthly';
  static const String malePlatinumQuarterly = 'male_platinum_quarterly';
  static const String malePlatinumAnnual = 'male_platinum_annual';

  // Female — Silver
  static const String femaleSilverMonthly = 'female_silver_monthly';
  static const String femaleSilverQuarterly = 'female_silver_quarterly';
  static const String femaleSilverAnnual = 'female_silver_annual';

  // Female — Gold
  static const String femaleGoldMonthly = 'female_gold_monthly';
  static const String femaleGoldQuarterly = 'female_gold_quarterly';
  static const String femaleGoldAnnual = 'female_gold_annual';

  // Female — Platinum
  static const String femalePlatinumMonthly = 'female_platinum_monthly';
  static const String femalePlatinumQuarterly = 'female_platinum_quarterly';
  static const String femalePlatinumAnnual = 'female_platinum_annual';

  /// One-time profile boost. Create as one-time product / consumable.
  static const String boostOneTime = 'boost_one_time';

  static const Set<String> subscriptionIds = {
    // Legacy IDs
    premiumMonthly, premiumQuarterly, premiumAnnual,
    silverMonthly, silverQuarterly, silverAnnual,
    goldMonthly, goldQuarterly, goldAnnual,
    platinumMonthly, platinumQuarterly, platinumAnnual,
    // Gender-prefixed IDs
    maleSilverMonthly, maleSilverQuarterly, maleSilverAnnual,
    maleGoldMonthly, maleGoldQuarterly, maleGoldAnnual,
    malePlatinumMonthly, malePlatinumQuarterly, malePlatinumAnnual,
    femaleSilverMonthly, femaleSilverQuarterly, femaleSilverAnnual,
    femaleGoldMonthly, femaleGoldQuarterly, femaleGoldAnnual,
    femalePlatinumMonthly, femalePlatinumQuarterly, femalePlatinumAnnual,
  };

  static const Set<String> all = {...subscriptionIds, boostOneTime};

  /// Returns the product ID for [tier] and [period]. [isFemale] true → `female_*`;
  /// all other genders (male, non-binary, unknown) should pass false → `male_*`.
  static String forTier(String tier, String period, {required bool isFemale}) {
    final prefix = isFemale ? 'female' : 'male';
    switch (tier) {
      case 'silver':
        switch (period) {
          case 'quarterly':
            return '${prefix}_silver_quarterly';
          case 'annual':
            return '${prefix}_silver_annual';
          default:
            return '${prefix}_silver_monthly';
        }
      case 'gold':
        switch (period) {
          case 'quarterly':
            return '${prefix}_gold_quarterly';
          case 'annual':
            return '${prefix}_gold_annual';
          default:
            return '${prefix}_gold_monthly';
        }
      case 'platinum':
        switch (period) {
          case 'quarterly':
            return '${prefix}_platinum_quarterly';
          case 'annual':
            return '${prefix}_platinum_annual';
          default:
            return '${prefix}_platinum_monthly';
        }
      default:
        return '${prefix}_gold_monthly';
    }
  }
}

/// Fetches product details (price, title) from the store.
/// Returns a map of productId -> ProductDetails. Empty or partial if store
/// isn't available (e.g. simulator, products not yet in console).
final iapProductsProvider = FutureProvider<Map<String, ProductDetails>>((ref) async {
  if (!Platform.isIOS && !Platform.isAndroid) {
    return {};
  }
  final iap = InAppPurchase.instance;
  var available = await iap.isAvailable();
  if (!available) {
    // Billing can report unavailable briefly after cold start; retry once.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    available = await iap.isAvailable();
  }
  if (!available) {
    if (kDebugMode) {
      debugPrint(
        '[IAP] Store not available — prices will show as dashes. '
        'Use a real device; iOS Simulator needs StoreKit config or device.',
      );
    }
    return {};
  }
  Future<ProductDetailsResponse> query() =>
      iap.queryProductDetails(IapProductIds.all);

  var response = await query();
  if (response.productDetails.isEmpty && response.error == null) {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    response = await query();
  }
  if (response.error != null && kDebugMode) {
    debugPrint('[IAP] queryProductDetails error: ${response.error}');
  }
  if (response.notFoundIDs.isNotEmpty && kDebugMode) {
    debugPrint('[IAP] Products not found in store: ${response.notFoundIDs}');
  }
  return Map.fromEntries(
    response.productDetails.map((p) => MapEntry(p.id, p)),
  );
});
