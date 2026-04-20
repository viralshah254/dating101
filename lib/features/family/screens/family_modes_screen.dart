import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/family_providers.dart';

class FamilyModesScreen extends ConsumerStatefulWidget {
  const FamilyModesScreen({super.key});

  @override
  ConsumerState<FamilyModesScreen> createState() => _FamilyModesScreenState();
}

class _FamilyModesScreenState extends ConsumerState<FamilyModesScreen> {
  String? _selectedMode;

  static const _modes = [
    _Mode(
      value: 'self',
      icon: Icons.person_outline_rounded,
      name: 'Self mode',
      body: 'You manage everything yourself. Family sees nothing. Full independence.',
      gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B5CC6)]),
    ),
    _Mode(
      value: 'assisted',
      icon: Icons.family_restroom_rounded,
      name: 'Family-assisted mode',
      body: 'Your family can browse, shortlist, and add notes. You control what they see.',
      gradient: AppColors.premiumGradient,
      recommended: true,
    ),
    _Mode(
      value: 'hidden',
      icon: Icons.visibility_off_outlined,
      name: 'Hidden-from-family mode',
      body: 'Your profile is completely hidden from people you flag as family members.',
      gradient: LinearGradient(
        colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
      ),
    ),
    _Mode(
      value: 'joint',
      icon: Icons.shield_outlined,
      name: 'Joint decision mode',
      body: 'Both you and a parent must approve before an interest is sent. True consensus.',
      gradient: AppColors.goldGradient,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final modeAsync = ref.watch(familyModeNotifierProvider);

    // Sync selected mode from server once loaded
    modeAsync.whenData((data) {
      _selectedMode ??= data['familyMode'] as String? ?? 'self';
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Mode'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'How involved should your family be?',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: onSurface,
                height: 1.2,
              ),
            ).animate().fadeIn(duration: 350.ms),
            const SizedBox(height: 8),
            Text(
              'Switch anytime. Your private chats always stay private.',
              style: AppTypography.bodyMedium.copyWith(
                color: onSurface.withValues(alpha: 0.55),
              ),
            ).animate().fadeIn(duration: 350.ms, delay: 60.ms),
            const SizedBox(height: 28),

            // Mode cards
            ...(_modes.asMap().entries.map((e) {
              final mode = e.value;
              final selected = _selectedMode == mode.value;
              return _ModeCard(
                mode: mode,
                selected: selected,
                delay: Duration(milliseconds: e.key * 80),
                onTap: () async {
                  setState(() => _selectedMode = mode.value);
                  await ref
                      .read(familyModeNotifierProvider.notifier)
                      .patch(familyMode: mode.value);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Switched to ${mode.name}'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            })),

            const SizedBox(height: 24),

            // Info strip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your conversations are always private — your family can never see your direct messages, regardless of the mode you choose.',
                      style: AppTypography.bodySmall.copyWith(
                        color: onSurface.withValues(alpha: 0.65),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms, delay: 360.ms),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
    this.delay = Duration.zero,
  });
  final _Mode mode;
  final bool selected;
  final VoidCallback onTap;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.06)
                : cs.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.4)
                  : cs.outline.withValues(alpha: 0.15),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with gradient background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: mode.gradient,
                ),
                child: Icon(mode.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mode.name,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        if (mode.recommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Most used',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.body,
                      style: AppTypography.bodySmall.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: 180.ms,
                child: selected
                    ? Icon(Icons.check_circle_rounded, color: cs.primary, size: 24, key: const ValueKey('check'))
                    : Icon(Icons.radio_button_unchecked_rounded,
                        color: onSurface.withValues(alpha: 0.2),
                        size: 24,
                        key: const ValueKey('empty')),
              ),
            ],
          ),
        ),
      ).animate(delay: delay).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
    );
  }
}

class _Mode {
  const _Mode({
    required this.value,
    required this.icon,
    required this.name,
    required this.body,
    required this.gradient,
    this.recommended = false,
  });
  final String value;
  final IconData icon;
  final String name;
  final String body;
  final LinearGradient gradient;
  final bool recommended;
}
