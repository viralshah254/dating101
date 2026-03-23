import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';

/// A model for a moment fetched from the API.
class MomentData {
  const MomentData({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.caption,
    required this.expiresAt,
    required this.createdAt,
    this.authorName,
  });

  final String id;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? authorName;

  factory MomentData.fromJson(Map<String, dynamic> j) => MomentData(
        id: j['id'] as String,
        userId: j['userId'] as String,
        imageUrl: j['imageUrl'] as String,
        caption: j['caption'] as String?,
        expiresAt: DateTime.parse(j['expiresAt'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        authorName: j['authorName'] as String?,
      );
}

/// Full-screen moment viewer with reply bar.
/// Shows the moment photo, caption, time-to-expiry, and a reply input.
class MomentViewer extends StatefulWidget {
  const MomentViewer({
    super.key,
    required this.moment,
    required this.onReply,
    this.onClose,
  });

  final MomentData moment;
  final Future<void> Function(String text) onReply;
  final VoidCallback? onClose;

  @override
  State<MomentViewer> createState() => _MomentViewerState();
}

class _MomentViewerState extends State<MomentViewer> {
  final _replyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String _timeRemaining() {
    final remaining = widget.moment.expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inHours > 0) return '${remaining.inHours}h left';
    return '${remaining.inMinutes}m left';
  }

  Future<void> _send() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.onReply(text);
      _replyController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply sent!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onClose?.call();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen photo
          Image.network(
            widget.moment.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.image_not_supported_rounded,
                  color: cs.onSurface.withValues(alpha: 0.3), size: 48),
            ),
          ),
          // Gradient overlay
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Colors.transparent,
                  Color(0xCC000000),
                ],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (widget.moment.authorName != null) ...[
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.moment.authorName!,
                              style: AppTypography.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _timeRemaining(),
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: AppMotion.medium),
          // Caption + reply bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    MediaQuery.viewInsetsOf(context).bottom + 16,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.moment.caption != null &&
                            widget.moment.caption!.isNotEmpty) ...[
                          Text(
                            widget.moment.caption!,
                            style: AppTypography.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: TextField(
                                  controller: _replyController,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Reply to ${widget.moment.authorName ?? 'this moment'}…',
                                    hintStyle: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white54,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.12),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _sending ? null : _send,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [cs.primary, cs.secondary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: _sending
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded,
                                        color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: AppMotion.medium, delay: 100.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

/// Story-ring widget shown around profile photos when user has an active Moment.
class MomentStoryRing extends StatefulWidget {
  const MomentStoryRing({
    super.key,
    required this.child,
    required this.hasActiveMoment,
    this.onTap,
    this.ringWidth = 3,
  });

  final Widget child;
  final bool hasActiveMoment;
  final VoidCallback? onTap;
  final double ringWidth;

  @override
  State<MomentStoryRing> createState() => _MomentStoryRingState();
}

class _MomentStoryRingState extends State<MomentStoryRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.hasActiveMoment) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(MomentStoryRing old) {
    super.didUpdateWidget(old);
    if (widget.hasActiveMoment && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.hasActiveMoment && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasActiveMoment) return widget.child;

    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (ctx, child) {
          return Transform.scale(
            scale: _pulse.value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [cs.primary, cs.secondary, const Color(0xFFFFB300)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.all(widget.ringWidth + 1.5),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(ctx).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: child,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
