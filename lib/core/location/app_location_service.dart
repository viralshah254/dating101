import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'place_search_service.dart';

/// Result of capturing profile creation location (for audit/safety).
class ProfileCreationLocation {
  const ProfileCreationLocation({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.address,
  });

  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final String? address;
}

/// Location permission state for gating the app.
enum LocationAccess {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Contract for location checks so app flows can be tested with overrides.
abstract class LocationService {
  Future<LocationAccess> checkAccess();
  Future<LocationAccess> requestPermission();
  Future<ProfileCreationLocation?> getCurrentCreationLocation();
  Future<bool> openAppSettings();
}

/// Service for accurate location: permission checks and current position.
/// Used to require location for app access and to record where a profile was created.
class AppLocationService implements LocationService {
  AppLocationService._();
  static final AppLocationService instance = AppLocationService._();

  /// Check current location access (without requesting).
  @override
  Future<LocationAccess> checkAccess() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return LocationAccess.serviceDisabled;

    final permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.denied:
        return LocationAccess.denied;
      case LocationPermission.deniedForever:
        return LocationAccess.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationAccess.granted;
      case LocationPermission.unableToDetermine:
        return LocationAccess.denied;
    }
  }

  /// Request permission. Returns [LocationAccess.granted] if user grants.
  @override
  Future<LocationAccess> requestPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return LocationAccess.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationAccess.granted;
      case LocationPermission.deniedForever:
        return LocationAccess.deniedForever;
      default:
        return LocationAccess.denied;
    }
  }

  /// Get current position with high accuracy for profile creation tracking.
  /// Returns null if permission not granted, service disabled, or error.
  @override
  Future<ProfileCreationLocation?> getCurrentCreationLocation() async {
    final access = await checkAccess();
    if (access != LocationAccess.granted) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.country,
          ].whereType<String>().where((e) => e.isNotEmpty).toList();
          address = parts.isNotEmpty ? parts.join(', ') : (p.country ?? 'Unknown');
        }
      } catch (_) {
        // Optional: address is best-effort
      }

      return ProfileCreationLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        capturedAt: DateTime.now().toUtc(),
        address: address,
      );
    } catch (_) {
      return null;
    }
  }

  /// Open system app settings so user can enable location.
  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Best-effort [PlaceSuggestion] from device GPS + reverse geocoding for profile "where you live".
  /// Returns null if permission denied, service off, or lookup fails.
  Future<PlaceSuggestion?> getCurrentLocationAsPlaceSuggestion() async {
    final access = await checkAccess();
    if (access != LocationAccess.granted) return null;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      String? city = p.locality;
      if (city == null || city.trim().isEmpty) {
        city = p.subLocality;
      }
      if (city == null || city.trim().isEmpty) {
        city = p.administrativeArea;
      }
      final country = (p.country ?? '').trim();
      if (country.isEmpty && (city == null || city.isEmpty)) {
        return null;
      }
      final displayParts = <String>[
        if (city != null && city.isNotEmpty) city,
        if (p.administrativeArea != null &&
            p.administrativeArea!.isNotEmpty &&
            p.administrativeArea != city) ...[
          p.administrativeArea!,
        ],
        if (country.isNotEmpty) country,
      ];
      final displayName =
          displayParts.isNotEmpty ? displayParts.join(', ') : country;
      return PlaceSuggestion(
        displayName: displayName,
        country: country,
        countryCode: p.isoCountryCode,
        state: p.administrativeArea,
        city: city,
      );
    } catch (_) {
      return null;
    }
  }
}
