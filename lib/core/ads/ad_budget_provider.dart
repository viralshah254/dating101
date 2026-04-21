import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repository_providers.dart';

/// Daily ad-unlock budget returned by GET /ads/budget.
class AdBudget {
  const AdBudget({
    required this.used,
    required this.remaining,
    required this.resetsAt,
  });

  final int used;
  final int remaining;
  final DateTime resetsAt;

  static final AdBudget full = AdBudget(
    used: 0,
    remaining: 10,
    resetsAt: DateTime.utc(2000),
  );

  factory AdBudget.fromJson(Map<String, dynamic> j) {
    final epoch = DateTime.utc(2000);
    return AdBudget(
      used: j['used'] as int? ?? 0,
      remaining: j['remaining'] as int? ?? 10,
      resetsAt: j['resetsAt'] != null
          ? DateTime.tryParse(j['resetsAt'] as String) ?? epoch
          : epoch,
    );
  }
}

/// Fetches the current user's daily ad-unlock budget from GET /ads/budget.
/// Auto-refreshes on invalidation (call ref.invalidate(adBudgetProvider) after each ad).
final adBudgetProvider = FutureProvider.autoDispose<AdBudget>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final body = await api.get('/ads/budget');
    return AdBudget.fromJson(body);
  } catch (_) {
    return AdBudget.full;
  }
});
