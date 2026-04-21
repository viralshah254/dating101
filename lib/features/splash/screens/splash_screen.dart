import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale/app_locale_provider.dart';
import '../../../core/location/app_location_service.dart';
import '../../../core/location/location_service_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/logo_with_transparent_white.dart';
import '../../../data/api/api_client.dart';
import '../../../l10n/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  static Future<bool?> _showReactivatePrompt(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.reactivateAccountPromptTitle),
        content: Text(l.reactivateAccountPromptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.reactivateAccountNo),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.reactivateAccountYes),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateAfterSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final authRepo = ref.read(authRepositoryProvider);
    final userId = authRepo.currentUserId;

    String destination;
    if (userId == null) {
      final localeSet = ref.read(appLocaleProvider);
      destination =
          localeSet == null ? '/language-select' : '/login';
    } else {
      // User is authenticated — check if they have a profile
      debugPrint('[Splash] User authenticated ($userId), checking profile...');
      final profileRepo = ref.read(profileRepositoryProvider);
      try {
        final profile = await profileRepo.getMyProfile();
        if (profile != null) {
          debugPrint(
            '[Splash] Profile exists (${profile.name}), going to home',
          );
          destination = '/';
        } else {
          debugPrint('[Splash] No profile found, routing to profile setup');
          destination = '/profile-for';
        }
      } catch (e) {
        if (e is ApiException && e.code == 'ACCOUNT_DEACTIVATED') {
          debugPrint('[Splash] Account deactivated, showing reactivate prompt');
          if (!mounted) return;
          final reactivate = await _showReactivatePrompt(context);
          if (!mounted) return;
          if (reactivate == true) {
            try {
              await ref.read(accountRepositoryProvider).reactivateAccount();
              if (!mounted) return;
              final profile = await profileRepo.getMyProfile();
              destination = profile != null ? '/' : '/profile-for';
            } catch (_) {
              await authRepo.signOut();
              destination = '/login';
            }
          } else {
            await authRepo.signOut();
            destination = '/login';
          }
        } else if (e is ApiException && (e.statusCode == 401 || e.statusCode == 403)) {
          debugPrint(
            '[Splash] Auth invalid (${e.statusCode}), signing out and routing to login',
          );
          await authRepo.signOut();
          destination = '/login';
        } else {
          debugPrint(
            '[Splash] Error checking profile: $e — routing to setup',
          );
          destination = '/profile-for';
        }
      }
    }

    if (!mounted) return;
    final access = await ref.read(locationServiceProvider).checkAccess();
    if (!mounted) return;

    if (access == LocationAccess.granted) {
      context.go(destination);
    } else {
      context.go('/location-required?then=${Uri.encodeComponent(destination)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Splash gradient background — the token that was defined but never used
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.roseDeep,
                        AppColors.darkBackground,
                      ],
                      stops: [0.0, 0.7],
                    )
                  : AppColors.splashGradient,
            ),
          ),

          // Soft radial glow centered behind logo — enhanced with contrast
          Positioned(
            top: size.height * 0.22,
            left: size.width * 0.05,
            right: size.width * 0.05,
            height: size.height * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  radius: 0.75,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 900.ms),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo — cinematic scale + blur clear
                Center(
                  child: SizedBox(
                    width: 360,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        child: LogoWithTransparentWhite(
                          assetPath: 'assets/images/shubhmilan_logo.png',
                          width: 540,
                          fit: BoxFit.contain,
                          whiteThreshold: 200,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.72, 0.72),
                      end: const Offset(1, 1),
                      duration: 1000.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 18),

                // Brand tagline — now uses AppTypography (Inter) consistently
                
                const Spacer(flex: 2),

                // Loading indicator
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.saffron.withValues(alpha: 0.8),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(delay: 900.ms)
                    .then()
                    .shimmer(
                      duration: 1200.ms,
                      color: AppColors.rosePrimary.withValues(alpha: 0.3),
                    ),
                const SizedBox(height: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
