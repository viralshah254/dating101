import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/app_location_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';

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
        debugPrint('[Splash] Error checking profile: $e — defaulting to home');
        destination = '/';
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
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.saffron.withValues(alpha: 0.08),
                    bg,
                    AppColors.indiaGreen.withValues(alpha: 0.06),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: AppColors.indiaGreen.withValues(alpha: 0.1),
                          blurRadius: 90,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/shubhmilan_logo.png',
                          width: 338,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        Image.asset(
                          'assets/images/shubhmilan_heart.png',
                          width: 120,
                          fit: BoxFit.contain,
                        ),
                      ],
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
