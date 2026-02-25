import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

/// Records user location for safety/security tracking.
class SecurityService {
  SecurityService({required this.api});
  final ApiClient api;

  /// Report current location to the backend.
  /// Call once per day or on app open when location is available.
  Future<void> recordLocation({
    required double lat,
    required double lng,
    String? address,
  }) async {
    debugPrint('[Security] Recording location: $lat, $lng');
    final body = <String, dynamic>{
      'lat': lat,
      'lng': lng,
    };
    if (address != null) body['address'] = address;
    await api.post('/security/location', body: body);
    debugPrint('[Security] Location recorded');
  }
}
