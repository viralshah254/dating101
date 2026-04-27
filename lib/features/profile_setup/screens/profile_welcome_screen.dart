import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/logo_with_transparent_white.dart';

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
    if (name != null && name.isNotEmpty) return 'Hi, $name';
    return 'Where love begins';
  }

  String _subtext(AppMode mode) {
    if (mode.isMatrimony) {
      return "Let's build a profile that helps you\nmeet someone to share a life with.";
    }
    return "Real connection starts with the real you.\nLet's help the right person find you.";
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final size = MediaQuery.sizeOf(context);
    final logoWidth = math.min(260.0, size.width * 0.65);

    // Subtle shadow so white text stays legible across the rose-to-gold gradient
    const textShadow = [
      Shadow(
        color: Color(0x26000000),
        blurRadius: 12,
        offset: Offset(0, 2),
      ),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient — rose → saffron → gold (brand CTA gradient extended)
            const DecoratedBox(
              decoration: BoxDecoration(
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

            // Radial glow — top-left depth
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 1.4,
                height: size.height * 0.65,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x2BFFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Real brand logo — white-background stripped by LogoWithTransparentWhite
                    LogoWithTransparentWhite(
                      assetPath: 'assets/images/shubhmilan_logo.png',
                      width: logoWidth,
                      fit: BoxFit.contain,
                      whiteThreshold: 200,
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.72, 0.72),
                          end: const Offset(1.0, 1.0),
                          duration: 700.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 450.ms),

                    SizedBox(height: size.height * 0.06),

                    // Greeting — Playfair Display, centered, with legibility shadow
                    Text(
                      _greeting(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize:
                            (size.width < 380 ? 32.0 : 38.0),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.6,
                        height: 1.12,
                        shadows: textShadow,
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

                    const SizedBox(height: 18),

                    // Subtext — Inter, centered, max-width for readability
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Text(
                        _subtext(mode),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          height: 1.55,
                          color: Colors.white.withValues(alpha: 0.90),
                          fontWeight: FontWeight.w400,
                          shadows: textShadow,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 420.ms)
                        .slideY(
                          begin: 0.12,
                          end: 0,
                          duration: 500.ms,
                          delay: 420.ms,
                          curve: Curves.easeOut,
                        ),

                    const Spacer(flex: 3),

                    // CTA — white pill, rose foreground, subtle warm lift shadow
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3D2E1C).withValues(alpha: 0.22),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        onPressed: () => context.go('/profile-for'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.rosePrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Start my story',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.rosePrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 650.ms)
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 500.ms,
                          delay: 650.ms,
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
