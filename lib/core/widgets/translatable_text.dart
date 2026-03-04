import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../locale/app_locale_provider.dart';
import '../theme/app_typography.dart';
import '../providers/repository_providers.dart';
import 'package:saathi/l10n/app_localizations.dart';

/// Shows [content] with an optional "Translate" button. On tap, translates to the app locale and shows the result.
class TranslatableText extends ConsumerStatefulWidget {
  const TranslatableText({
    super.key,
    required this.content,
    required this.textStyle,
    this.maxLines,
    this.showTranslateButton = true,
  });

  final String content;
  final TextStyle textStyle;
  final int? maxLines;
  final bool showTranslateButton;

  @override
  ConsumerState<TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends ConsumerState<TranslatableText> {
  String? _translated;
  bool _loading = false;
  bool _showTranslated = true;

  @override
  Widget build(BuildContext context) {
    final text = widget.content.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    final displayText = _translated != null && _showTranslated
        ? _translated!
        : text;
    final locale = ref.watch(appLocaleProvider) ?? 'en';
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayText,
          style: widget.textStyle,
          maxLines: widget.maxLines,
          overflow: widget.maxLines != null ? TextOverflow.ellipsis : null,
        ),
        if (widget.showTranslateButton && text.length > 10) ...[
          const SizedBox(height: 6),
          if (_loading)
            SizedBox(
              height: 24,
              child: Text(
                l.translating,
                style: widget.textStyle.copyWith(
                  fontSize: 12,
                  color: widget.textStyle.color?.withValues(alpha: 0.6),
                ),
              ),
            )
          else if (_translated == null)
            _TranslateButton(
              label: l.translate,
              onTap: () => _translate(ref, locale),
            )
          else
            _TranslateButton(
              label: _showTranslated ? l.showOriginal : l.showTranslation,
              onTap: () => setState(() => _showTranslated = !_showTranslated),
            ),
        ],
      ],
    );
  }

  Future<void> _translate(WidgetRef ref, String targetLocale) async {
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(translateRepositoryProvider)
          .translate(widget.content, targetLocale: targetLocale);
      if (mounted) {
        setState(() {
          _loading = false;
          _translated = result;
          _showTranslated = result != null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translationUnavailable),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _TranslateButton extends StatelessWidget {
  const _TranslateButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
