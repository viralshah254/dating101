import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mode/mode_provider.dart';
import 'referral_promo_storage.dart';

final referralPromoStorageProvider = Provider<ReferralPromoStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReferralPromoStorage(prefs);
});
