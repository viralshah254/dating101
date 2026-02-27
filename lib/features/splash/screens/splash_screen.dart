import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/app_location_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/logo_with_transparent_white.dart';
import '../../../data/api/api_client.dart';

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

  Future<void> _navigateAfterSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final authRepo = ref.read(authRepositoryProvider);
    final userId = authRepo.currentUserId;

    String destination;
    if (userId == null) {
      destination = '/login';
    } else {
      // User is authenticated — check if they have a profile
      debugPrint('[Splash] User authenticated ($userId), checking profile...');
      try {
        final profileRepo = ref.read(profileRepositoryProvider);
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
        if (e is ApiException && (e.statusCode == 401 || e.statusCode == 403)) {
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
    final access = await AppLocationService.instance.checkAccess();
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
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bg, AppColors.darkSurface, bg],
                )
              : AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 48,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: isDark
                            ? [
                                bg.withValues(alpha: 0.6),
                                bg.withValues(alpha: 0.25),
                                Colors.transparent,
                              ]
                            : [
                                AppColors.splashMid.withValues(alpha: 0.5),
                                AppColors.splashPeach.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.2),
                          blurRadius: 80,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: AppColors.indiaGreen.withValues(alpha: 0.08),
                          blurRadius: 100,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: 280,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: LogoWithTransparentWhite(
                            assetPath: 'assets/images/shubhmilan_logo.png',
                            width: 420,
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
      ),
    );
  }
}
