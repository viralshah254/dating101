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
  Future<bool> restorePurchases() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return false;
  }

  @override
  Future<SubscriptionEntitlements> getEntitlements() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return const SubscriptionEntitlements(
      canSendMessage: false,
      canSeeWhoLikedYou: false,
      canSeeWhoShortlistedYou: false,
      dailyInterestLimit: 10,
      dailyMessageLimit: 0,
    );
  }
}
