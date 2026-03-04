import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_typography.dart';
import 'app_locale_provider.dart';

const _localeNames = <String, String>{
  'en': 'English',
  'hi': 'हिन्दी',
  'bn': 'বাংলা',
  'te': 'తెలుగు',
  'mr': 'मराठी',
  'ta': 'தமிழ்',
  'ur': 'اردو',
  'gu': 'ગુજરાતી',
  'kn': 'ಕನ್ನಡ',
  'ml': 'മലയാളം',
  'pa': 'ਪੰਜਾਬੀ',
};

/// Shows a bottom sheet to select app language. Used on login screen and in settings.
void showLanguagePickerSheet(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context)!;
  final currentCode = ref.read(appLocaleProvider);
  final locales = supportedAppLocales;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.appLanguage,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: locales.length,
                  itemBuilder: (_, index) {
                    final locale = locales[index];
                    final code = locale.languageCode;
                    final name = _localeNames[code] ?? code;
                    final isSelected = currentCode == code;
                    return ListTile(
                      title: Text(name),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () {
                        ref.read(appLocaleProvider.notifier).setLocale(code);
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l.languageSetTo(name)),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
