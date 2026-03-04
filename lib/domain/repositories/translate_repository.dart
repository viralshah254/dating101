/// On-demand translation of user content (e.g. bio) to the viewer's language.
/// Backend implements POST /translate; see docs/BACKEND_PROFILE_TRANSLATION.md.
abstract class TranslateRepository {
  /// Translates [text] to [targetLocale] (e.g. 'en', 'hi'). Returns null if translation fails or is unavailable.
  Future<String?> translate(String text, {required String targetLocale});
}
