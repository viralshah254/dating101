import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/subscription_repository.dart';
import '../providers/repository_providers.dart';

/// Gender-aware entitlements: women get more free features than men.
/// Premium unlocks everything for both genders.
enum UserGender { male, female, other, unknown }

class Entitlements {
  const Entitlements({
    required this.tier,
    required this.gender,
  });

  final SubscriptionTier tier;
  final UserGender gender;

  bool get isPremium => tier == SubscriptionTier.premium;
  bool get isFemale => gender == UserGender.female;

  // ── Core actions ──────────────────────────────────────────────────

  /// Express interest: free for everyone
  bool get canExpressInterest => true;

  /// Shortlist (add to shortlist): free for everyone
  bool get canShortlist => true;

  /// View full profiles: free for everyone
  bool get canViewFullProfile => true;

  /// Can send a message at all (women free, men need premium or ad → message request)
  bool get canSendMessage => isPremium || isFemale;

  /// If true, messages go to normal chat; if false, sent as message request (after ad for free).
  bool get canSendMessageDirect => isPremium || isFemale;

  /// See who liked you: free for women, premium for men
  bool get canSeeWhoLikedYou => isPremium || isFemale;

  /// See who shortlisted you (premium only)
  bool get canSeeWhoShortlistedYou => isPremium;

  /// See requests inbox (received interests, contact requests, etc.). Premium only.
  bool get canSeeRequestsInbox => isPremium;

  /// Request contact details: free for women, premium for men
  bool get canRequestContact => isPremium || isFemale;

  // ── Limits ────────────────────────────────────────────────────────

  /// Daily express-interest limit
  int get dailyInterestLimit => isPremium ? 999 : (isFemale ? 30 : 10);

  /// Daily message limit (direct messages; free women get 20, men 0 unless ad → request)
  int get dailyMessageLimit {
    if (isPremium) return 999;
    if (isFemale) return 20;
    return 0;
  }

  /// Priority interests per day: premium 10, free 0 (free can send one per ad).
  int get dailyPriorityInterestLimit => isPremium ? 10 : 0;

  /// Free user can send one priority interest after watching an ad.
  bool get canSendPriorityInterestWithAd => !isPremium;

  // ── Discovery & visibility ────────────────────────────────────────

  /// Travel mode: premium only
  bool get canUseTravelMode => isPremium;

  /// Profile boost: purchasable (premium or separate product)
  bool get canBoostProfile => isPremium;

  /// Priority in discovery: premium only
  bool get hasPriorityDiscovery => isPremium;

  /// Read receipts: premium only
  bool get hasReadReceipts => isPremium;

  /// For premium: must watch ad per request before viewing/accepting (backend can require token).
  bool get requiresAdPerRequestToView => isPremium;

  // ── Photos & profile ──────────────────────────────────────────────

  /// View all photos: free for women, premium for men
  bool get canViewAllPhotos => isPremium || isFemale;

  /// See compatibility breakdown: free for women, premium for men
  bool get canSeeCompatBreakdown => isPremium || isFemale;

  // ── Labels for paywall prompts ────────────────────────────────────

  String get upgradeReason {
    if (isFemale) return 'Upgrade for unlimited messaging and travel mode.';
    return 'Upgrade to send messages, see who likes you, and more.';
  }
}

/// Parses gender string from profile to enum.
UserGender parseGender(String? gender) {
  if (gender == null) return UserGender.unknown;
  switch (gender.toLowerCase()) {
    case 'woman':
    case 'female':
    case 'f':
      return UserGender.female;
    case 'man':
    case 'male':
    case 'm':
      return UserGender.male;
    default:
      return UserGender.other;
  }
}

/// Synchronous entitlements with defaults (use entitlementsAsyncProvider for loaded state).
final entitlementsProvider = Provider<Entitlements>((ref) {
  final async = ref.watch(entitlementsAsyncProvider);
  return async.valueOrNull ??
      const Entitlements(tier: SubscriptionTier.none, gender: UserGender.unknown);
});

/// Async version that loads actual state.
final entitlementsAsyncProvider = FutureProvider<Entitlements>((ref) async {
  final subRepo = ref.watch(subscriptionRepositoryProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);

  final sub = await subRepo.getSubscriptionState();
  final profile = await profileRepo.getMyProfile();
  final gender = parseGender(profile?.gender);

  return Entitlements(tier: sub.tier, gender: gender);
});
