import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Wraps every profile-setup step with a consistent warm header:
/// - Illustrated icon circle with brand gradient
/// - Large Playfair question headline
/// - Optional subtitle
/// - Content area
///
/// Optional micro-toast [saveStatus] surfaces the auto-save state.
class WizardStepShell extends StatelessWidget {
  const WizardStepShell({
    super.key,
    required this.icon,
    required this.headline,
    this.subtitle,
    required this.child,
    this.saveStatus,
    this.completenessGain,
  });

  final IconData icon;
  final String headline;
  final String? subtitle;
  final Widget child;

  /// 'saving' | 'saved' | null
  final String? saveStatus;

  /// If non-null, a "+X% complete" pill is shown alongside the save pill.
  final int? completenessGain;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header — collapses when keyboard is open to free space for inputs ──
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: keyboardOpen
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon circle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.brandGradient,
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1, 1),
                            duration: 350.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: 200.ms),

                      const SizedBox(height: 16),

                      // Headline
                      Text(
                        headline,
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                          height: 1.2,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 60.ms)
                          .slideX(begin: 0.08, end: 0, duration: 300.ms, curve: Curves.easeOut),

                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: onSurface.withValues(alpha: 0.55),
                            height: 1.4,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 300.ms, delay: 120.ms),
                      ],

                      const SizedBox(height: 12),

                      // Save / completeness pills
                      if (saveStatus != null || completenessGain != null)
                        Row(
                          children: [
                            if (saveStatus != null)
                              _StatusPill(
                                label: saveStatus == 'saving' ? 'Saving…' : 'Saved',
                                icon: saveStatus == 'saving'
                                    ? Icons.sync_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: saveStatus == 'saving'
                                    ? AppColors.saffron.withValues(alpha: 0.8)
                                    : AppColors.indiaGreen,
                                spin: saveStatus == 'saving',
                              ).animate().fadeIn(duration: 200.ms).scale(
                                    begin: const Offset(0.85, 0.85),
                                    end: const Offset(1, 1),
                                    duration: 200.ms,
                                  ),
                            if (completenessGain != null) ...[
                              const SizedBox(width: 8),
                              _StatusPill(
                                label: '+$completenessGain% complete',
                                icon: Icons.trending_up_rounded,
                                color: AppColors.rosePrimary,
                              )
                                  .animate()
                                  .fadeIn(duration: 200.ms, delay: 80.ms)
                                  .scale(
                                    begin: const Offset(0.85, 0.85),
                                    end: const Offset(1, 1),
                                    duration: 200.ms,
                                    delay: 80.ms,
                                  ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
        ),

        // Divider + spacing — also collapses with keyboard
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: keyboardOpen
              ? const SizedBox.shrink()
              : const Column(
                  children: [
                    SizedBox(height: 20),
                    Divider(height: 1, indent: 24, endIndent: 24),
                    SizedBox(height: 20),
                  ],
                ),
        ),

        // ── Content ──────────────────────────────────────────────────────
        // Must be expanded: parent is inside PageView with fixed height; without this,
        // Column + SingleChildScrollView would take infinite intrinsic height → overflow.
        Expanded(child: child),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.color,
    this.spin = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool spin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          spin
              ? Icon(icon, size: 12, color: color)
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: 1000.ms)
              : Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// A celebratory confetti-burst widget shown at milestone completeness %s.
/// Wrap around any widget that should trigger confetti on first mount.
class CompletionConfetti extends StatefulWidget {
  const CompletionConfetti({super.key, required this.child, this.burst = true});

  final Widget child;
  final bool burst;

  @override
  State<CompletionConfetti> createState() => _CompletionConfettiState();
}

class _CompletionConfettiState extends State<CompletionConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: 1200.ms);
    if (widget.burst) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (widget.burst)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  if (_controller.value > 0.8) return const SizedBox.shrink();
                  return CustomPaint(
                    painter: _ConfettiPainter(progress: _controller.value),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});
  final double progress;

  static const _colors = [
    AppColors.rosePrimary,
    AppColors.saffron,
    AppColors.gold,
    AppColors.indiaGreen,
    Color(0xFF7C3AED),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = [1, 7, 13, 19, 23, 29, 37, 41, 43, 47, 53, 59];
    for (var i = 0; i < 40; i++) {
      final seed = rng[i % rng.length] * (i + 1);
      final px = (seed * 37 % 100) / 100.0;
      final py = (seed * 53 % 100) / 100.0;
      final color = _colors[i % _colors.length];
      final paint = Paint()..color = color.withValues(alpha: 1 - progress);
      final x = px * size.width;
      final y = py * size.height * progress * 1.5 - size.height * 0.1;
      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
