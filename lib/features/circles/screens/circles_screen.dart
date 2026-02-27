import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
    final circles = _mockCircles;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.navCommunities,
          style: AppTypography.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Groups by interest, alumni & career',
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          ...circles.asMap().entries.map((e) {
            final c = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  Card(
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(c.icon, color: accent),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.name,
                                            style: AppTypography.titleMedium
                                                .copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            '${c.memberCount} members',
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.8),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () => context.push('/paywall'),
                                      child: Text(l.join),
                                    ),
                                  ],
                                ),
                                if (c.description.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    c.description,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.85),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (60 * e.key).ms)
                      .slideY(begin: 0.02, end: 0),
            );
          }),
        ],
      ),
    );
  }
}

class _Circle {
  _Circle({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.icon,
  });
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final IconData icon;
}

final List<_Circle> _mockCircles = [
  _Circle(
    id: '1',
    name: 'London Desi Professionals',
    description: 'Career-focused meetups and networking in London.',
    memberCount: 420,
    icon: Icons.work,
  ),
  _Circle(
    id: '2',
    name: 'IIT Alumni UK',
    description: 'IIT alumni in the UK. Events and reunions.',
    memberCount: 180,
    icon: Icons.school,
  ),
  _Circle(
    id: '3',
    name: 'Chai & Chats',
    description: 'Casual meetups over chai. No agenda, just good vibes.',
    memberCount: 310,
    icon: Icons.coffee,
  ),
];
