/// Country option for the Change city picker (Browse by country).
/// Only countries with active users are shown.
class CountryOption {
  const CountryOption({
    required this.code,
    required this.name,
    required this.cityCount,
    required this.userCount,
  });

  final String code;
  final String name;
  final int cityCount;
  final int userCount;
}
