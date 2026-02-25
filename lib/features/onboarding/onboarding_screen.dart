import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/mode/app_mode.dart';
import '../../core/mode/mode_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final l = AppLocalizations.of(context)!;
    final pages = _buildPages(mode, l);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/profile-setup'),
                child: Text(
                  l.skip,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
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
                        Icon(
                          p.icon,
                          size: 80,
                          color: accent,
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                        const SizedBox(height: 32),
                        Text(
                          p.title,
                          style: AppTypography.headlineMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 16),
                        Text(
                          p.body,
                          style: AppTypography.bodyLarge.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? accent
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
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
