import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a discovery card: swipe left = pass, right = like, up = super like.
/// Uses animated fly-away, spring-back, velocity-aware commit, and haptics.
class DiscoverySwipeableCard extends StatefulWidget {
  const DiscoverySwipeableCard({
    super.key,
    required this.child,
    this.onPass,
    this.onLike,
    this.onSuperLike,
  });

  final Widget child;
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final VoidCallback? onSuperLike;

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

  late AnimationController _returnController;
  late AnimationController _exitController;
  late Animation<double> _returnAnimation;
  late Animation<double> _exitAnimation;

  bool _isAnimatingOut = false;
  bool _hasHapticLike = false;
  bool _hasHapticPass = false;
  bool _hasHapticSuper = false;

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
  }

  @override
  void dispose() {
    _returnController.dispose();
    _exitController.dispose();
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
  }

  void _maybeHapticOverlay() {
    if (_dragDx > 50 && !_hasHapticLike) {
      _hasHapticLike = true;
      HapticFeedback.lightImpact();
    } else if (_dragDx < -50 && !_hasHapticPass) {
      _hasHapticPass = true;
      HapticFeedback.lightImpact();
    } else if (_dragDy < -50 && !_hasHapticSuper) {
      _hasHapticSuper = true;
      HapticFeedback.lightImpact();
    }
    if (_dragDx.abs() < 30) {
      _hasHapticLike = false;
      _hasHapticPass = false;
    }
    if (_dragDy.abs() < 30) _hasHapticSuper = false;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimatingOut) return;
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;

    final commitLike = _dragDx > _threshold || vx > _velocityThreshold;
    final commitPass = _dragDx < -_threshold || vx < -_velocityThreshold;
    final commitSuper =
        _dragDy < -_threshold || vy < -_velocityThreshold;

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
      });
    });
  }

  void _commitAction(_SwipeAction action) {
    if (_isAnimatingOut) return;
    _isAnimatingOut = true;
    HapticFeedback.mediumImpact();

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
              animation: Listenable.merge([_returnController, _exitController]),
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(_dragDx * 0.5, _dragDy * 0.5)
                    ..rotateZ(rotationRad)
                    ..scale(scale),
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: child,
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
              label: 'LIKE',
              color: const Color(0xFF34D399),
              progress: (_dragDx / _maxDrag).clamp(0.0, 1.0),
            ),
          ),
        if (showPass && !_isAnimatingOut)
          Positioned(
            right: 24,
            top: size.height * 0.26,
            child: _SwipeOverlay(
              icon: Icons.close_rounded,
              label: 'PASS',
              color: const Color(0xFFF87171),
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
                label: 'SUPER LIKE',
                color: const Color(0xFF60A5FA),
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
    final opacity = (0.4 + 0.6 * progress).clamp(0.0, 1.0);
    final scale = 0.85 + 0.15 * progress;
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 4),
              borderRadius: BorderRadius.circular(14),
              color: color.withValues(alpha: 0.25),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 34, color: color),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
