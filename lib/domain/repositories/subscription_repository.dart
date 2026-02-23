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

/// Premium / subscription state (for paywall, feature gating).
abstract class SubscriptionRepository {
  Stream<SubscriptionState> watchSubscriptionState();

  Future<SubscriptionState> getSubscriptionState();

  /// Restore purchases (IAP).
  Future<bool> restorePurchases();
}
