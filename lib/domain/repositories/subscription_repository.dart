/// Subscription tier (for paywall).
/// silver < gold < platinum. `premium` is a legacy alias for gold.
enum SubscriptionTier { none, silver, gold, premium, platinum }

extension SubscriptionTierExt on SubscriptionTier {
  bool get isPaid => this != SubscriptionTier.none;

  bool get isAtLeastSilver =>
      this == SubscriptionTier.silver ||
      this == SubscriptionTier.gold ||
      this == SubscriptionTier.premium ||
      this == SubscriptionTier.platinum;

  bool get isAtLeastGold =>
      this == SubscriptionTier.gold ||
      this == SubscriptionTier.premium ||
      this == SubscriptionTier.platinum;

  bool get isAtLeastPlatinum => this == SubscriptionTier.platinum;

  String get displayName {
    switch (this) {
      case SubscriptionTier.silver:
        return 'Silver';
      case SubscriptionTier.gold:
      case SubscriptionTier.premium:
        return 'Gold';
      case SubscriptionTier.platinum:
        return 'Platinum';
      case SubscriptionTier.none:
        return 'Free';
    }
  }
}

SubscriptionTier parseTier(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'silver':
      return SubscriptionTier.silver;
    case 'gold':
      return SubscriptionTier.gold;
    case 'premium':
      return SubscriptionTier.premium;
    case 'platinum':
      return SubscriptionTier.platinum;
    default:
      return SubscriptionTier.none;
  }
}

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
    this.tier = SubscriptionTier.none,
    this.gender = 'unknown',
    this.canExpressInterest = true,
    this.canShortlist = true,
    this.canViewFullProfile = true,
    // Silver+: can initiate messages. Free users can only reply inside
    // acceptance-opened threads (the isMatched bypass in the UI handles this).
    this.canSendMessage = false,
    this.canSeeWhoLikedYou = false,
    this.canSeeWhoShortlistedYou = false,
    this.dailyInterestLimit = 10,
    this.dailyMessageLimit = 0,
    this.dailyPriorityInterestLimit = 0,
    this.hasPriorityDiscovery = false,
    this.canSuperlike = false,
    this.canSendMessageDirect = false,
    this.canSeeRequestsInbox = false,
    this.requiresAdPerRequestToView = false,
    this.canBoostProfile = false,
    this.canRequestContact = false,
    this.canViewAllPhotos = false,
    this.canSeeCompatBreakdown = false,
    this.canUseTravelMode = false,
    this.hasReadReceipts = false,
    this.photosVisibleCount = 1,
    // Max simultaneous active chat threads. 0 = unlimited (Gold+).
    // Free = 0 but backend only opens threads on mutual acceptance.
    // Silver = 25.
    this.maxActiveChats = 0,
    this.raw = const {},
  });
  final SubscriptionTier tier;
  final String gender;
  final bool canExpressInterest;
  final bool canShortlist;
  final bool canViewFullProfile;
  /// True for Silver+. Free users can only reply inside acceptance-opened threads
  /// (the isMatched bypass in UI handles those cases).
  final bool canSendMessage;
  final bool canSeeWhoLikedYou;
  final bool canSeeWhoShortlistedYou;
  final int dailyInterestLimit;
  final int dailyMessageLimit;
  /// Gold: 5/day. Silver: 1/day. Free: 0 (can use ad for one).
  final int dailyPriorityInterestLimit;
  final bool hasPriorityDiscovery;
  final bool canSuperlike;
  /// If true, messages go straight to inbox; false = goes as a request (Silver behaviour).
  final bool canSendMessageDirect;
  /// If true, user can see the requests inbox. Silver+.
  final bool canSeeRequestsInbox;
  /// If true, user must watch an ad per request before viewing/accepting.
  final bool requiresAdPerRequestToView;
  /// Can purchase profile boost (1 hr/day peak). Included for Platinum; add-on for others.
  final bool canBoostProfile;
  final bool canRequestContact;
  final bool canViewAllPhotos;
  final bool canSeeCompatBreakdown;
  final bool canUseTravelMode;
  final bool hasReadReceipts;
  /// Number of photos visible before blur/gate. 999 = all (Silver+ or female). 1 = free male baseline.
  final int photosVisibleCount;
  /// Max simultaneous active chat threads. 0 = unlimited. Silver = 25.
  final int maxActiveChats;
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
