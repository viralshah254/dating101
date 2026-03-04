import '../../domain/repositories/translate_repository.dart';

/// No-op: returns text as-is when backend translate is not available.
class FakeTranslateRepository implements TranslateRepository {
  @override
  Future<String?> translate(String text, {required String targetLocale}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return text.trim().isEmpty ? null : text;
  }
}
