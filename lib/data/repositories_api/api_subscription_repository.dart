import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/repositories/subscription_repository.dart';
import '../api/api_client.dart';

class ApiSubscriptionRepository implements SubscriptionRepository {
  ApiSubscriptionRepository({required this.api});
  final ApiClient api;

  @override
  Future<SubscriptionState> getSubscriptionState() async {
    final body = await api.get('/subscription/me');
    return _parse(body);
  }

  @override
  Stream<SubscriptionState> watchSubscriptionState() {
    final controller = StreamController<SubscriptionState>();
    getSubscriptionState().then((state) {
      if (!controller.isClosed) controller.add(state);
    }).catchError((e) {
      if (!controller.isClosed) controller.addError(e);
    });
    return controller.stream;
  }

  @override
  Future<SubscriptionState> purchaseSubscription({
    required String platform,
    required String receiptOrToken,
    required String planId,
  }) async {
    debugPrint('[Subscription] Purchasing plan=$planId platform=$platform');
    final body = await api.post('/subscription/purchase', body: {
      'platform': platform,
      'receiptOrToken': receiptOrToken,
      'planId': planId,
    });
    return _parse(body);
  }

  @override
  Future<bool> restorePurchases() async {
    try {
      final body = await api.post('/subscription/restore', body: {
        'platform': 'ios',
        'receiptOrToken': '',
      });
      final state = _parse(body);
      return state.isActive;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<SubscriptionEntitlements> getEntitlements() async {
    debugPrint('[Subscription] Fetching entitlements');
    final body = await api.get('/subscription/entitlements');
    return SubscriptionEntitlements(
      canSendMessage: body['canSendMessage'] as bool? ?? false,
      canSeeWhoLikedYou: body['canSeeWhoLikedYou'] as bool? ?? body['canSeeWhoLiked'] as bool? ?? false,
      canSeeWhoShortlistedYou: body['canSeeWhoShortlistedYou'] as bool? ?? false,
      dailyInterestLimit: body['dailyInterestLimit'] as int? ?? 10,
      dailyMessageLimit: body['dailyMessageLimit'] as int? ?? 0,
      hasPriorityDiscovery: body['hasPriorityDiscovery'] as bool? ?? false,
      canSuperlike: body['canSuperlike'] as bool? ?? false,
      raw: body,
    );
  }

  static SubscriptionState _parse(Map<String, dynamic> j) {
    return SubscriptionState(
      tier: (j['tier'] as String?) == 'premium'
          ? SubscriptionTier.premium
          : SubscriptionTier.none,
      expiresAt: j['expiresAt'] != null
          ? DateTime.tryParse(j['expiresAt'] as String)
          : null,
      isActive: j['isActive'] as bool? ?? false,
    );
  }
}
