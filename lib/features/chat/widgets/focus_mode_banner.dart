import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';

/// Focus Mode banner — shown at the top of the discovery screen when the user
/// has an active deep conversation thread (20+ messages in 5 days).
///
/// Shows a connection tracker: days connected, message count, and a
/// "Have you met yet?" CTA after 14 days.
class FocusModeBanner extends StatelessWidget {
  const FocusModeBanner({
    super.key,
    required this.otherPersonName,
    required this.daysConnected,
    required this.messageCount,
    required this.threadId,
    this.showMeetNudge = false,
    this.onFocusModeAccept,
    this.onDismiss,
    this.onMarkMet,
    this.onOpenChat,
  });

  final String otherPersonName;
  final int daysConnected;
  final int messageCount;
  final String threadId;
  final bool showMeetNudge;
  final VoidCallback? onFocusModeAccept;
  final VoidCallback? onDismiss;
  final VoidCallback? onMarkMet;
  final VoidCallback? onOpenChat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (showMeetNudge) {
      return _MeetNudgeBanner(
        name: otherPersonName,
        daysConnected: daysConnected,
        onOpenChat: onOpenChat,
        onMarkMet: onMarkMet,
        onDismiss: onDismiss,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withValues(alpha: 0.12),
                cs.secondary.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Something is forming with $otherPersonName',
                          style: AppTypography.titleSmall.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Want to focus on this connection?',
                          style: AppTypography.bodySmall.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Stats row
              Row(
                children: [
                  _StatChip(
                    icon: Icons.calendar_today_rounded,
                    label: '$daysConnected days',
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '$messageCount messages',
                    color: cs.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.onSurface.withValues(alpha: 0.6),
                        side: BorderSide(
                            color: cs.outline.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Not now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onFocusModeAccept,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Focus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: AppMotion.medium)
        .slideY(begin: -0.2, end: 0);
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 14-day meet nudge banner.
class _MeetNudgeBanner extends StatelessWidget {
  const _MeetNudgeBanner({
    required this.name,
    required this.daysConnected,
    this.onOpenChat,
    this.onMarkMet,
    this.onDismiss,
  });

  final String name;
  final int daysConnected;
  final VoidCallback? onOpenChat;
  final VoidCallback? onMarkMet;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const meetColor = Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: meetColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meetColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.handshake_rounded, color: meetColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ready to meet $name in person?',
                  style: AppTypography.titleSmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "You've been chatting for $daysConnected days — maybe it's time to suggest a coffee?",
            style: AppTypography.bodySmall.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onMarkMet,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: meetColor,
                    side: const BorderSide(color: meetColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('We met! 🎉'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenChat,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Send date idea'),
                  style: FilledButton.styleFrom(
                    backgroundColor: meetColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppMotion.medium)
        .slideY(begin: -0.2, end: 0);
  }
}
