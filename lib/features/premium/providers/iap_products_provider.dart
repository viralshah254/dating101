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

  /// Premium subscription (recurring). Create as auto-renewable subscription.
  static const String premiumMonthly = 'premium_monthly';

  /// One-time profile boost. Create as one-time product / consumable.
  static const String boostOneTime = 'boost_one_time';

  static const Set<String> all = {premiumMonthly, boostOneTime};
}

/// Fetches product details (price, title) from the store.
/// Returns a map of productId -> ProductDetails. Empty or partial if store
/// isn't available (e.g. simulator, products not yet in console).
final iapProductsProvider = FutureProvider<Map<String, ProductDetails>>((ref) async {
  if (!Platform.isIOS && !Platform.isAndroid) {
    return {};
  }
  final iap = InAppPurchase.instance;
  final available = await iap.isAvailable();
  if (!available) {
    if (kDebugMode) {
      debugPrint('[IAP] Store not available (e.g. simulator or not signed in)');
    }
    return {};
  }
  final response = await iap.queryProductDetails(IapProductIds.all);
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
