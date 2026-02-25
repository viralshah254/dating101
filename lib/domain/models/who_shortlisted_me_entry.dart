/// One entry from GET /shortlist/received ("People who shortlisted you").
/// When [blurred] is true (non‑premium), only [profileId] may be set; [firstName]/[age] may be empty/null.
class WhoShortlistedMeEntry {
  const WhoShortlistedMeEntry({
    required this.profileId,
    this.firstName = '',
    this.age,
    this.name,
    this.imageUrl,
    this.blurred = false,
  });
  final String profileId;
  final String firstName;
  final int? age;
  final String? name;
  final String? imageUrl;
  final bool blurred;
}
