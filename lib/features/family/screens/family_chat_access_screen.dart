import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/family_providers.dart';

/// Lets the user control what their family sees in chats.
/// familyChatPolicy: "private" | "summaries" | "full"
class FamilyChatAccessScreen extends ConsumerStatefulWidget {
  const FamilyChatAccessScreen({super.key});

  @override
  ConsumerState<FamilyChatAccessScreen> createState() => _FamilyChatAccessScreenState();
}

class _FamilyChatAccessScreenState extends ConsumerState<FamilyChatAccessScreen> {
  String? _selectedPolicy;

  static const _policies = [
    _Policy(
      value: 'private',
      icon: Icons.lock_outline_rounded,
      name: 'Private (recommended)',
      body: 'Your family cannot see any of your chats. This is the default and cannot be overridden by family members.',
      color: AppColors.indiaGreen,
    ),
    _Policy(
      value: 'summaries',
      icon: Icons.chat_bubble_outline_rounded,
      name: 'Chat summaries',
      body: 'Family can see who you\'re talking to — participant names and the last message timestamp only. No message content.',
      color: AppColors.saffron,
    ),
    _Policy(
      value: 'full',
      icon: Icons.forum_outlined,
      name: 'Full access',
      body: 'Family can read the full conversation threads. Only grant this if you\'re in a managed profile scenario.',
      color: AppColors.rosePrimary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final modeAsync = ref.watch(familyModeNotifierProvider);

    modeAsync.whenData((data) {
      _selectedPolicy ??= data['familyChatPolicy'] as String? ?? 'private';
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Privacy'),
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
              'What can your family see?',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: onSurface,
                height: 1.2,
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 8),
            Text(
              'Control how much of your conversations your family members can access.',
              style: AppTypography.bodyMedium.copyWith(
                color: onSurface.withValues(alpha: 0.55),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 60.ms),
            const SizedBox(height: 24),

            // Strong assurance box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.indiaGreen.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.indiaGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, size: 20, color: AppColors.indiaGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your conversations are end-to-end confidential. This setting controls voluntary sharing. Even with "Full access", family members cannot reply or message on your behalf.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.indiaGreen,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 80.ms),

            const SizedBox(height: 24),

            // Policy cards
            ...(_policies.asMap().entries.map((e) {
              final policy = e.value;
              final selected = _selectedPolicy == policy.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () async {
                    setState(() => _selectedPolicy = policy.value);
                    await ref
                        .read(familyModeNotifierProvider.notifier)
                        .patch(familyChatPolicy: policy.value);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chat privacy updated'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: selected
                          ? policy.color.withValues(alpha: 0.07)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? policy.color.withValues(alpha: 0.4)
                            : cs.outline.withValues(alpha: 0.15),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: policy.color.withValues(alpha: 0.12),
                          ),
                          child: Icon(policy.icon, size: 20, color: policy.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                policy.name,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                policy.body,
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
                              ? Icon(Icons.check_circle_rounded, color: policy.color, size: 22, key: const ValueKey('check'))
                              : Icon(Icons.radio_button_unchecked_rounded,
                                  color: onSurface.withValues(alpha: 0.2),
                                  size: 22,
                                  key: const ValueKey('empty')),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: Duration(milliseconds: e.key * 80)).fadeIn(duration: 280.ms).slideY(begin: 0.08, end: 0),
              );
            })),
          ],
        ),
      ),
    );
  }
}

class _Policy {
  const _Policy({
    required this.value,
    required this.icon,
    required this.name,
    required this.body,
    required this.color,
  });
  final String value;
  final IconData icon;
  final String name;
  final String body;
  final Color color;
}
