/// City option for the Change city picker.
/// Only cities with active users (userCount > 0) are shown.
class CityOption {
  const CityOption({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.countryName,
    required this.userCount,
    this.isNearby = false,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String countryCode;
  final String countryName;
  final int userCount;
  final bool isNearby;
  final double? distanceKm;

  /// Display label for user count, e.g. "1,247 users"
  String get userCountLabel => _formatCount(userCount);

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
