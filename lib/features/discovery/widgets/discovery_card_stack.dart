import 'package:flutter/material.dart';

import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';
import 'discovery_swipe_card.dart';
import 'discovery_swipeable_card.dart';

/// Stack of discovery cards with the next profile visible behind the current one.
/// Creates a Tinder-style peek effect as you swipe.
class DiscoveryCardStack extends StatefulWidget {
  const DiscoveryCardStack({
    super.key,
    required this.profiles,
    required this.currentIndex,
    required this.onPass,
    required this.onLike,
    required this.onSuperLike,
    required this.onTapProfile,
    required this.onBlock,
    required this.onReport,
    required this.showManagedByChip,
  });

  final List<ProfileSummary> profiles;
  final int currentIndex;
  final void Function(ProfileSummary) onPass;
  final void Function(ProfileSummary) onLike;
  final void Function(ProfileSummary) onSuperLike;
  final void Function(ProfileSummary) onTapProfile;
  final void Function(ProfileSummary) onBlock;
  final void Function(ProfileSummary) onReport;
  final bool showManagedByChip;

  @override
  State<DiscoveryCardStack> createState() => _DiscoveryCardStackState();
}

class _DiscoveryCardStackState extends State<DiscoveryCardStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DiscoveryCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scaleController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final profiles = widget.profiles;
    final index = widget.currentIndex;
    if (profiles.isEmpty || index >= profiles.length) {
      return const SizedBox.expand();
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Back cards — next 2 profiles, scaled down and offset
        if (index + 2 < profiles.length)
          _StackedCard(
            profile: profiles[index + 2],
            scale: 0.88,
            offsetY: 24,
            onTapProfile: widget.onTapProfile,
            onBlock: widget.onBlock,
            onReport: widget.onReport,
            showManagedByChip: widget.showManagedByChip,
          ),
        if (index + 1 < profiles.length)
          _StackedCard(
            profile: profiles[index + 1],
            scale: 0.92,
            offsetY: 12,
            onTapProfile: widget.onTapProfile,
            onBlock: widget.onBlock,
            onReport: widget.onReport,
            showManagedByChip: widget.showManagedByChip,
          ),
        // Top card — current, swipeable (animates up when it becomes top)
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            final t = index > 0 ? _scaleAnimation.value : 1.0;
            final scale = 0.92 + 0.08 * t;
            return Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            );
          },
          child: DiscoverySwipeableCard(
            likeLabel: l.discoverLike,
            passLabel: l.discoverPass,
            superLikeLabel: l.discoverSuperLike,
            onPass: () => widget.onPass(profiles[index]),
            onLike: () => widget.onLike(profiles[index]),
            onSuperLike: () => widget.onSuperLike(profiles[index]),
            child: DiscoverySwipeCard(
              profile: profiles[index],
              onTap: () => widget.onTapProfile(profiles[index]),
              onPass: () => widget.onPass(profiles[index]),
              onLike: () => widget.onLike(profiles[index]),
              onSuperLike: () => widget.onSuperLike(profiles[index]),
              onBlock: () => widget.onBlock(profiles[index]),
              onReport: () => widget.onReport(profiles[index]),
              showManagedByChip: widget.showManagedByChip,
            ),
          ),
        ),
      ],
    );
  }
}

class _StackedCard extends StatelessWidget {
  const _StackedCard({
    required this.profile,
    required this.scale,
    required this.offsetY,
    required this.onTapProfile,
    required this.onBlock,
    required this.onReport,
    required this.showManagedByChip,
  });

  final ProfileSummary profile;
  final double scale;
  final double offsetY;
  final void Function(ProfileSummary) onTapProfile;
  final void Function(ProfileSummary) onBlock;
  final void Function(ProfileSummary) onReport;
  final bool showManagedByChip;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(0, offsetY),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: DiscoverySwipeCard(
                profile: profile,
                onTap: () => onTapProfile(profile),
                onPass: () {},
                onLike: () {},
                onSuperLike: () {},
                onBlock: () => onBlock(profile),
                onReport: () => onReport(profile),
                showManagedByChip: showManagedByChip,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
