import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Result of initiating a subscription/IAP purchase.
class IapPurchaseResult {
  const IapPurchaseResult._({this.verificationData, this.planId, this.error});
  final String? verificationData;
  final String? planId;
  final String? error;

  bool get isSuccess => verificationData != null && verificationData!.isNotEmpty;
  factory IapPurchaseResult.success(String verificationData, String planId) =>
      IapPurchaseResult._(verificationData: verificationData, planId: planId);
  factory IapPurchaseResult.failure(String error) =>
      IapPurchaseResult._(error: error);
}

/// Result of restore: platform + receipt/token to send to backend.
class IapRestoreResult {
  const IapRestoreResult({this.platform, this.receiptOrToken, this.error});
  final String? platform;
  final String? receiptOrToken;
  final String? error;

  bool get hasReceipt =>
      platform != null &&
      receiptOrToken != null &&
      receiptOrToken!.isNotEmpty;
}

/// Runs the store purchase flow and returns verification data for the backend.
/// Call [SubscriptionRepository.purchaseSubscription] with the returned data.
Future<IapPurchaseResult> runIapPurchase({
  required Map<String, ProductDetails> products,
  required String productId,
}) async {
  if (!Platform.isIOS && !Platform.isAndroid) {
    return IapPurchaseResult.failure('Store not available on this platform');
  }
  final product = products[productId];
  if (product == null) {
    return IapPurchaseResult.failure('Product not found: $productId');
  }
  final iap = InAppPurchase.instance;
  final available = await iap.isAvailable();
  if (!available) {
    return IapPurchaseResult.failure('Store not available');
  }

  final purchaseParam = PurchaseParam(productDetails: product);
  late StreamSubscription<List<PurchaseDetails>> subscription;
  final completer = Completer<IapPurchaseResult>();

  subscription = iap.purchaseStream.listen(
    (purchases) {
      for (final p in purchases) {
        if (p.productID != productId) continue;
        if (p.status == PurchaseStatus.purchased) {
          subscription.cancel();
          final data = p.verificationData.serverVerificationData;
          final raw = data.isNotEmpty ? data : p.verificationData.localVerificationData;
          if (raw.isNotEmpty) {
            iap.completePurchase(p);
            if (!completer.isCompleted) {
              completer.complete(IapPurchaseResult.success(raw, productId));
            }
          } else if (!completer.isCompleted) {
            completer.complete(IapPurchaseResult.failure('No verification data'));
          }
          return;
        }
        if (p.status == PurchaseStatus.error) {
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.complete(IapPurchaseResult.failure(
                p.error?.message ?? 'Purchase failed'));
          }
          return;
        }
        if (p.status == PurchaseStatus.canceled) {
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.complete(IapPurchaseResult.failure('Purchase canceled'));
          }
          return;
        }
      }
    },
    onError: (e) {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(IapPurchaseResult.failure(e.toString()));
      }
    },
  );

  final success = await iap.buyNonConsumable(purchaseParam: purchaseParam);
  if (!success) {
    subscription.cancel();
    return IapPurchaseResult.failure('Could not start purchase');
  }

  return completer.future.timeout(
    const Duration(seconds: 120),
    onTimeout: () {
      subscription.cancel();
      return IapPurchaseResult.failure('Purchase timed out');
    },
  );
}

/// Restores purchases from the store and returns receipt/token for the backend.
Future<IapRestoreResult> runIapRestore() async {
  if (!Platform.isIOS && !Platform.isAndroid) {
    return const IapRestoreResult(error: 'Store not available');
  }
  final iap = InAppPurchase.instance;
  final available = await iap.isAvailable();
  if (!available) {
    return const IapRestoreResult(error: 'Store not available');
  }

  String? receiptOrToken;
  final completer = Completer<IapRestoreResult>();
  final platform = Platform.isIOS ? 'ios' : 'android';

  final subscription = iap.purchaseStream.listen(
    (purchases) {
      for (final p in purchases) {
        if (p.status != PurchaseStatus.restored &&
            p.status != PurchaseStatus.purchased) continue;
        final data = p.verificationData.serverVerificationData;
        final local = p.verificationData.localVerificationData;
        final raw = data.isNotEmpty ? data : local;
        if (raw.isNotEmpty) {
          receiptOrToken = raw;
          if (!completer.isCompleted) {
            completer.complete(IapRestoreResult(
                platform: platform, receiptOrToken: receiptOrToken));
          }
          return;
        }
      }
    },
    onError: (e) {
      if (!completer.isCompleted) {
        completer.complete(IapRestoreResult(error: e.toString()));
      }
    },
  );

  await iap.restorePurchases();
  try {
    return await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => IapRestoreResult(
        platform: platform,
        receiptOrToken: receiptOrToken ?? '',
        error: receiptOrToken == null ? 'No purchases to restore' : null,
      ),
    );
  } finally {
    subscription.cancel();
  }
}
