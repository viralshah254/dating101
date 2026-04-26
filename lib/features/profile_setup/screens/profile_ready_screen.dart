import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/wizard_step_shell.dart';

/// Celebration screen shown after profile setup completes.
/// Uses CompletionConfetti, displays a personalised message, then
/// auto-navigates to the home screen after 2.5 s.
class ProfileReadyScreen extends ConsumerStatefulWidget {
  const ProfileReadyScreen({super.key});

  @override
  ConsumerState<ProfileReadyScreen> createState() => _ProfileReadyScreenState();
}

class _ProfileReadyScreenState extends ConsumerState<ProfileReadyScreen> {
  String? _firstName;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    final displayName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    _firstName = displayName.trim().split(' ').first;
    if (_firstName!.isEmpty) _firstName = null;

    _navTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  String _headline() {
    final name = _firstName;
    if (name != null && name.isNotEmpty) return "$name, you're live!";
    return "You're live!";
  }

  String _subtext(AppMode mode) {
    if (mode.isMatrimony) {
      return 'Your profile is out there.\nTime to find your person.';
    }
    return 'Go meet someone real.';
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: CompletionConfetti(
          child: DecoratedBox(
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
            child: SizedBox.expand(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Success badge
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.0, 1.0),
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: 300.ms),

                      const SizedBox(height: 28),

                      // Headline
                      Text(
                        _headline(),
                        style: AppTypography.displayLarge.copyWith(
                          color: Colors.white,
                          fontSize: 38,
                          height: 1.1,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 200.ms)
                          .slideY(
                            begin: 0.12,
                            end: 0,
                            duration: 500.ms,
                            delay: 200.ms,
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
                          .fadeIn(duration: 500.ms, delay: 400.ms)
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            duration: 500.ms,
                            delay: 400.ms,
                            curve: Curves.easeOut,
                          ),

                      const SizedBox(height: 48),

                      // Loading dots — signals auto-advance
                      Row(
                        children: List.generate(3, (i) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(
                                onPlay: (c) => c.repeat(reverse: true),
                              )
                              .scaleXY(
                                begin: 0.6,
                                end: 1.0,
                                duration: 600.ms,
                                delay: Duration(milliseconds: 150 * i),
                                curve: Curves.easeInOut,
                              );
                        }),
                      ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
