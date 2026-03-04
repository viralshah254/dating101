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
    this.dailyPriorityInterestLimit = 0,
    this.hasPriorityDiscovery = false,
    this.canSuperlike = false,
    this.canSendMessageDirect = false,
    this.canSeeRequestsInbox = false,
    this.requiresAdPerRequestToView = false,
    this.canBoostProfile = false,
    this.raw = const {},
  });
  final bool canSendMessage;
  final bool canSeeWhoLikedYou;
  final bool canSeeWhoShortlistedYou;
  final int dailyInterestLimit;
  final int dailyMessageLimit;
  /// Premium: 10/day. Free: 0 (can use ad to send one).
  final int dailyPriorityInterestLimit;
  final bool hasPriorityDiscovery;
  final bool canSuperlike;
  /// If true, messages go to normal chat; if false, free user sends as message request (after ad).
  final bool canSendMessageDirect;
  /// If true, user can see the requests (inbox) list. Premium only.
  final bool canSeeRequestsInbox;
  /// If true, user must watch ad per request before viewing/accepting (except e.g. phone).
  final bool requiresAdPerRequestToView;
  /// Can purchase profile boost (1hr/day peak, show on top).
  final bool canBoostProfile;
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

  /// Restore purchases (IAP). Pass [platform] and [receiptOrToken] from the
  /// store after calling restore in the app; backend validates and links to user.
  Future<bool> restorePurchases({
    String? platform,
    String? receiptOrToken,
  });

  /// Get feature entitlements based on current subscription.
  Future<SubscriptionEntitlements> getEntitlements();

  /// Boost status (GET /boost/me). Used for boost UI and paywall.
  Future<BoostStatus> getBoostStatus();

  /// Purchase one-time boost via IAP (POST /boost/purchase). Product ID e.g. boost_one_time.
  Future<BoostStatus> purchaseBoost({
    required String platform,
    required String receiptOrToken,
    required String productId,
  });
}

/// Boost state from GET /boost/me or after POST /boost/purchase.
class BoostStatus {
  const BoostStatus({
    this.activeUntil,
    this.hoursRemainingToday = 0,
    this.peakWindowStart,
    this.peakWindowEnd,
  });
  final DateTime? activeUntil;
  final int hoursRemainingToday;
  final String? peakWindowStart;
  final String? peakWindowEnd;

  bool get isActive => activeUntil != null && activeUntil!.isAfter(DateTime.now());
}
