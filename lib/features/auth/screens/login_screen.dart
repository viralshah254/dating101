import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale/language_picker_sheet.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';

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
  final _referralCodeController = TextEditingController();
  bool _ageConfirmed = false;
  bool _isSending = false;
  String? _errorMessage;
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

  /// ISO 3166-1 alpha-2 country code -> _CountryCode (for device locale).
  static final _isoToCountry = {
    'IN': _countryCodes[0],   // India
    'GB': _countryCodes[1],   // UK
    'US': _countryCodes[2],   // USA
    'AE': _countryCodes[3],   // UAE
    'AU': _countryCodes[4],   // Australia
    'SG': _countryCodes[5],   // Singapore
    'DE': _countryCodes[6],   // Germany
    'FR': _countryCodes[7],   // France
    'CA': _countryCodes[8],   // Canada
    'KE': _countryCodes[9],   // Kenya
    'ZA': _countryCodes[10],  // South Africa
    'MY': _countryCodes[11],  // Malaysia
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

  /// Picks country code from device locale (e.g. US, IN, GB); falls back to India.
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
    _referralCodeController.dispose();
    super.dispose();
  }

  /// Normalized phone: strip leading zeros, keep only digits.
  String get _normalizedPhone {
    final raw = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    return raw.replaceFirst(RegExp(r'^0+'), '');
  }

  bool get _canContinue =>
      _ageConfirmed && _normalizedPhone.length >= 7 && !_isSending;

  Future<void> _continue() async {
    if (!_canContinue) return;
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final phone = _normalizedPhone;
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.sendOtp(
      countryCode: _country.code,
      phone: phone,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    switch (result) {
      case SendOtpSuccess(:final verificationId):
        final displayPhone = '${_country.code} $phone';
        var otpPath = '/otp?phone=${Uri.encodeComponent(displayPhone)}&vid=${Uri.encodeComponent(verificationId)}';
        final refCode = _referralCodeController.text.trim();
        if (refCode.isNotEmpty) {
          otpPath += '&ref=${Uri.encodeComponent(refCode)}';
        }
        context.push(otpPath);
      case SendOtpFailure(:final message):
        setState(() => _errorMessage = message);
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () =>
                          showLanguagePickerSheet(context, ref),
                      icon: const Icon(Icons.language_rounded),
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
                      const SizedBox(height: 24),
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

                      // Phone input
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
                              onChanged: (_) =>
                                  setState(() => _errorMessage = null),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 250.ms),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],

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

                      const SizedBox(height: 20),

                      // Optional referral code
                      Text(
                        l.referralCodeHint,
                        style: AppTypography.labelMedium.copyWith(
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _referralCodeController,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        style: AppTypography.bodyMedium.copyWith(
                          color: onSurface,
                          letterSpacing: 1.2,
                        ),
                        decoration: InputDecoration(
                          hintText: l.referralCodeOptional,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
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
                                  l.continueButton,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
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
                c.label.toLowerCase().contains(q) ||
                c.code.contains(q))
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
                hintText: 'Search country...',
                prefixIcon: Icon(Icons.search, color: onSurface.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                        'No countries found',
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
                        leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
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

