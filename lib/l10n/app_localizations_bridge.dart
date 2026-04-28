import 'app_localizations.dart';

/// Forwards to codegen getters on concrete [AppLocalizations] subclasses.
///
/// Use these accessors when the analyzer does not yet see newer ARB-generated
/// getters (run `flutter gen-l10n` from `shubhmilan_frontend`). At runtime the
/// delegates load the real strings from `app_localizations_*.dart`.
extension AppLocalizationsBridge on AppLocalizations {
  String get pcGateTitle => (this as dynamic).preChatGateTitle as String;
  String get pcGateBody => (this as dynamic).preChatGateBody as String;
  String get pcGateAccept => (this as dynamic).preChatGateAccept as String;
  String get pcGateDecline => (this as dynamic).preChatGateDecline as String;
  String get pcGateSkip => (this as dynamic).preChatGateSkip as String;
  String get signupTermsAgreementLabelBridge =>
      (this as dynamic).signupTermsAgreementLabel as String;
}
