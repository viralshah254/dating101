import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen loading experience shown while first-time profile setup completes.
class CreatingProfileLoadingOverlay extends StatefulWidget {
  const CreatingProfileLoadingOverlay({super.key});

  @override
  State<CreatingProfileLoadingOverlay> createState() =>
      _CreatingProfileLoadingOverlayState();
}

class _CreatingProfileLoadingOverlayState extends State<CreatingProfileLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _hintTimer;
  int _hintIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _hintTimer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % 3);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String _hint(AppLocalizations l) {
    switch (_hintIndex % 3) {
      case 0:
        return l.creatingProfileHintTailoring;
      case 1:
        return l.creatingProfileHintMatches;
      default:
        return l.creatingProfileHintAlmost;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final onSurface = scheme.onSurface;
    final surface = scheme.surface;
    final l = AppLocalizations.of(context)!;

    final veil = Color.lerp(surface, accent, 0.04) ?? surface;

    return Material(
      color: veil,
      child: SafeArea(
        child: AbsorbPointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final t = _pulse.value;
                      final glow = 0.18 + 0.14 * t;
                      final scale = 1.0 + 0.06 * t;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: glow),
                                blurRadius: 28 + 18 * t,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 92,
                                height: 92,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.2,
                                  strokeCap: StrokeCap.round,
                                  color: accent,
                                  backgroundColor: accent.withValues(alpha: 0.12),
                                ),
                              ),
                              Icon(
                                Icons.favorite_rounded,
                                size: 32,
                                color: accent,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 36),
                  Text(
                    l.creatingProfileTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMedium.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.creatingProfileSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: onSurface.withValues(alpha: 0.55),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Text(
                      _hint(l),
                      key: ValueKey(_hintIndex),
                      textAlign: TextAlign.center,
                      style: AppTypography.titleSmall.copyWith(
                        color: accent.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 220,
                      height: 5,
                      child: LinearProgressIndicator(
                        backgroundColor: onSurface.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          accent.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  _FloatingPrefIcons(accent: accent, onSurface: onSurface),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingPrefIcons extends StatelessWidget {
  const _FloatingPrefIcons({
    required this.accent,
    required this.onSurface,
  });

  final Color accent;
  final Color onSurface;

  static const _icons = [
    Icons.cake_outlined,
    Icons.height,
    Icons.temple_hindu_outlined,
    Icons.groups_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _icons.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  _icons[i],
                  size: 22,
                  color: onSurface.withValues(alpha: 0.45),
                ),
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(reverse: true),
                )
                .moveY(
                  begin: 0,
                  end: -5,
                  duration: 1.7.seconds,
                  delay: (i * 180).ms,
                  curve: Curves.easeInOutCubic,
                ),
          ),
      ],
    );
  }
}
