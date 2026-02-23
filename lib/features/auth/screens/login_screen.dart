import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

class _CountryCode {
  const _CountryCode(this.code, this.label, this.flag);
  final String code;
  final String label;
  final String flag;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _usePhone = true;
  bool _ageConfirmed = false;
  _CountryCode _country = const _CountryCode(
    '+91',
    'India',
    '\u{1F1EE}\u{1F1F3}',
  );

  static const _countryCodes = [
    _CountryCode('+91', 'India', '\u{1F1EE}\u{1F1F3}'),
    _CountryCode('+44', 'UK', '\u{1F1EC}\u{1F1E7}'),
    _CountryCode('+1', 'USA', '\u{1F1FA}\u{1F1F8}'),
    _CountryCode('+971', 'UAE', '\u{1F1E6}\u{1F1EA}'),
    _CountryCode('+61', 'Australia', '\u{1F1E6}\u{1F1FA}'),
    _CountryCode('+65', 'Singapore', '\u{1F1F8}\u{1F1EC}'),
    _CountryCode('+49', 'Germany', '\u{1F1E9}\u{1F1EA}'),
    _CountryCode('+33', 'France', '\u{1F1EB}\u{1F1F7}'),
    _CountryCode('+1', 'Canada', '\u{1F1E8}\u{1F1E6}'),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    if (!_ageConfirmed) return false;
    if (_usePhone) return _phoneController.text.trim().length >= 10;
    return _emailController.text.trim().contains('@');
  }

  void _continue() {
    if (!_canContinue) return;
    if (_usePhone) {
      final phone = '${_country.code} ${_phoneController.text.trim()}';
      context.push('/otp?phone=${Uri.encodeComponent(phone)}');
    } else {
      context.go('/mode-select');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 56),
                      Text(
                            l.loginHeroTitle,
                            style: AppTypography.displayLarge.copyWith(
                              color: onSurface,
                              fontSize: 40,
                              height: 1.15,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: -0.15, end: 0, curve: Curves.easeOut),
                      const SizedBox(height: 12),
                      Text(
                        l.loginHeroSubtitle,
                        style: AppTypography.bodyLarge.copyWith(
                          color: onSurface.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                      const SizedBox(height: 40),

                      // Tab switcher
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _TabButton(
                              label: l.phoneNumber,
                              icon: Icons.phone_outlined,
                              isSelected: _usePhone,
                              onTap: () => setState(() => _usePhone = true),
                            ),
                            _TabButton(
                              label: l.email,
                              icon: Icons.email_outlined,
                              isSelected: !_usePhone,
                              onTap: () => setState(() => _usePhone = false),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 250.ms),

                      const SizedBox(height: 24),

                      if (_usePhone) ...[
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showCountryPicker(context),
                              child: Container(
                                height: 56,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _country.flag,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _country.code,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 20,
                                      color: onSurface.withValues(alpha: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: onSurface,
                                  letterSpacing: 1.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: l.phoneNumber,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTypography.bodyLarge.copyWith(
                            color: onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: l.emailHint,
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),

                      const SizedBox(height: 20),

                      // Age confirmation
                      GestureDetector(
                        onTap: () =>
                            setState(() => _ageConfirmed = !_ageConfirmed),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _ageConfirmed,
                                onChanged: (v) =>
                                    setState(() => _ageConfirmed = v ?? false),
                                activeColor: accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l.ageConfirmation,
                                style: AppTypography.bodySmall.copyWith(
                                  color: onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: _canContinue ? _continue : null,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            l.continueButton,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l.orDivider,
                              style: AppTypography.caption,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Social buttons
                      _SocialButton(
                        icon: Icons.g_mobiledata,
                        label: l.continueWithGoogle,
                        onTap: () => context.go('/mode-select'),
                      ),
                      const SizedBox(height: 12),
                      _SocialButton(
                        icon: Icons.apple,
                        label: l.continueWithApple,
                        onTap: () => context.go('/mode-select'),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  l.termsConsent,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ...(_countryCodes.map(
              (c) => ListTile(
                leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                title: Text(c.label),
                trailing: Text(c.code, style: AppTypography.labelLarge),
                onTap: () {
                  setState(() => _country = c);
                  Navigator.pop(ctx);
                },
              ),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: Theme.of(context).dividerColor),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: onSurface),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
