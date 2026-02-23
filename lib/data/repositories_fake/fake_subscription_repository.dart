import 'dart:async';

import '../../domain/repositories/subscription_repository.dart';

class FakeSubscriptionRepository implements SubscriptionRepository {
  SubscriptionState _state = const SubscriptionState();
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
  Future<bool> restorePurchases() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return false;
  }
}
