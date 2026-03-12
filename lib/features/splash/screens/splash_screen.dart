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
          destination = '/mode-select';
        }
      } catch (e) {
        if (e is ApiException && e.code == 'ACCOUNT_DEACTIVATED') {
          debugPrint('[Splash] Account deactivated, showing reactivate prompt');
          final reactivate = await _showReactivatePrompt(context);
          if (!mounted) return;
          if (reactivate == true) {
            try {
              await ref.read(accountRepositoryProvider).reactivateAccount();
              if (!mounted) return;
              final profile = await profileRepo.getMyProfile();
              destination = profile != null ? '/' : '/mode-select';
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
            '[Splash] Error checking profile: $e — defaulting to home',
          );
          destination = '/';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final bg = isDark ? AppColors.darkBackground : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Center(
              child: SizedBox(
                width: 392, // 280 * 1.4
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.center,
                    child: LogoWithTransparentWhite(
                      assetPath: 'assets/images/shubhmilan_logo.png',
                      width: 588, // 420 * 1.4
                      fit: BoxFit.contain,
                      whiteThreshold: 200,
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  duration: 900.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 500.ms),
            const Spacer(flex: 2),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(delay: 700.ms)
                .then()
                .shimmer(
                  duration: 1200.ms,
                  color: accent.withValues(alpha: 0.3),
                ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
