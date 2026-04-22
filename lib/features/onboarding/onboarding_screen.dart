import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mode/app_mode.dart';
import '../../core/mode/mode_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  /// Builds the 3 onboarding slides for the current mode (Dating vs Matrimony).
  List<_OnboardingPage> _buildPages(AppMode mode, AppLocalizations l) {
    if (mode == AppMode.matrimony) {
      return [
        _OnboardingPage(
          title: l.onboardingMatrimonySlide1Title,
          body: l.onboardingMatrimonySlide1Body,
          icon: Icons.diversity_3_rounded,
        ),
        _OnboardingPage(
          title: l.onboardingMatrimonySlide2Title,
          body: l.onboardingMatrimonySlide2Body,
          icon: Icons.family_restroom,
        ),
        _OnboardingPage(
          title: l.onboardingMatrimonySlide3Title,
          body: l.onboardingMatrimonySlide3Body,
          icon: Icons.verified_user,
        ),
      ];
    }
    return [
      _OnboardingPage(
        title: l.onboardingDatingSlide1Title,
        body: l.onboardingDatingSlide1Body,
        icon: Icons.person_search,
      ),
      _OnboardingPage(
        title: l.onboardingDatingSlide2Title,
        body: l.onboardingDatingSlide2Body,
        icon: Icons.map,
      ),
      _OnboardingPage(
        title: l.onboardingDatingSlide3Title,
        body: l.onboardingDatingSlide3Body,
        icon: Icons.groups,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Per-slide brand accent colors used for background tinting and icon color.
  static const _slideColors = [
    AppColors.rosePrimary,  // slide 1: discovery — romantic rose
    AppColors.gold,         // slide 2: matching   — warm gold
    AppColors.indiaGreen,   // slide 3: connect    — fresh emerald
  ];

  /// Dark-mode slide backgrounds: rich jewel tones so the screen never looks
  /// plain black. Light mode uses a gentle 9% tint of the same color.
  static const _slideDarkBg = [
    Color(0xFF3D0B1F), // deep rose-maroon
    Color(0xFF2C1A00), // deep amber-brown
    Color(0xFF002B1A), // deep emerald-forest
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final l = AppLocalizations.of(context)!;
    final pages = _buildPages(mode, l);

    final slideColor = _slideColors[_currentPage];
    final bg = isDark
        ? _slideDarkBg[_currentPage]
        : slideColor.withValues(alpha: 0.09);

    // In dark mode, text sits on a deep jewel background → use white.
    // In light mode, use onSurface (dark) as usual.
    final titleColor = isDark ? Colors.white : cs.onSurface;
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.82)
        : cs.onSurface.withValues(alpha: 0.85);
    final skipColor = isDark
        ? Colors.white.withValues(alpha: 0.38)
        : cs.onSurface.withValues(alpha: 0.45);
    final dotInactive = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : cs.outline.withValues(alpha: 0.5);
    // Icon and active dot use the slide's brand color (visible on both backgrounds).
    final iconColor = isDark ? slideColor : cs.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      color: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/profile-setup'),
                  style: TextButton.styleFrom(foregroundColor: skipColor),
                  child: Text(l.skip),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) {
                    final p = pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Glow container behind icon for depth in dark mode
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: slideColor.withValues(alpha: isDark ? 0.18 : 0.10),
                            ),
                            child: Center(
                              child: Icon(p.icon, size: 72, color: iconColor)
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .scale(begin: const Offset(0.75, 0.75), end: const Offset(1, 1)),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            p.title,
                            style: AppTypography.headlineMedium.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                              shadows: isDark
                                  ? [Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8)]
                                  : null,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 16),
                          Text(
                            p.body,
                            style: AppTypography.bodyLarge.copyWith(color: bodyColor),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 200.ms),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Dot indicators
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? iconColor : dotInactive,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (_currentPage < pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go('/profile-setup');
                      }
                    },
                    child: Text(
                      _currentPage < pages.length - 1 ? l.next : l.getStarted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.body,
    required this.icon,
  });
  final String title;
  final String body;
  final IconData icon;
}
