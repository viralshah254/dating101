import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _pages = [
    _OnboardingPage(
      title: 'Depth-first connections',
      body: 'See full profiles and send thoughtful intros—no mindless swiping.',
      icon: Icons.person_search,
    ),
    _OnboardingPage(
      title: 'Explore by map',
      body: 'Discover people in your city or plan ahead when you travel.',
      icon: Icons.map,
    ),
    _OnboardingPage(
      title: 'Circles & events',
      body: 'Join communities and real-world meetups that match your life.',
      icon: Icons.groups,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/profile-setup'),
                child: Text(
                  'Skip',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
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
                  _pages.length,
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
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      context.go('/profile-setup');
                    }
                  },
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get started',
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
