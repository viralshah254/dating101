import 'dart:async';

import '../../domain/repositories/subscription_repository.dart';

class FakeSubscriptionRepository implements SubscriptionRepository {
  final SubscriptionState _state = const SubscriptionState();
  final _controller = StreamController<SubscriptionState>.broadcast();

  @override
  Stream<SubscriptionState> watchSubscriptionState() {
    _controller.add(_state);
    return _controller.stream;
  }

  @override
  Future<SubscriptionState> getSubscriptionState() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _state;
  }

  @override
  Future<SubscriptionState> purchaseSubscription({
    required String platform,
    required String receiptOrToken,
    required String planId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const SubscriptionState(
      tier: SubscriptionTier.premium,
      isActive: true,
    );
  }

  @override
  Future<bool> restorePurchases({
    String? platform,
    String? receiptOrToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return false;
  }

  @override
  Future<SubscriptionEntitlements> getEntitlements() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return const SubscriptionEntitlements(
      tier: SubscriptionTier.none,
      gender: 'unknown',
      canExpressInterest: true,
      canShortlist: true,
      canViewFullProfile: true,
      canSendMessage: false,
      canSeeWhoLikedYou: false,
      canSeeWhoShortlistedYou: false,
      dailyInterestLimit: 10,
      dailyMessageLimit: 0,
    );
  }

  @override
  Future<BoostStatus> getBoostStatus() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return const BoostStatus();
  }

  @override
  Future<BoostStatus> purchaseBoost({
    required String platform,
    required String receiptOrToken,
    required String productId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return BoostStatus(
      activeUntil: DateTime.now().add(const Duration(hours: 24)),
      hoursRemainingToday: 1,
      peakWindowStart: '18:00',
      peakWindowEnd: '22:00',
    );
  }
}
