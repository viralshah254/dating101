import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    this.phone,
    this.verificationId,
    this.referralCode,
  });
  final String? phone;
  final String? verificationId;
  /// Optional referral code from login; sent to backend on verify for 30 days Premium.
  final String? referralCode;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  static const _digitCount = 4;

  final List<TextEditingController> _controllers = List.generate(
    _digitCount,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _digitCount,
    (_) => FocusNode(),
  );

  Timer? _resendTimer;
  int _resendSeconds = 30;
  bool _isVerifying = false;
  String? _errorMessage;
  late AnimationController _shakeController;

  String get _displayPhone {
    final phone = widget.phone?.trim();
    if (phone == null || phone.isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return phone;
    final prefix = phone.startsWith('+')
        ? phone.split(RegExp(r'[\s]')).first
        : '+??';
    final last4 = digits.substring(digits.length - 4);
    return '$prefix \u25CF\u25CF\u25CF\u25CF\u25CF $last4';
  }

  String get _fullCode => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _shakeController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < _digitCount - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_fullCode.length == _digitCount) {
      _verify();
    }
    setState(() {});
  }

  static Future<void> _showReferralSuccessDialog(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.referralPremiumTitle),
        content: Text(l.referralPremiumMessage),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.continueButton),
          ),
        ],
      ),
    );
  }

  void _onKeyPress(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  Future<void> _verify() async {
    if (_fullCode.length != _digitCount || _isVerifying) return;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.verifyOtp(
      verificationId: widget.verificationId ?? '',
      code: _fullCode,
      referralCode: widget.referralCode,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    switch (result) {
      case AuthSuccess(:final isNewUser, :final referralApplied):
        if (isNewUser) {
          debugPrint('[OTP] New user → mode-select (referralApplied=$referralApplied)');
          if (referralApplied) {
            await _showReferralSuccessDialog(context);
            if (!mounted) return;
          }
          context.go('/mode-select');
        } else {
          // Returning user — verify they have a profile
          debugPrint('[OTP] Returning user, checking profile...');
          try {
            final profile = await ref
                .read(profileRepositoryProvider)
                .getMyProfile();
            if (!mounted) return;
            if (profile != null) {
              debugPrint('[OTP] Profile exists → home');
              context.go('/');
            } else {
              debugPrint('[OTP] No profile → mode-select');
              context.go('/mode-select');
            }
          } catch (e) {
            debugPrint('[OTP] Error checking profile: $e → home');
            if (mounted) context.go('/');
          }
        }
      case AuthFailure(:final message):
        setState(() => _errorMessage = message);
        _shakeController.forward(from: 0);
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                          l.otpTitle,
                          style: AppTypography.displayLarge.copyWith(
                            color: onSurface,
                            fontSize: 36,
                            height: 1.15,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.1, end: 0),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: AppTypography.bodyLarge.copyWith(
                          color: onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(text: '${l.otpSubtitle}\n'),
                          TextSpan(
                            text: _displayPhone,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 40),

                    // OTP boxes
                    Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_digitCount, (i) {
                            final hasValue = _controllers[i].text.isNotEmpty;
                            return Container(
                              width: 56,
                              height: 64,
                              margin: EdgeInsets.only(
                                right: i < _digitCount - 1 ? 12 : 0,
                              ),
                              child: KeyboardListener(
                                focusNode: FocusNode(),
                                onKeyEvent: (e) => _onKeyPress(i, e),
                                child: TextField(
                                  controller: _controllers[i],
                                  focusNode: _focusNodes[i],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    filled: true,
                                    fillColor: hasValue
                                        ? accent.withValues(alpha: 0.08)
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: hasValue
                                            ? accent
                                            : Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: accent,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: hasValue
                                            ? accent.withValues(alpha: 0.5)
                                            : Theme.of(context).dividerColor,
                                      ),
                                    ),
                                  ),
                                  onChanged: (v) => _onDigitChanged(i, v),
                                ),
                              ),
                            );
                          }),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.05, end: 0),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Resend
                    Center(
                      child: _resendSeconds > 0
                          ? Text(
                              l.otpResendIn(_resendSeconds),
                              style: AppTypography.bodySmall.copyWith(
                                color: onSurface.withValues(alpha: 0.5),
                              ),
                            )
                          : TextButton(
                              onPressed: () {
                                _startResendTimer();
                                for (final c in _controllers) {
                                  c.clear();
                                }
                                _focusNodes[0].requestFocus();
                                setState(() {});
                              },
                              child: Text(
                                l.resendCode,
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),

                    const Spacer(),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed:
                            _fullCode.length == _digitCount && !_isVerifying
                            ? _verify
                            : null,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l.verifyAndContinue,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
