import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repository_providers.dart';

/// One action type's slice of the daily ad budget.
class AdBudgetBucket {
  const AdBudgetBucket({
    required this.used,
    required this.remaining,
  });

  final int used;
  final int remaining;
}

/// Full response from GET /ads/budget (per-feature daily limits).
class AdBudgetMap {
  const AdBudgetMap({
    required this.limitPerAction,
    required this.resetsAt,
    required this.perAction,
  });

  final int limitPerAction;
  final DateTime resetsAt;
  final Map<String, AdBudgetBucket> perAction;

  AdBudgetBucket forType(String actionType) {
    final b = perAction[actionType];
    if (b != null) return b;
    return AdBudgetBucket(used: 0, remaining: limitPerAction);
  }

  static final AdBudgetMap full = AdBudgetMap(
    limitPerAction: 2,
    resetsAt: DateTime.utc(2000),
    perAction: const {},
  );

  factory AdBudgetMap.fromJson(Map<String, dynamic> j) {
    final epoch = DateTime.utc(2000);
    final limit = j['limitPerAction'] as int? ?? 2;
    final per = <String, AdBudgetBucket>{};
    final raw = j['perAction'];
    if (raw is Map<String, dynamic>) {
      for (final e in raw.entries) {
        final v = e.value;
        if (v is Map<String, dynamic>) {
          per[e.key] = AdBudgetBucket(
            used: v['used'] as int? ?? 0,
            remaining: v['remaining'] as int? ?? limit,
          );
        }
      }
    }
    return AdBudgetMap(
      limitPerAction: limit,
      resetsAt: j['resetsAt'] != null
          ? DateTime.tryParse(j['resetsAt'] as String) ?? epoch
          : epoch,
      perAction: per,
    );
  }
}

/// Fetches the current user's daily ad-unlock budget per feature from GET /ads/budget.
/// Call [ref.invalidate(adBudgetProvider)] after each ad consumption.
final adBudgetProvider = FutureProvider.autoDispose<AdBudgetMap>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final body = await api.get('/ads/budget');
    return AdBudgetMap.fromJson(body);
  } catch (_) {
    return AdBudgetMap.full;
  }
});
