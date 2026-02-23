import 'package:freezed_annotation/freezed_annotation.dart';

import 'discovery_preferences.dart';

part 'dating_extensions.freezed.dart';

@freezed
class DatingExtensions with _$DatingExtensions {
  const factory DatingExtensions({
    String? datingIntent, // serious / casual / marriage / friends first / etc.
    List<PromptAnswer>? prompts,
    String? voiceIntroUrl,
    @Default(false) bool travelModeEnabled,
    DiscoveryPreferences? discoveryPreferences,
  }) = _DatingExtensions;
}

@freezed
class PromptAnswer with _$PromptAnswer {
  const factory PromptAnswer({
    required String questionId,
    required String questionText,
    required String answer,
  }) = _PromptAnswer;
}
