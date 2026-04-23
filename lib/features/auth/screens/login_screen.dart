import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/language_picker_sheet.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_post_sign_in.dart';

class _CountryCode {
  const _CountryCode(this.code, this.label, this.flag);
  final String code;
  final String label;
  final String flag;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _ageConfirmed = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _errorCode;
  late _CountryCode _country;

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
    _CountryCode('+254', 'Kenya', '\u{1F1F0}\u{1F1EA}'),
    _CountryCode('+27', 'South Africa', '\u{1F1FF}\u{1F1E6}'),
    _CountryCode('+60', 'Malaysia', '\u{1F1F2}\u{1F1FE}'),
  ];

  static final _isoToCountry = {
    'IN': _countryCodes[0],
    'GB': _countryCodes[1],
    'US': _countryCodes[2],
    'AE': _countryCodes[3],
    'AU': _countryCodes[4],
    'SG': _countryCodes[5],
    'DE': _countryCodes[6],
    'FR': _countryCodes[7],
    'CA': _countryCodes[8],
    'KE': _countryCodes[9],
    'ZA': _countryCodes[10],
    'MY': _countryCodes[11],
  };

  static const _defaultCountry = _CountryCode(
    '+91',
    'India',
    '\u{1F1EE}\u{1F1F3}',
  );

  @override
  void initState() {
    super.initState();
    _country = _countryCodeFromDeviceLocale();
  }

  _CountryCode _countryCodeFromDeviceLocale() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final iso = locale.countryCode;
    if (iso != null && iso.isNotEmpty) {
      final upper = iso.toUpperCase();
      final match = _isoToCountry[upper];
      if (match != null) return match;
    }
    return _defaultCountry;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    final raw = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    return raw.replaceFirst(RegExp(r'^0+'), '');
  }

  bool get _passwordLongEnough => _passwordController.text.length >= 8;

  bool get _passwordsMatch =>
      _confirmPasswordController.text == _passwordController.text;

  bool get _canContinue =>
      (!_isSignUp || _ageConfirmed) &&
      _normalizedPhone.length >= 7 &&
      _passwordLongEnough &&
      !_isSending &&
      (!_isSignUp || _passwordsMatch);

  Future<void> _continue() async {
    if (!_canContinue) return;
    final l = AppLocalizations.of(context)!;
    if (_isSignUp && !_passwordsMatch) {
      setState(() {
        _errorMessage = l.authPasswordsMismatch;
        _errorCode = null;
      });
      return;
    }
    setState(() {
      _isSending = true;
      _errorMessage = null;
      _errorCode = null;
    });

    final phone = _normalizedPhone;
    final authRepo = ref.read(authRepositoryProvider);
    final AuthResult result;
    if (_isSignUp) {
      final refCode = _referralCodeController.text.trim();
      result = await authRepo.signUpWithPassword(
        countryCode: _country.code,
        phone: phone,
        password: _passwordController.text,
        referralCode: refCode.isEmpty ? null : refCode,
      );
    } else {
      result = await authRepo.signInWithPassword(
        countryCode: _country.code,
        phone: phone,
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    setState(() => _isSending = false);

    switch (result) {
      case AuthSuccess(:final isNewUser, :final referralApplied):
        await navigateAfterAuthSuccess(
          context,
          ref,
          isNewUser: isNewUser,
          referralApplied: referralApplied,
        );
      case AuthFailure(:final message, :final code):
        setState(() {
          _errorMessage = message;
          _errorCode = code;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // cs.onSurface is properly scoped to the widget tree (context-aware),
    // unlike AppTypography which bakes colors via a static _isDark flag that
    // can end up stale when MaterialApp builds both theme and darkTheme.
    final cs = Theme.of(context).colorScheme;
    // On the gradient background, text in the hero area is always white
    const heroTextColor = Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Rich auth hero gradient — makes the glassmorphism card actually work
            if (!isDark)
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.authHeroGradient),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.roseDeep,
                      AppColors.rosePrimary.withValues(alpha: 0.85),
                      AppColors.darkBackground,
                    ],
                    stops: const [0.0, 0.4, 0.85],
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () => showLanguagePickerSheet(context, ref),
                          icon: const Icon(Icons.language_rounded, color: Colors.white70),
                          tooltip: l.appLanguage,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            l.loginHeroTitle,
                            style: AppTypography.displayLarge.copyWith(
                              color: heroTextColor,
                              fontSize: 42,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: -0.15, end: 0, curve: Curves.easeOut),
                          const SizedBox(height: 10),
                          Text(
                            l.loginHeroSubtitle,
                            style: AppTypography.bodyLarge.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              height: 1.4,
                            ),
                          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                          const SizedBox(height: 32),
                          // Glassmorphism form card — now has a rich gradient to blur
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.45)
                                      : Colors.white.withValues(alpha: 0.82),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.roseDeep.withValues(alpha: 0.18),
                                      blurRadius: 32,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                              color: isDark
                                                  ? AppColors.darkSurfaceVariant
                                                  : AppColors.lightSurfaceVariant,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.lightDivider,
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
                                                    color: cs.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 20,
                                                  color: AppColors.lightTextTertiary,
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
                                              letterSpacing: 1.2,
                                              color: cs.onSurface,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: l.phoneNumber,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            onChanged: (_) => setState(() {
                                              _errorMessage = null;
                                              _errorCode = null;
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: AppTypography.bodyLarge.copyWith(color: cs.onSurface),
                                      decoration: InputDecoration(
                                        labelText: l.authPasswordLabel,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: AppColors.lightTextTertiary,
                                          ),
                                          onPressed: () => setState(
                                              () => _obscurePassword = !_obscurePassword),
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {
                                        _errorMessage = null;
                                        _errorCode = null;
                                      }),
                                    ),
                                    if (_isSignUp) ...[
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _confirmPasswordController,
                                        obscureText: _obscureConfirm,
                                        style: AppTypography.bodyLarge.copyWith(color: cs.onSurface),
                                        decoration: InputDecoration(
                                          labelText: l.authConfirmPasswordLabel,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirm
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: AppColors.lightTextTertiary,
                                            ),
                                            onPressed: () => setState(
                                                () => _obscureConfirm = !_obscureConfirm),
                                          ),
                                        ),
                                        onChanged: (_) => setState(() {
                                          _errorMessage = null;
                                          _errorCode = null;
                                        }),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => setState(() {
                                          _isSignUp = !_isSignUp;
                                          _errorMessage = null;
                                          _errorCode = null;
                                        }),
                                        child: Text(
                                          _isSignUp ? l.authSignInLink : l.authSignUpLink,
                                          style: AppTypography.labelLarge.copyWith(
                                            color: AppColors.rosePrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 8),
                                      _buildErrorWidget(context),
                                    ],
                                    const SizedBox(height: 10),
                                    if (_isSignUp) ...[
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _ageConfirmed = !_ageConfirmed,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: _ageConfirmed,
                                                onChanged: (v) => setState(
                                                    () => _ageConfirmed = v ?? false),
                                                activeColor: AppColors.rosePrimary,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                l.ageConfirmation,
                                                style: AppTypography.bodySmall.copyWith(color: cs.onSurface.withValues(alpha: 0.8)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l.referralCodeHint,
                                        style: AppTypography.labelMedium.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                                      ),
                                      const SizedBox(height: 8),
                                        TextField(
                                        controller: _referralCodeController,
                                        textCapitalization: TextCapitalization.characters,
                                        autocorrect: false,
                                        style: AppTypography.bodyMedium.copyWith(
                                          letterSpacing: 1.2,
                                          color: cs.onSurface,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: l.referralCodeOptional,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ],
                                    const SizedBox(height: 22),
                                    // Gradient button — always shows rose gradient, dims when disabled
                                    AnimatedOpacity(
                                      opacity: _canContinue ? 1.0 : 0.55,
                                      duration: const Duration(milliseconds: 200),
                                      child: GestureDetector(
                                        onTap: _canContinue ? _continue : null,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: double.infinity,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            gradient: AppColors.brandGradient,
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: _canContinue
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.rosePrimary
                                                          .withValues(alpha: 0.45),
                                                      blurRadius: 20,
                                                      offset: const Offset(0, 8),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: _isSending
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text(
                                                    _isSignUp
                                                        ? l.authCreateAccountButton
                                                        : l.authSignInButton,
                                                    style: AppTypography.labelLarge.copyWith(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(
                                begin: 0.05,
                                end: 0,
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
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isServerOrNetworkError {
    return _errorCode == 'SERVER_ERROR' ||
        _errorCode == 'INTERNAL_ERROR' ||
        _errorCode == 'SEND_FAILED' ||
        _errorCode == null;
  }

  Widget _buildErrorWidget(BuildContext context) {
    final isServerError = _isServerOrNetworkError;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.error;

    if (!isServerError) {
      return Text(
        _errorMessage!,
        style: AppTypography.bodySmall.copyWith(color: textColor),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => _CountryPickerSheet(
          countries: _countryCodes,
          scrollController: scrollController,
          onSelect: (c) {
            setState(() => _country = c);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({
    required this.countries,
    required this.scrollController,
    required this.onSelect,
  });
  final List<_CountryCode> countries;
  final ScrollController scrollController;
  final void Function(_CountryCode) onSelect;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<_CountryCode> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.countries;
      } else {
        _filtered = widget.countries
            .where((c) =>
                c.label.toLowerCase().contains(q) || c.code.contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchCountryHint,
                prefixIcon:
                    Icon(Icons.search, color: onSurface.withValues(alpha: 0.4)),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _onSearch,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        AppLocalizations.of(context)!.noCountriesFound,
                        style: AppTypography.bodyMedium.copyWith(
                          color: onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final c = _filtered[i];
                      return ListTile(
                        leading:
                            Text(c.flag, style: const TextStyle(fontSize: 24)),
                        title: Text(c.label),
                        trailing: Text(c.code, style: AppTypography.labelLarge),
                        onTap: () => widget.onSelect(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
