import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'app_tokens.dart';

/// Shared motion presets for consistent, restrained animation.
///
/// Usage: `widget.animate().addEffect(AppMotion.fadeSlideUp())` or use
/// the convenience extensions like `widget.fadeSlideIn(delay: 100.ms)`.
class AppMotion {
  AppMotion._();

  // ── Canonical duration tokens ────────────────────────────────────────────
  /// Micro feedback: button presses, icon swaps (100 ms).
  static const micro = Duration(milliseconds: 100);

  /// Fast transitions: fade-ins, chip appearances (200 ms).
  static const fast = Duration(milliseconds: 200);

  /// Standard transitions: page slides, card reveals (320 ms).
  static const medium = Duration(milliseconds: 320);

  /// Deliberate reveals: bottom sheets, panels (480 ms).
  static const slow = Duration(milliseconds: 480);

  /// Emphasis animations: hero moments, onboarding (600 ms).
  static const enter = Duration(milliseconds: 600);

  /// Long loops: pulse, shimmer, idle breathing (1500 ms).
  static const loop = Duration(milliseconds: 1500);

  // ── Canonical curve tokens ───────────────────────────────────────────────
  /// Natural exit — most sliding-out elements.
  static const Curve spring = Curves.easeOutCubic;

  /// Snappy standard — most sliding-in elements.
  static const Curve snap = Curves.easeInOutCubic;

  /// Playful overshoot — badges, likes, confirmations.
  static const Curve reveal = Curves.easeOutBack;

  /// Sharp — destructive actions, quick dismissals.
  static const Curve sharp = Curves.easeInCubic;

  // ── List stagger helper ──────────────────────────────────────────────────
  /// Returns the stagger delay for list item at [index].
  /// Caps at 400 ms to avoid feeling slow on large lists.
  static Duration stagger(int index, {int stepMs = 40}) =>
      Duration(milliseconds: (index * stepMs).clamp(0, 400));

  // ── Effect presets ───────────────────────────────────────────────────────

  /// Standard content entrance: fade + upward slide.
  static List<Effect> fadeSlideUp({
    Duration? delay,
    Duration? duration,
    Offset? begin,
  }) =>
      [
        FadeEffect(
          delay: delay ?? Duration.zero,
          duration: duration ?? AppTokens.durationMedium,
          curve: AppTokens.curveDecelerate,
        ),
        SlideEffect(
          delay: delay ?? Duration.zero,
          duration: duration ?? AppTokens.durationMedium,
          curve: AppTokens.curveDecelerate,
          begin: begin ?? const Offset(0, 0.04),
          end: Offset.zero,
        ),
      ];

  /// Staggered list item entrance delay: 40ms per index, capped at 400ms.
  static Duration staggerDelay(int index) =>
      Duration(milliseconds: (index * 40).clamp(0, 400));

  /// Scale-up entrance for hero elements (badges, icons, avatars).
  static List<Effect> scaleIn({
    Duration? delay,
    Duration? duration,
  }) =>
      [
        FadeEffect(
          delay: delay ?? Duration.zero,
          duration: duration ?? AppTokens.durationMedium,
          curve: AppTokens.curveDecelerate,
        ),
        ScaleEffect(
          delay: delay ?? Duration.zero,
          duration: duration ?? AppTokens.durationMedium,
          curve: AppTokens.curveSpring,
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
        ),
      ];
}

/// Convenience extensions for common motion patterns.
extension MotionWidgetExtension on Widget {
  /// Fade + slide up with optional stagger delay.
  Widget fadeSlideIn({Duration? delay, Duration? duration}) {
    return animate().fadeIn(
      delay: delay ?? Duration.zero,
      duration: duration ?? AppTokens.durationMedium,
      curve: AppTokens.curveDecelerate,
    ).slideY(
      begin: 0.03,
      end: 0,
      delay: delay ?? Duration.zero,
      duration: duration ?? AppTokens.durationMedium,
      curve: AppTokens.curveDecelerate,
    );
  }

  /// Staggered item in a list (index-based delay).
  Widget staggeredItem(int index) {
    final delay = AppMotion.staggerDelay(index);
    return animate().fadeIn(
      delay: delay,
      duration: AppTokens.durationMedium,
      curve: AppTokens.curveDecelerate,
    ).slideY(
      begin: 0.04,
      end: 0,
      delay: delay,
      duration: AppTokens.durationMedium,
      curve: AppTokens.curveDecelerate,
    );
  }
}
