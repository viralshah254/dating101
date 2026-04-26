import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Warm, personalised welcome screen shown to new users immediately after
/// sign-up — before they answer "who is this for?".
/// Sets a celebratory, human tone before any form fields appear.
class ProfileWelcomeScreen extends ConsumerStatefulWidget {
  const ProfileWelcomeScreen({super.key});

  @override
  ConsumerState<ProfileWelcomeScreen> createState() =>
      _ProfileWelcomeScreenState();
}

class _ProfileWelcomeScreenState extends ConsumerState<ProfileWelcomeScreen> {
  String? _firstName;

  @override
  void initState() {
    super.initState();
    final displayName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    _firstName = displayName.trim().split(' ').first;
    if (_firstName!.isEmpty) _firstName = null;
  }

  String _greeting() {
    final name = _firstName;
    if (name != null && name.isNotEmpty) return 'Hi $name 👋';
    return 'Welcome 👋';
  }

  String _subtext(AppMode mode) {
    if (mode.isMatrimony) {
      return "Let's build the profile that finds\nyour life partner.";
    }
    return "Let's show the world\nthe real you.";
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final size = MediaQuery.sizeOf(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD63B6A),
                    Color(0xFFCB6D35),
                    Color(0xFFD4A855),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // Subtle radial glow for depth
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 1.4,
                height: size.height * 0.7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),

                    // Brand mark
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'S',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.6, 0.6),
                          end: const Offset(1.0, 1.0),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 32),

                    // Greeting
                    Text(
                      _greeting(),
                      style: AppTypography.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                        height: 1.1,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 250.ms)
                        .slideY(
                          begin: 0.15,
                          end: 0,
                          duration: 500.ms,
                          delay: 250.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 16),

                    // Subtext
                    Text(
                      _subtext(mode),
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w400,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 450.ms)
                        .slideY(
                          begin: 0.12,
                          end: 0,
                          duration: 500.ms,
                          delay: 450.ms,
                          curve: Curves.easeOut,
                        ),

                    const Spacer(flex: 3),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () => context.go('/profile-for'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.rosePrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Let's go",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 700.ms)
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 500.ms,
                          delay: 700.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 40),
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
