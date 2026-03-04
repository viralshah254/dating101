import 'package:flutter/foundation.dart';

import '../../domain/repositories/translate_repository.dart';
import '../api/api_client.dart';

class ApiTranslateRepository implements TranslateRepository {
  ApiTranslateRepository({required this.api});
  final ApiClient api;

  @override
  Future<String?> translate(String text, {required String targetLocale}) async {
    if (text.trim().isEmpty) return null;
    try {
      final body = await api.post('/translate', body: {
        'text': text,
        'targetLocale': targetLocale,
      });
      final translated = body['translatedText'] as String?;
      return translated?.trim().isEmpty == true ? null : translated;
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 501) {
        if (kDebugMode) debugPrint('[Translate] Endpoint not available: ${e.message}');
        return null;
      }
      rethrow;
    }
  }
}
