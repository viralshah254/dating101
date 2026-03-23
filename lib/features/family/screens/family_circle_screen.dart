import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';

/// Family Circle — lets users invite a family member to view their shortlist
/// and leave private notes on profiles.
class FamilyCircleScreen extends StatefulWidget {
  const FamilyCircleScreen({super.key});

  @override
  State<FamilyCircleScreen> createState() => _FamilyCircleScreenState();
}

class _FamilyCircleScreenState extends State<FamilyCircleScreen> {
  bool _hasLink = false;
  String? _inviteUrl;
  String? _selectedRelationship;

  final _relationships = <(String, IconData, String)>[
    ('parent', Icons.person_outline_rounded, 'Parent'),
    ('sibling', Icons.people_outline_rounded, 'Sibling'),
    ('other', Icons.groups_rounded, 'Other'),
  ];

  Future<void> _generateInvite() async {
    if (_selectedRelationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your family member\'s relationship'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // In a real integration: call POST /family/invite
    setState(() {
      _hasLink = true;
      _inviteUrl = 'https://app.shubhmilan.com/family/join/demo-token-xyz';
    });
  }

  void _copyLink() {
    if (_inviteUrl == null) return;
    Clipboard.setData(ClipboardData(text: _inviteUrl!));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite link copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Circle'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.08),
                    cs.secondary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.family_restroom_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Involve Your Family',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invite a parent or sibling to view your shortlisted profiles and leave private notes. Only you can see their notes.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: AppMotion.medium)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 24),

            if (!_hasLink) ...[
              Text(
                'Who are you inviting?',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ..._relationships.map(((String, IconData, String) r) {
                final (key, icon, label) = r;
                final selected = _selectedRelationship == key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRelationship = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary.withValues(alpha: 0.08)
                            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? cs.primary.withValues(alpha: 0.4)
                              : cs.outline.withValues(alpha: 0.15),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon,
                              color:
                                  selected ? cs.primary : cs.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 14),
                          Text(
                            label,
                            style: AppTypography.titleSmall.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (selected)
                            Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _generateInvite,
                icon: const Icon(Icons.link_rounded),
                label: const Text('Generate Invite Link'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ] else ...[
              // Invite link generated
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF2E7D32), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Invite link ready!',
                          style: AppTypography.titleSmall.copyWith(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _inviteUrl!,
                              style: AppTypography.bodySmall.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.7),
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _copyLink,
                            child: Icon(Icons.copy_rounded,
                                size: 18, color: cs.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _copyLink,
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share via SMS / WhatsApp'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
              const SizedBox(height: 24),
              // How it works section
              Text(
                'How Family Circle works',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...[
                (Icons.visibility_rounded, 'They see your shortlist',
                    'Name, occupation, city, and one photo — nothing private.'),
                (Icons.edit_note_rounded, 'Private notes',
                    'They can leave notes on each profile that only you see.'),
                (Icons.lock_outline_rounded, 'You\'re in control',
                    'They can\'t message anyone. You decide who you proceed with.'),
              ].asMap().entries.map((e) {
                final (icon, title, subtitle) = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary.withValues(alpha: 0.1),
                        ),
                        child: Icon(icon, size: 20, color: cs.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                )),
                            Text(subtitle,
                                style: AppTypography.bodySmall.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                )),
                          ],
                        ),
                      ),
                    ],
                  )
                      .animate(delay: Duration(milliseconds: e.key * 80))
                      .fadeIn(duration: AppMotion.medium)
                      .slideX(begin: 0.15, end: 0),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
