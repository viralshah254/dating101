import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_location_service.dart';

final locationServiceProvider = Provider<LocationService>(
  (_) => AppLocationService.instance,
);
