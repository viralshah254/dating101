import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_typography.dart';

/// Compact voice intro player badge for discovery cards.
/// Tap to play/pause. Shows animated waveform when playing.
class VoiceIntroBadge extends StatefulWidget {
  const VoiceIntroBadge({
    super.key,
    required this.url,
    this.onPlay,
  });

  final String url;
  /// Called when the user taps play — caller is responsible for actual audio.
  final VoidCallback? onPlay;

  @override
  State<VoiceIntroBadge> createState() => _VoiceIntroBadgeState();
}

class _VoiceIntroBadgeState extends State<VoiceIntroBadge>
    with TickerProviderStateMixin {
  bool _playing = false;
  late AnimationController _pulseCtrl;
  final _bars = List.generate(7, (_) => 0.3);
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addListener(_updateBars);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _updateBars() {
    if (_playing) {
      setState(() {
        for (int i = 0; i < _bars.length; i++) {
          _bars[i] = 0.15 + _rng.nextDouble() * 0.85;
        }
      });
    }
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _playing = !_playing);
    if (_playing) {
      _pulseCtrl.repeat();
      widget.onPlay?.call();
      // Simulate playback end after 30s
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _playing) setState(() => _playing = false);
      });
    } else {
      _pulseCtrl.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _playing
                ? cs.primary.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _playing ? Icons.pause_rounded : Icons.mic_rounded,
              size: 14,
              color: _playing ? cs.primary : Colors.white,
            ),
            const SizedBox(width: 6),
            // Mini waveform
            SizedBox(
              width: 32,
              height: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _bars.map((amp) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 3,
                    height: 4 + amp * 12,
                    decoration: BoxDecoration(
                      color: _playing
                          ? cs.primary.withValues(alpha: 0.7 + amp * 0.3)
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(begin: 0.3, end: 0);
  }
}

/// Full-size player card for full_profile_screen.
class VoiceIntroPlayerCard extends StatefulWidget {
  const VoiceIntroPlayerCard({
    super.key,
    required this.url,
    required this.name,
  });

  final String url;
  final String name;

  @override
  State<VoiceIntroPlayerCard> createState() => _VoiceIntroPlayerCardState();
}

class _VoiceIntroPlayerCardState extends State<VoiceIntroPlayerCard>
    with TickerProviderStateMixin {
  bool _playing = false;
  late AnimationController _waveCtrl;
  final _bars = List.generate(20, (_) => 0.3);
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addListener(() {
        if (_playing) {
          setState(() {
            for (int i = 0; i < _bars.length; i++) {
              _bars[i] = 0.1 + _rng.nextDouble() * 0.9;
            }
          });
        }
      });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _playing = !_playing);
    if (_playing) {
      _waveCtrl.repeat();
    } else {
      _waveCtrl.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Play button
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, cs.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: _playing
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.name}\'s Voice Intro',
                  style: AppTypography.labelMedium.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                // Waveform bars
                SizedBox(
                  height: 28,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _bars.map((amp) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 3,
                        height: 4 + amp * 24,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: _playing
                              ? primary.withValues(alpha: 0.5 + amp * 0.5)
                              : primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.mic_rounded, size: 16, color: primary.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
