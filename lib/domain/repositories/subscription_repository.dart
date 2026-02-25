/// Subscription tier (for paywall).
enum SubscriptionTier { none, premium }

/// Current subscription state.
class SubscriptionState {
  const SubscriptionState({
    this.tier = SubscriptionTier.none,
    this.expiresAt,
    this.isActive = false,
  });
  final SubscriptionTier tier;
  final DateTime? expiresAt;
  final bool isActive;
}

/// Feature flags from GET /subscription/entitlements (tier + gender).
class SubscriptionEntitlements {
  const SubscriptionEntitlements({
    this.canSendMessage = false,
    this.canSeeWhoLikedYou = false,
    this.canSeeWhoShortlistedYou = false,
    this.dailyInterestLimit = 5,
    this.dailyMessageLimit = 0,
    this.hasPriorityDiscovery = false,
    this.canSuperlike = false,
    this.raw = const {},
  });
  final bool canSendMessage;
  final bool canSeeWhoLikedYou;
  final bool canSeeWhoShortlistedYou;
  final int dailyInterestLimit;
  final int dailyMessageLimit;
  final bool hasPriorityDiscovery;
  final bool canSuperlike;
  final Map<String, dynamic> raw;
}

/// Premium / subscription state (for paywall, feature gating).
abstract class SubscriptionRepository {
  Stream<SubscriptionState> watchSubscriptionState();

  Future<SubscriptionState> getSubscriptionState();

  /// Purchase a subscription plan via platform receipt.
  Future<SubscriptionState> purchaseSubscription({
    required String platform,
    required String receiptOrToken,
    required String planId,
  });

  /// Restore purchases (IAP).
  Future<bool> restorePurchases();

  /// Get feature entitlements based on current subscription.
  Future<SubscriptionEntitlements> getEntitlements();
}
