import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/brand_theme.dart';

/// Primary action button. Renders as a filled button using the theme's primary
/// color by default, or an accent gradient when [gradient] is true.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.gradient = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;
  final bool expand;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<BrandTheme>();
    final isDisabled = loading || onPressed == null;

    Widget content;
    if (loading) {
      content = SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(
            theme.colorScheme.onPrimary,
          ),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: gradient ? Colors.white : theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: gradient ? Colors.white : theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    if (gradient && brand != null) {
      final btn = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radius14),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTokens.radius14),
          child: AnimatedContainer(
            duration: AppTokens.durationFast,
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              gradient: isDisabled ? null : brand.accentGradient,
              color: isDisabled ? theme.colorScheme.onSurface.withValues(alpha: 0.12) : null,
              borderRadius: BorderRadius.circular(AppTokens.radius14),
              boxShadow: isDisabled
                  ? null
                  : AppTokens.shadowGlow(brand.saffron, intensity: 0.2),
            ),
            child: content,
          ),
        ),
      );
      return expand ? SizedBox(width: double.infinity, child: btn) : btn;
    }

    final button = FilledButton(
      onPressed: isDisabled ? null : onPressed,
      child: content,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Secondary / outline style for less prominent actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = icon != null
        ? Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon!,
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        : Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          );

    final button = OutlinedButton(onPressed: onPressed, child: child);

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
