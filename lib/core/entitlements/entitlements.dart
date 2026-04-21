import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/subscription_repository.dart';
import '../providers/repository_providers.dart';

enum UserGender { male, female, other, unknown }

class Entitlements {
  const Entitlements({
    required this.tier,
    required this.gender,
    required this.canExpressInterest,
    required this.canShortlist,
    required this.canViewFullProfile,
    required this.canSendMessage,
    required this.canSendMessageDirect,
    required this.canSeeWhoLikedYou,
    required this.canSeeWhoShortlistedYou,
    required this.canSeeRequestsInbox,
    required this.requiresAdPerRequestToView,
    required this.canRequestContact,
    required this.canViewAllPhotos,
    required this.canSeeCompatBreakdown,
    required this.canUseTravelMode,
    required this.canBoostProfile,
    required this.hasPriorityDiscovery,
    required this.hasReadReceipts,
    required this.dailyInterestLimit,
    required this.dailyMessageLimit,
    required this.dailyPriorityInterestLimit,
    this.photosVisibleCount = 1,
    this.maxActiveChats = 0,
    this.canSuperlike = false,
  });

  final SubscriptionTier tier;
  final UserGender gender;
  final bool canExpressInterest;
  final bool canShortlist;
  final bool canViewFullProfile;
  /// True for Silver+. Free users can only reply inside acceptance-opened threads
  /// (the isMatched bypass in UI handles those cases).
  final bool canSendMessage;
  final bool canSendMessageDirect;
  final bool canSeeWhoLikedYou;
  final bool canSeeWhoShortlistedYou;
  final bool canSeeRequestsInbox;
  final bool requiresAdPerRequestToView;
  final bool canRequestContact;
  final bool canViewAllPhotos;
  final bool canSeeCompatBreakdown;
  final bool canUseTravelMode;
  final bool canBoostProfile;
  final bool hasPriorityDiscovery;
  final bool hasReadReceipts;
  final int dailyInterestLimit;
  final int dailyMessageLimit;
  final int dailyPriorityInterestLimit;
  /// Number of photos visible before blur/gate. 999 = all (Silver+ or female). 1 = free male baseline.
  final int photosVisibleCount;
  /// Max simultaneous active chat threads. 0 = unlimited (Gold+). Silver = 25.
  final int maxActiveChats;
  /// Platinum only: can send a SuperLike (priority interest that appears at the top of the feed).
  final bool canSuperlike;

  bool get isPremium => tier == SubscriptionTier.premium || tier.isAtLeastGold;
  bool get isSilver => tier.isAtLeastSilver;
  bool get isGold => tier.isAtLeastGold;
  bool get isPlatinum => tier.isAtLeastPlatinum;
  bool get isFemale => gender == UserGender.female;

  /// Gold+ users get LLM-powered AI profile review; free/silver get rule-based only.
  bool get hasAiReview => tier.isAtLeastGold;

  bool get canSendPriorityInterestWithAd => !isPremium;

  String get upgradeReason {
    if (isFemale) return 'Upgrade for travel mode, priority discovery, and AI review.';
    return 'Upgrade to chat with more matches, see who likes you, and more.';
  }

  factory Entitlements.fromSubscriptionEntitlements(
    SubscriptionEntitlements entitlements,
  ) {
    return Entitlements(
      tier: entitlements.tier,
      gender: parseGender(entitlements.gender),
      canExpressInterest: entitlements.canExpressInterest,
      canShortlist: entitlements.canShortlist,
      canViewFullProfile: entitlements.canViewFullProfile,
      canSendMessage: entitlements.canSendMessage,
      canSendMessageDirect: entitlements.canSendMessageDirect,
      canSeeWhoLikedYou: entitlements.canSeeWhoLikedYou,
      canSeeWhoShortlistedYou: entitlements.canSeeWhoShortlistedYou,
      canSeeRequestsInbox: entitlements.canSeeRequestsInbox,
      requiresAdPerRequestToView: entitlements.requiresAdPerRequestToView,
      canRequestContact: entitlements.canRequestContact,
      canViewAllPhotos: entitlements.canViewAllPhotos,
      canSeeCompatBreakdown: entitlements.canSeeCompatBreakdown,
      canUseTravelMode: entitlements.canUseTravelMode,
      canBoostProfile: entitlements.canBoostProfile,
      hasPriorityDiscovery: entitlements.hasPriorityDiscovery,
      hasReadReceipts: entitlements.hasReadReceipts,
      dailyInterestLimit: entitlements.dailyInterestLimit,
      dailyMessageLimit: entitlements.dailyMessageLimit,
      dailyPriorityInterestLimit: entitlements.dailyPriorityInterestLimit,
      photosVisibleCount: entitlements.photosVisibleCount,
      maxActiveChats: entitlements.maxActiveChats,
      canSuperlike: entitlements.canSuperlike,
    );
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

final subscriptionStateProvider = FutureProvider<SubscriptionState>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).getSubscriptionState();
});

final subscriptionStateStreamProvider = StreamProvider<SubscriptionState>((ref) {
  return ref.watch(subscriptionRepositoryProvider).watchSubscriptionState();
});

final subscriptionAccessRefreshProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(subscriptionStateProvider);
    ref.invalidate(subscriptionStateStreamProvider);
    ref.invalidate(entitlementsAsyncProvider);
  };
});

final entitlementsProvider = Provider<Entitlements>((ref) {
  final async = ref.watch(entitlementsAsyncProvider);
  return async.valueOrNull ??
      const Entitlements(
        tier: SubscriptionTier.none,
        gender: UserGender.unknown,
        canExpressInterest: true,
        canShortlist: true,
        canViewFullProfile: true,
        canSendMessage: false,
        canSendMessageDirect: false,
        canSeeWhoLikedYou: false,
        canSeeWhoShortlistedYou: false,
        canSeeRequestsInbox: false,
        requiresAdPerRequestToView: false,
        canRequestContact: false,
        canViewAllPhotos: false,
        canSeeCompatBreakdown: false,
        canUseTravelMode: false,
        canBoostProfile: false,
        hasPriorityDiscovery: false,
        hasReadReceipts: false,
        dailyInterestLimit: 10,
        dailyMessageLimit: 0,
        dailyPriorityInterestLimit: 0,
        photosVisibleCount: 1,
        maxActiveChats: 0,
        canSuperlike: false,
      );
});

final entitlementsAsyncProvider = FutureProvider<Entitlements>((ref) async {
  final subRepo = ref.watch(subscriptionRepositoryProvider);
  final entitlements = await subRepo.getEntitlements();
  return Entitlements.fromSubscriptionEntitlements(entitlements);
});
