import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a discovery card: swipe left = pass, right = like, up = super like.
/// Uses animated fly-away, spring-back, velocity-aware commit, and haptics.
///
/// **Deep Look Swipe**: when dragging right past 90 px and holding for 800 ms,
/// [deepLookContent] slides up from the bottom half of the card, revealing
/// more profile depth (prompts, compat, voice intro) without committing a like.
class DiscoverySwipeableCard extends StatefulWidget {
  const DiscoverySwipeableCard({
    super.key,
    required this.child,
    required this.likeLabel,
    required this.passLabel,
    required this.superLikeLabel,
    this.onPass,
    this.onLike,
    this.onSuperLike,
    this.deepLookContent,
  });

  final Widget child;
  final String likeLabel;
  final String passLabel;
  final String superLikeLabel;
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final VoidCallback? onSuperLike;
  /// Widget shown when user hovers in the curiosity zone (>90 px right, >800 ms).
  final Widget? deepLookContent;

  @override
  State<DiscoverySwipeableCard> createState() => _DiscoverySwipeableCardState();
}

class _DiscoverySwipeableCardState extends State<DiscoverySwipeableCard>
    with TickerProviderStateMixin {
  double _dragDx = 0;
  double _dragDy = 0;

  static const double _threshold = 70;
  static const double _velocityThreshold = 400;
  static const double _maxDrag = 140;
  static const double _rotationDegPerPixel = 0.35;
  static const double _translationFactor = 0.65;
  static const double _minScale = 0.96;

  /// The pixel threshold that enters the "curiosity zone" triggering Deep Look.
  static const double _deepLookThreshold = 90;
  static const Duration _deepLookDelay = Duration(milliseconds: 800);

  late AnimationController _returnController;
  late AnimationController _exitController;
  late AnimationController _deepLookController;
  late Animation<double> _returnAnimation;
  late Animation<double> _exitAnimation;
  late Animation<double> _deepLookAnimation;

  bool _isAnimatingOut = false;
  bool _hasHapticLike = false;
  bool _hasHapticPass = false;
  bool _hasHapticSuper = false;
  bool _hasHapticCuriosity = false; // medium tick at 90 px
  bool _showDeepLook = false;
  Timer? _deepLookTimer;

  @override
  void initState() {
    super.initState();
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _returnAnimation = CurvedAnimation(
      parent: _returnController,
      curve: Curves.easeOutBack,
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _exitAnimation = CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeIn,
    );

    _deepLookController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _deepLookAnimation = CurvedAnimation(
      parent: _deepLookController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _deepLookTimer?.cancel();
    _returnController.dispose();
    _exitController.dispose();
    _deepLookController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails _) {
    if (_isAnimatingOut) return;
    _returnController.stop();
    _returnController.reset();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimatingOut) return;
    final dx = (_dragDx + details.delta.dx * _translationFactor)
        .clamp(-_maxDrag, _maxDrag);
    final dy = (_dragDy + details.delta.dy * _translationFactor)
        .clamp(-_maxDrag, _maxDrag);
    setState(() {
      _dragDx = dx;
      _dragDy = dy;
    });
    _maybeHapticOverlay();
    _updateDeepLookTimer();
  }

  void _maybeHapticOverlay() {
    // Level 1: light tick at 35 px
    if (_dragDx > 35 && !_hasHapticLike) {
      _hasHapticLike = true;
      HapticFeedback.lightImpact();
    } else if (_dragDx < -35 && !_hasHapticPass) {
      _hasHapticPass = true;
      HapticFeedback.lightImpact();
    } else if (_dragDy < -35 && !_hasHapticSuper) {
      _hasHapticSuper = true;
      HapticFeedback.lightImpact();
    }

    // Level 2: medium tick when entering curiosity zone
    if (_dragDx > _deepLookThreshold && !_hasHapticCuriosity) {
      _hasHapticCuriosity = true;
      HapticFeedback.mediumImpact();
    }

    if (_dragDx.abs() < 30) {
      _hasHapticLike = false;
      _hasHapticPass = false;
      _hasHapticCuriosity = false;
    }
    if (_dragDy.abs() < 30) _hasHapticSuper = false;
  }

  void _updateDeepLookTimer() {
    if (_dragDx > _deepLookThreshold && !_showDeepLook) {
      _deepLookTimer ??= Timer(_deepLookDelay, () {
        if (!mounted) return;
        if (_dragDx > _deepLookThreshold && !_isAnimatingOut) {
          setState(() => _showDeepLook = true);
          _deepLookController.forward(from: 0);
        }
      });
    } else if (_dragDx <= _deepLookThreshold) {
      _cancelDeepLook();
    }
  }

  void _cancelDeepLook() {
    _deepLookTimer?.cancel();
    _deepLookTimer = null;
    if (_showDeepLook) {
      setState(() => _showDeepLook = false);
      _deepLookController.reverse();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimatingOut) return;
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;

    final commitLike = _dragDx > _threshold || vx > _velocityThreshold;
    final commitPass = _dragDx < -_threshold || vx < -_velocityThreshold;
    final commitSuper =
        _dragDy < -_threshold || vy < -_velocityThreshold;

    _cancelDeepLook();

    if (commitLike && !commitPass) {
      _commitAction(_SwipeAction.like);
      return;
    }
    if (commitPass && !commitLike) {
      _commitAction(_SwipeAction.pass);
      return;
    }
    if (commitSuper) {
      _commitAction(_SwipeAction.superLike);
      return;
    }

    _springBack();
  }

  void _springBack() {
    _cancelDeepLook();
    final startDx = _dragDx;
    final startDy = _dragDy;
    void listener() {
      if (!mounted) return;
      final t = _returnAnimation.value;
      setState(() {
        _dragDx = startDx * (1 - t);
        _dragDy = startDy * (1 - t);
      });
    }
    _returnController.addListener(listener);
    _returnController.forward(from: 0).then((_) {
      _returnController.removeListener(listener);
      if (!mounted) return;
      setState(() {
        _dragDx = 0;
        _dragDy = 0;
        _hasHapticLike = false;
        _hasHapticPass = false;
        _hasHapticSuper = false;
        _hasHapticCuriosity = false;
      });
    });
  }

  void _commitAction(_SwipeAction action) {
    if (_isAnimatingOut) return;
    _isAnimatingOut = true;
    // Level 3: strong impact on commit
    HapticFeedback.heavyImpact();

    final size = MediaQuery.sizeOf(context);
    final exitDx = action == _SwipeAction.like
        ? size.width * 1.3
        : action == _SwipeAction.pass
            ? -size.width * 1.3
            : 0.0;
    final exitDy = action == _SwipeAction.superLike
        ? -size.height * 1.2
        : 0.0;

    final startDx = _dragDx;
    final startDy = _dragDy;

    void exitListener() {
      if (!mounted) return;
      final t = _exitAnimation.value;
      setState(() {
        _dragDx = startDx + (exitDx - startDx) * t;
        _dragDy = startDy + (exitDy - startDy) * t;
      });
    }
    _exitController.addListener(exitListener);
    _exitController.forward(from: 0).then((_) {
      _exitController.removeListener(exitListener);
      if (!mounted) return;
      setState(() {
        _dragDx = 0;
        _dragDy = 0;
        _isAnimatingOut = false;
        _hasHapticLike = false;
        _hasHapticPass = false;
        _hasHapticSuper = false;
        _hasHapticCuriosity = false;
        _showDeepLook = false;
      });
      switch (action) {
        case _SwipeAction.like:
          widget.onLike?.call();
          break;
        case _SwipeAction.pass:
          widget.onPass?.call();
          break;
        case _SwipeAction.superLike:
          widget.onSuperLike?.call();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final showLike = _dragDx > 35;
    final showPass = _dragDx < -35;
    final showSuperLike = _dragDy < -35;

    final dragAmount = math.sqrt(_dragDx * _dragDx + _dragDy * _dragDy);
    final scale = 1.0 - (1.0 - _minScale) * (dragAmount / _maxDrag).clamp(0.0, 1.0);
    // Subtle card lift when in deep look zone
    final deepLookScale = _showDeepLook ? 1.02 : 1.0;
    final rotationRad = _dragDx * _rotationDegPerPixel * math.pi / 180;
    final exitProgress = _exitController.isAnimating ? _exitAnimation.value : 0.0;
    final opacity = _isAnimatingOut ? (1.0 - exitProgress).clamp(0.0, 1.0) : 1.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _returnController,
                _exitController,
                _deepLookController,
              ]),
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translateByDouble(_dragDx * 0.5, _dragDy * 0.5, 0.0, 1.0)
                    ..rotateZ(rotationRad)
                    ..scaleByDouble(scale * deepLookScale, scale * deepLookScale, 1.0, 1.0),
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(child: child!),
                        // Deep Look overlay — slides up from the bottom half
                        if (widget.deepLookContent != null)
                          AnimatedBuilder(
                            animation: _deepLookAnimation,
                            builder: (ctx, _) {
                              final t = _deepLookAnimation.value;
                              if (t == 0) return const SizedBox.shrink();
                              return Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: FractionalTranslation(
                                  translation: Offset(0, 1.0 - t),
                                  child: Opacity(
                                    opacity: t,
                                    child: widget.deepLookContent,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
              child: widget.child,
            ),
          ),
        ),
        if (showLike && !_isAnimatingOut)
          Positioned(
            left: 24,
            top: size.height * 0.26,
            child: _SwipeOverlay(
              icon: Icons.favorite_rounded,
              label: widget.likeLabel.toUpperCase(),
              color: Theme.of(context).colorScheme.primary,
              progress: (_dragDx / _maxDrag).clamp(0.0, 1.0),
            ),
          ),
        if (showPass && !_isAnimatingOut)
          Positioned(
            right: 24,
            top: size.height * 0.26,
            child: _SwipeOverlay(
              icon: Icons.close_rounded,
              label: widget.passLabel.toUpperCase(),
              color: Theme.of(context).colorScheme.error,
              progress: (-_dragDx / _maxDrag).clamp(0.0, 1.0),
            ),
          ),
        if (showSuperLike && !_isAnimatingOut)
          Positioned(
            left: 0,
            right: 0,
            top: size.height * 0.16,
            child: Center(
              child: _SwipeOverlay(
                icon: Icons.star_rounded,
                label: widget.superLikeLabel.toUpperCase(),
                color: Theme.of(context).colorScheme.secondary,
                progress: (-_dragDy / _maxDrag).clamp(0.0, 1.0),
              ),
            ),
          ),
      ],
    );
  }
}

enum _SwipeAction { like, pass, superLike }

class _SwipeOverlay extends StatelessWidget {
  const _SwipeOverlay({
    required this.icon,
    required this.label,
    required this.color,
    required this.progress,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final opacity = (0.5 + 0.5 * progress).clamp(0.0, 1.0);
    final scale = 0.9 + 0.1 * progress;
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                  color: color.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 28, color: color),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
